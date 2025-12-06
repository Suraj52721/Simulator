
# Quantum Simulator Project

A beautiful, functional Quantum Computing Simulator built with **Flutter** (Frontend) and **Python Flask** (Backend).

## Prerequisites

- **Python 3.x**
- **Flutter SDK**
- **VS Code** (Recommended)

## Project Structure

- `backend/`: Python Flask server wrapping `quantum_lib.py`.
- `quantum_simulator_app/`: Flutter Desktop/Web application.
- `quantum_lib.py`: Core quantum engine.

## How to Run

### 1. Start the Backend Server
The frontend needs the python backend to perform calculations.

Open a terminal in the root `Simulator` directory:
```bash
pip install -r backend/requirements.txt
python backend/app.py
```
*The server will start on http://127.0.0.1:5000*

### 2. Run the Frontend App
Open a new terminal:
```bash
cd quantum_simulator_app
flutter pub get
flutter run -d windows
```
*(Or use `-d chrome` for web, `-d macos`/`-d linux` if on those platforms)*

## Features

- **Circuit Composer**: Drag and drop gates (H, X, Y, Z, CX, SWAP).
- **Visualization**: See probabilities of measurement outcomes.
- **Quantum Engine**: Powered by `quantum_lib.py` with support for Entanglement, Superposition, and multi-qubit gates.

## Troubleshooting

- **"Connection Refused"**: Ensure `backend/app.py` is running.
- **"ImportError"**: Make sure you run python from the `Simulator` root directory so it can find `quantum_lib.py`.
