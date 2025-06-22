# 🔄 Asynchronous FIFO Design & Verification in SystemVerilog

## Clock-Domain Crossing FIFO with Gray Code Synchronization and Functional Verification

This repository presents a **SystemVerilog-based RTL design and verification** of an **Asynchronous FIFO (First-In-First-Out)** memory module. It focuses on enabling **reliable data transfer between independent clock domains** using Gray code synchronization. The design and verification were developed using standard HDL simulation practices and verified with a self-contained testbench.

---

## 🔍 Project Overview

This digital design project implements an Asynchronous FIFO featuring:

- **Dual-Clock Domains**: Independent write and read clocks for real-time asynchronous data handling.
- **Pointer Synchronization**: Gray-coded pointer conversion for metastability-resilient clock domain crossing.
- **FIFO Control Logic**: Efficient generation of Full, Empty, and Valid flags.
- **Modular Design**: Clean separation of write/read logic, memory buffer, and synchronization blocks.

---

## ✨ Key Design Features

- ✅ **Asynchronous Write and Read Clocks**  
- ✅ **Gray Code Based Pointer Synchronization**  
- ✅ **Full and Empty Condition Detection**  
- ✅ **Circular Memory Buffer Implementation**  
- ✅ **Assertion-Based Error Detection**  

---

## 📁 Repository Structure
```
Async-FIFO-SystemVerilog/
├── Async_fifo_design.sv      # RTL Design: Asynchronous FIFO module
├── Async_fifo_tb.sv          # Testbench: Functional simulation environment
└── README.md                 # Project documentation
```


---

## 🧪 Verification Overview

The testbench includes:

- 📌 Reset Condition Check  
- 📌 Write and Read Operations under different clock frequencies  
- 📌 Boundary Condition Tests (Full & Empty flags)  
- 📌 Stress Testing Across Clock Domains  

>🧠 Note: This testbench does not use the UVM library, but follows a modular verification structure with components like driver, monitor, and scoreboard written in pure SystemVerilog. It demonstrates fundamental verification concepts such as stimulus generation, observation, and result checking using mailbox-based communication.
---

## 🛠️ Development Environment

- **Language**: SystemVerilog (IEEE 1800 Standard)
- **Simulator**: Compatible with all standard HDL tools (e.g., ModelSim, QuestaSim, Vivado Simulator, etc.)
- **Hardware Used**: *Not implemented on physical FPGA* — only simulation and RTL-level verification

---
