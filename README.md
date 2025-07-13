# AES FPGA Encryption & Decryption on PYNQ Z2

> A complete end-to-end AES-128 encryption/decryption SoC on the Xilinx Zynq-7000, from Verilog RTL through behavioral simulation, C-driver integration, and on-board demonstration using UART, AXI-GPIO (buttons/switches/LEDs), and custom AXI-Lite slave interfaces.

---

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Repository Structure](#repository-structure)  
3. [Verilog RTL Modules](#verilog-rtl-modules)  
   - [AES Encryptor (`aes_encryptor_top.v`)](#aes-encryptor)  
   - [AES Decryptor (`aes_decryptor_top.v`)](#aes-decryptor)  
   - [Key Expansion (`aes_key_expansion.v`)](#key-expansion)  
   - [Core Primitives (`aes_inv_shiftrows.v`, `aes_inv_sbox.v`, etc.)](#core-primitives)  
   - [AXI-Lite Slave Wrapper (`AES_*_S00_AXI.v`)](#axi-lite-slave-wrapper)  
4. [Behavioral Simulation & Testbenches](#behavioral-simulation--testbenches)  
   - [Encryption TB (`tb_encrypt.v`)](#encryption-tb)  
   - [Decryption TB (`tb_decrypt.v`)](#decryption-tb)  
   - [Waveform Debugging & Log-Capture](#waveform-debugging--log-capture)  
5. [Software / C Driver](#software--c-driver)  
   - [AXI-GPIO Button & Switch Interface](#axi-gpio-button--switch-interface)  
   - [UART Console I/O](#uart-console-io)  
   - [Encryption & Decryption Flow](#encryption--decryption-flow)  
6. [Block Design & Vivado Integration](#block-design--vivado-integration)  
   - [Block Diagram Overview](#block-diagram-overview)  
   - [AXI Interconnect & Custom Slave](#axi-interconnect--custom-slave)  
7. [Hardware Demonstration on PYNQ Z2](#hardware-demonstration-on-pynq-z2)  
   - [Switch-Controlled Mode Selection](#switch-controlled-mode-selection)  
   - [Button-Driven Operations](#button-driven-operations)  
   - [LED Status Indicators](#led-status-indicators)  
8. [Future Enhancements](#future-enhancements)  

---

## 1. Project Overview

This project implements a full AES-128 encryption and decryption subsystem on the Xilinx Zynq-7000 SoC. It covers:

- **RTL design** of AES encryption & decryption cores  
- **AXI-Lite** wrappers for register-based control & data transfer  
- **Behavioral testbenches** with cycle-accurate log printing and waveform dump  
- **C driver** to talk to the IP over AXI-Lite and AXI-GPIO, using UART console for input/output  
- **Vivado block design** integration into a PYNQ Z2 hardware platform  
- **On-board demo**: buttons & switches select mode, LEDs indicate status, UART console types plaintext & key.

---

## 2. Repository Structure

```text
├── rtl/
│ ├── aes_encryptor_top.v
│ ├── aes_decryptor_top.v
│ ├── aes_key_expansion.v
│ ├── aes_inv_shiftrows.v
│ ├── aes_inv_sbox.v
│ ├── aes_inv_mixcolumns.v
│ └── AES_*_S00_AXI.v # AXI-Lite slave wrappers
│
├── tb/
│ ├── tb_encrypt.v
│ └── tb_decrypt.v
│
├── sw/
│ └── AES_FPGA.c # PYNQ/Zynq C application
│
├── vivado/
│ ├── top_level_wrapper.xpr
│ ├── design_1_wrapper.bit
│ └── design_1_wrapper.hwh
│
├── images/ # block diagrams & waveform screenshots
├── README.md # ← you are here
```


---

## 3. Verilog RTL Modules

### AES Encryptor

- **File**: `rtl/aes_encryptor_top.v`  
- Implements the classic AES-128 round structure:  
  1. SubBytes → ShiftRows → MixColumns → AddRoundKey (10 rounds, final skip MixColumns)  
  2. On `start` pulse, latches key & plaintext, runs FSM, asserts `valid` & outputs ciphertext.  

### AES Decryptor

- **File**: `rtl/aes_decryptor_top.v`  
- Mirrors encryption in reverse:  
  1. InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns (10 rounds)  
  2. Final round omits InvMixColumns.  

### Key Expansion

- **File**: `rtl/aes_key_expansion.v`  
- On `start` pulses, expands the 128-bit master key into 11 round keys (`rk0`…`rk10`).  
- Outputs each `round_key` with a one-cycle `valid` pulse.  

### Core Primitives

- **InvShiftRows**: `aes_inv_shiftrows.v`  
- **InvSubBytes**: `aes_inv_sbox.v` (lookup S-box function)  
- **InvMixColumns**: `aes_inv_mixcolumns.v`  
- **Forward Versions** (encryption) in `aes_shiftrows.v`, `aes_sbox.v`, `aes_mixcolumns.v`.

### AXI-Lite Slave Wrapper

- **Files**: `rtl/AES_Encryptor_S00_AXI.v`, `rtl/AES_Decryptor_S00_AXI.v`  
- Standard AXI4-Lite interface mapping:  
  - Registers 0–3: key words  
  - Registers 4–7: data words (plaintext or ciphertext)  
  - Reg 8: `start` bit  
  - Reg 9: `valid` bit  
  - Reg 10–13: output data words  

---

## 4. Behavioral Simulation & Testbenches

### Encryption TB

- **File**: `tb/tb_encrypt.v`  
- Drives AXI-Lite writes of key & plaintext, pulses start, polls `valid`, then reads back ciphertext.  
- Captures `$display` logs for each write/read and prints mismatches.

### Decryption TB

- **File**: `tb/tb_decrypt.v`  
- Similar to encryption TB but driving ciphertext→plaintext.  
- Enhanced with debug prints in the decrypt core showing round-by-round state evolution.

### Waveform Debugging & Log-Capture

1. Launch `xsim tb_encrypt` / `xsim tb_decrypt` with `-gui` or `-vcd`.  
2. Inspect waveforms for AXI handshake, register contents, core FSM states.  
3. Use `$display` logs at key events (write, read, round transitions) to pinpoint mismatches.

---

## 5. Software / C Driver

**File**: `sw/AES_FPGA.c`

### AXI-GPIO Button & Switch Interface

- Uses two AXI-GPIO IPs:  
  - **Buttons**  → read `BTN_CLEAR`, `BTN_RUN`  
  - **Switches** → mode select: text vs. key entry  

### UART Console I/O

- Prompts user to enter 16-byte plaintext or 32-hex-digit key over UART.  
- `readline()` echoes characters, assembles fixed-length buffers.  

### Encryption & Decryption Flow

1. **Text mode**: user types plaintext, LED1 lights.  
2. **Key mode**: user types key hex, LED2 lights.  
3. Press BTN3 to **run**:  
   - AXI-Lite write key regs → start → poll valid → read ciphertext  
   - AXI-Lite write ciphertext regs → start → poll valid → read roundtrip plaintext  
4. Results printed to UART, LED0 lights on completion.

---

## 6. Block Design & Vivado Integration

### Block Diagram Overview

![Block Diagram](images/Block_Design.png)

- **Processing System** (PS-7) provides AXI master clock/reset.  
- **SmartConnect** routes 4 custom AXI-Lite slaves:  
  1. AES_Encryptor_0  
  2. AES_Decryptor_0  
  3. AXI-GPIO buttons/switches  
  4. AXI-GPIO LEDs  

### AXI Interconnect & Custom Slave

- Each AES IP is a memory-mapped AXI4-Lite slave at a unique base address.  
- PS C driver uses these base addresses (`xparameters.h`) to `Xil_Out32()` / `Xil_In32()`.

---

## 7. Hardware Demonstration on PYNQ Z2

1. **Mode Selection** via Slide Switch 0:  
   - SW0 = 1 → **Text Mode** (enter plaintext)  
   - SW0 = 0 → **Key Mode** (enter key)  

2. **Control Buttons**:  
   - BTN1 = **Clear** (resets text/key entry)  
   - BTN3 = **Run** (trigger AES operation)  

3. **LED Indicators**:  
   - LED3 always on after reset  
   - LED1 lights when plaintext entered  
   - LED2 lights when key entered  
   - LED0 lights on successful run
   - 
---

## 8. Future Enhancements
- DMA-accelerated key transfer rather than AXI-Lite
- Hardware-accelerated CBC / CTR modes for streaming data
- AXI-4 Stream interface for bulk data encryption
- Integration with Python API on PYNQ for interactive demos
