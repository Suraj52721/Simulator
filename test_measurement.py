import quantum_lib
import numpy as np

def test_measurement_collapse():
    print("Testing H -> Measure -> H circuit...")
    # Circuit: H -> Measure -> H -> Measure
    # If collapse works: Output should be ~50/50 0/1
    # If collapse fails (deferred): H->H = I. Output 100% 0.
    
    circuit = quantum_lib.QuantumCircuit(1)
    circuit.h(0)
    circuit.measure(0, 0) # Intermediate measurement
    circuit.h(0)
    circuit.measure(0, 0) # Final measurement
    
    sim = quantum_lib.Simulator()
    counts = sim.run(circuit, shots=1000)
    
    print(f"Counts: {counts}")
    
    zeros = counts.get('0', 0)
    ones = counts.get('1', 0)
    
    if 400 < zeros < 600 and 400 < ones < 600:
        print("SUCCESS: State collapsed correctly (results are random).")
    else:
        print("FAILURE: State did not collapse (results are deterministic or biased).")

if __name__ == "__main__":
    test_measurement_collapse()
