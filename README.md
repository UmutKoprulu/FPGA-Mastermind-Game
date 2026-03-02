# FPGA Mastermind Game – Verilog FSM Implementation

Sabancı University – CS303 Logic & Digital System Design  
Umut Köprülü  

---

## Project Overview

This project implements a two-player **Mastermind game** on FPGA using **Verilog HDL**.

The system is designed as a multi-state **Finite State Machine (FSM)** handling:

- Player role control  
- Input validation  
- Scoring logic  
- Life management  
- Display control  

The design was synthesized and deployed on a **Tang Nano 9K FPGA board**.

---

## Hardware Platform

- Tang Nano 9K FPGA  
- 7-Segment Display (SSD)  
- Push Buttons (Enter, Restart)  
- LED Outputs  
- On-board clock  

---

## Game Logic

1. Player A (Code Maker) enters a 4-character secret code.
2. Player B (Code Breaker) attempts to guess the code.
3. Exact and partial matches are evaluated.
4. The breaker has limited lives.
5. Scores are updated based on round outcome.
6. Roles swap after each round.
7. The game ends when a player reaches the winning score.

Invalid inputs are ignored and do not increment the input index.

---

## FSM Architecture

The entire system is controlled by a structured finite state machine.

### Main States

- `S_START`
- `S_WAIT_START_PRESS`
- `S_MAKER_IN`
- `S_BREAKER_IN`
- `S_EVAL`
- `S_SHOW_LIVES`
- `S_SHOW_SCORE`
- `S_SWAP_ROLES`
- `S_ROUND_WIN_MAKER`
- `S_ROUND_WIN_BREAKER`
- `S_GAME_END`

Reset is implemented as **asynchronous** and forces the system back to `S_START` from any state.

---

## Key Modules

### `top_module.v`
Top-level integration module connecting all submodules.

### `mastermind.v`
Core FSM logic and overall game control implementation.

### `clk_divider.v`
Clock frequency division for timing control.

### `debouncer.v`
Push-button stabilization to prevent metastability and bouncing.

### `ssd.v`
7-segment display driver used for game feedback and state display.

---

## Evaluation Logic

### Exact Match Condition

```verilog
(guess[0] == code[0]) &&
(guess[1] == code[1]) &&
(guess[2] == code[2]) &&
(guess[3] == code[3])
```
Verification (Phase 2)

The FSM was verified through simulation and waveform analysis.

Verification confirmed:

Correct state transitions

Proper handling of invalid inputs

Accurate life decrement logic

Correct score update mechanism

Stable reset behavior

Proper role switching

Waveform inspection validated compliance with project specifications.

Implementation & Deployment

RTL design implemented in Verilog

Synthesized using FPGA toolchain

Pin mapping configured via constraint file

Successfully programmed and tested on hardware

Skills Demonstrated

Finite State Machine (FSM) Design

Digital System Architecture

Verilog HDL Implementation

Hardware Debugging via Simulation

FPGA Synthesis & Deployment

Modular Hardware Design

Contributors

Umut Köprülü
Azra Arslan
