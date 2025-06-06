# 🎯 Mastermind Terminal Game (Swift)

This is a terminal-based version of the classic **Mastermind** game written in **Swift**, using a live backend API to generate secret codes and validate guesses.

The goal is to guess a 4-digit code where each digit is between **1 and 6**, and all digits must be **unique**. After each guess, the game provides feedback using:

- `B` — Correct digit in the correct position
- `W` — Correct digit in the wrong position

The game continues until the player guesses the code or exits manually.

---

## 🛠️ Built With

- [Swift 5.10+](https://swift.org)
- [AsyncHTTPClient](https://github.com/swift-server/async-http-client)

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Manazd/MastermindGame-swift.git
cd MastermindGame-swift
