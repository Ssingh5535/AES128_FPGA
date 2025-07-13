#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include <ctype.h>
#include <unistd.h>  // for usleep()

//-----------------------------------------------------------------------------
// AES register bases (from xparameters.h)
#define AES_ENC_BASE      XPAR_AES_ENCRYPT_0_BASEADDR
#define AES_DEC_BASE      XPAR_AES_DECRYPT_0_BASEADDR

//-----------------------------------------------------------------------------
// GPIO bases (from xparameters.h)
#define GPIO_LED_BASE     XPAR_AXI_GPIO_0_BASEADDR   // leds[3:0] + rgb_led[1:0]
#define GPIO_BTN_BASE     XPAR_AXI_GPIO_1_BASEADDR   // btns[3:0]
#define GPIO_SW_BASE      XPAR_AXI_GPIO_2_BASEADDR   // switches[1:0]

//-----------------------------------------------------------------------------
// AXI-GPIO register offsets
#define GPIO_DATA_CH1     0x00  // Data register, channel 1
#define GPIO_TRI_CH1      0x04  // Tri-state (1=input, 0=output), channel 1
#define GPIO_DATA_CH2     0x08  // Data register, channel 2
#define GPIO_TRI_CH2      0x0C  // Tri-state, channel 2

//-----------------------------------------------------------------------------
// AES register offsets
#define REG_KEY0     0x00
#define REG_KEY1     0x08
#define REG_KEY2     0x10
#define REG_KEY3     0x18
#define REG_DATA0    0x20
#define REG_DATA1    0x28
#define REG_DATA2    0x30
#define REG_DATA3    0x38
#define REG_START    0x40
#define REG_VALID    0x44
#define REG_OUT0     0x48
#define REG_OUT1     0x50
#define REG_OUT2     0x58
#define REG_OUT3     0x60

//-----------------------------------------------------------------------------
// App constants
#define MSG_LEN       16
#define KEY_HEX_LEN   32
#define BTN_CLEAR     (1 << 1)  // btns[1]
#define BTN_RUN       (1 << 3)  // btns[3]

//-----------------------------------------------------------------------------
// Helpers
static void set_dir(u32 base, u32 tri_offset, u32 mask, int is_input) {
    // is_input? mask bits=1 : mask bits=0
    u32 val = is_input ? mask : 0;
    Xil_Out32(base + tri_offset, val);
}

static inline u32 rd(u32 base, u32 offs)   { return Xil_In32(base + offs); }
static inline void wr(u32 base, u32 offs, u32 v) { Xil_Out32(base + offs, v); }

static void readline(char *buf, int maxlen) {
    int idx = 0;
    while (idx < maxlen) {
        int c = inbyte();
        if (c == '\r' || c == '\n') break;
        buf[idx++] = (char)c;
        outbyte(c);
    }
    while (idx < maxlen) buf[idx++] = ' ';
    buf[maxlen] = '\0';
    xil_printf("\r\n");
}

static int hex2nibble(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    c = toupper((unsigned char)c);
    if (c >= 'A' && c <= 'F') return 10 + (c - 'A');
    return -1;
}

