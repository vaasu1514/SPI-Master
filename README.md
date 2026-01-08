# SPI Master Controller (Verilog)

## Overview
This project implements an SPI Master Controller in Verilog HDL, supporting all four standard SPI modes (Mode 0–3).  
The design focuses on correct clock generation, edge-accurate data transfer, and protocol-compliant MOSI/MISO operation.  
A loopback-based testbench is used to verify transmission and reception behavior.

---

## Key Features
- Supports all SPI modes (Mode 0–3) using configurable **CPOL** and **CPHA**
- Parameterized SPI clock generation using a programmable clock divider
- Bit-wise data transfer over **MOSI** and **MISO**
- MSB-first, 8-bit data transactions
- Designed without chip-select (CS) for core SPI datapath clarity

---

## Design Details
- SPI clock (SCLK) is generated from the system clock using a parameterized divider
- Leading and trailing edges are explicitly detected to support CPHA-dependent timing
- Data is shifted out on MOSI and sampled from MISO on the appropriate clock edges
- Transmission is controlled using internal counters and edge tracking logic

---

## Verification
The design is verified using a custom Verilog testbench with loopback configuration.

Verification includes:
- Multi-byte SPI transfers
- Correct operation across different SPI modes
- Validation of MOSI/MISO timing with respect to clock edges
- Waveform inspection using **GTKWave**