//-----------------------------------------------------------------------------
int main() {
    char    plain[MSG_LEN+1];
    char    keystr[KEY_HEX_LEN+1];
    u64     key_hi=0, key_lo=0;
    int     have_text=0, have_key=0;

    xil_printf("\r\n=== AES via UART + Buttons ===\r\n");

    // --- configure GPIO directions ---
    // LEDs (channel1): 4-bit output
    set_dir(GPIO_LED_BASE, GPIO_TRI_CH1, 0xF, 0);
    // RGB (channel2): 2-bit output (we only use bit0=red, bit2=blue)
    set_dir(GPIO_LED_BASE, GPIO_TRI_CH2, 0x3, 0);

    // Switches (channel1): 2-bit input
    set_dir(GPIO_SW_BASE, GPIO_TRI_CH1, 0x3, 1);

    // Buttons (channel1): 4-bit input
    set_dir(GPIO_BTN_BASE, GPIO_TRI_CH1, 0xF, 1);

    // Boot LED3 on
    wr(GPIO_LED_BASE, GPIO_DATA_CH1, (1<<3));

    while (1) {
        // read mode switch0
        int sw0 = rd(GPIO_SW_BASE, GPIO_DATA_CH1) & 1;
        if (sw0) {
            xil_printf("\r\n** TEXT MODE **\r\n");
            // RED = bit0 on channel2
            wr(GPIO_LED_BASE, GPIO_DATA_CH2, 0x1);
        } else {
            xil_printf("\r\n** KEY MODE **\r\n");
            // BLUE = bit2 on channel2
            wr(GPIO_LED_BASE, GPIO_DATA_CH2, 0x4);
        }

        // clear on BTN1
        if ((rd(GPIO_BTN_BASE, GPIO_DATA_CH1) & BTN_CLEAR)==1) {
            have_text = have_key = 0;
            xil_printf(" ** CLEARED **\r\n");
            wr(GPIO_LED_BASE, GPIO_DATA_CH1, (1<<3));
            usleep(200000);
            // wait release
            while ((rd(GPIO_BTN_BASE,GPIO_DATA_CH1)&BTN_CLEAR)==0);
        }

        // get plaintext once
        if (sw0 && !have_text) {
            xil_printf("Enter %d-char plaintext: ", MSG_LEN);
            readline(plain, MSG_LEN);
            have_text = 1;
            // LED1 + LED3
            wr(GPIO_LED_BASE, GPIO_DATA_CH1, (1<<1)|(1<<3));
        }

        // get key once
        if (!sw0 && !have_key) {
            xil_printf("Enter %d hex digits key: ", KEY_HEX_LEN);
            readline(keystr, KEY_HEX_LEN);
            // parse
            key_hi = key_lo = 0;
            for (int i=0; i<16; i++) {
                int hi = hex2nibble(keystr[2*i]);
                int lo = hex2nibble(keystr[2*i+1]);
                if (hi<0||lo<0) { xil_printf("Bad hex\n"); break; }
                if (i<8)  key_hi = (key_hi<<8)|((hi<<4)|lo);
                else      key_lo = (key_lo<<8)|((hi<<4)|lo);
            }
            have_key = 1;
            xil_printf("Key = %016llx%016llx\n", key_hi, key_lo);
            // LED2 + LED3
            wr(GPIO_LED_BASE, GPIO_DATA_CH1, (1<<2)|(1<<3));
        }

        // run AES on BTN3
        if (have_text && have_key) {
            xil_printf("\r\nPress BTN3 to RUN AES... ");
            // wait press
            while ( rd(GPIO_BTN_BASE,GPIO_DATA_CH1)&BTN_RUN );
            // wait release
            while (!(rd(GPIO_BTN_BASE,GPIO_DATA_CH1)&BTN_RUN));
            xil_printf("GO!\r\n");

            // pack plain into two u64
            u64 pt_hi=0, pt_lo=0;
            for (int i=0; i<MSG_LEN; i++) {
                u8 b = (u8)plain[i];
                if (i<8)      pt_hi = (pt_hi<<8)|b;
                else          pt_lo = (pt_lo<<8)|b;
            }

            // encrypt
            Xil_Out64(AES_ENC_BASE+REG_KEY0,   key_hi);
            Xil_Out64(AES_ENC_BASE+REG_KEY1,   key_lo);
            Xil_Out64(AES_ENC_BASE+REG_DATA0,  pt_hi);
            Xil_Out64(AES_ENC_BASE+REG_DATA1,  pt_lo);
            Xil_Out32(AES_ENC_BASE+REG_START,  1);
            Xil_Out32(AES_ENC_BASE+REG_START,  0);
            while (!Xil_In32(AES_ENC_BASE+REG_VALID));
            u64 ct_hi = Xil_In64(AES_ENC_BASE+REG_OUT0);
            u64 ct_lo = Xil_In64(AES_ENC_BASE+REG_OUT1);
            xil_printf("CIPHERTEXT = %016llx%016llx\n", ct_hi, ct_lo);

            // decrypt
            Xil_Out64(AES_DEC_BASE+REG_KEY0,   key_hi);
            Xil_Out64(AES_DEC_BASE+REG_KEY1,   key_lo);
            Xil_Out64(AES_DEC_BASE+REG_DATA0,  ct_hi);
            Xil_Out64(AES_DEC_BASE+REG_DATA1,  ct_lo);
            Xil_Out32(AES_DEC_BASE+REG_START,  1);
            Xil_Out32(AES_DEC_BASE+REG_START,  0);
            while (!Xil_In32(AES_DEC_BASE+REG_VALID));
            u64 rt_hi = Xil_In64(AES_DEC_BASE+REG_OUT0);
            u64 rt_lo = Xil_In64(AES_DEC_BASE+REG_OUT1);

            // unpack
            for (int i=0; i<8; i++) {
                plain[7-i]  = (char)(rt_hi & 0xFF); rt_hi >>= 8;
                plain[15-i] = (char)(rt_lo & 0xFF); rt_lo >>= 8;
            }
            plain[MSG_LEN] = '\0';
            xil_printf("ROUNDTRIP => \"%s\"\n", plain);

            // LED0 + preserve 2/3
            wr(GPIO_LED_BASE,GPIO_DATA_CH1,(1<<0)|(1<<2)|(1<<3));
            have_text = have_key = 0;
        }
    }
    return 0;
}
