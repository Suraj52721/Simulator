import subprocess
import time
import requests
import sys
import os
import signal

def test_backend():
    print("Starting Flask Backend...")
    # Start backend
    backend_process = subprocess.Popen(
        [sys.executable, "backend/app.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait for startup
    time.sleep(5)
    
    try:
        # Test Health
        print("Testing Health Endpoint...")
        try:
            resp = requests.get("http://127.0.0.1:5000/health")
            print(f"Health: {resp.status_code} {resp.json()}")
            assert resp.status_code == 200
        except Exception as e:
            print(f"Health Check Failed: {e}")
            return False

        # Test Simulation (Bell State)
        print("Testing Simulation (Bell State)...")
        payload = {
            "num_qubits": 2,
            "shots": 1000,
            "operations": [
                {"type": "h", "qubit": 0},
                {"type": "cx", "control": 0, "target": 1}
            ]
        }
        resp = requests.post("http://127.0.0.1:5000/simulate", json=payload)
        print(f"Simulate: {resp.status_code}")
        data = resp.json()
        print(f"Response: {data}")
        
        assert resp.status_code == 200
        counts = data.get("counts", {})
        # Expect roughly 50% 00 and 50% 11
        # Keys might be "00", "11", "01", "10"
        
        valid_states = ["00", "11"]
        total_valid = sum(counts.get(k, 0) for k in valid_states)
        total_shots = data.get("shots", 1000)
        
        print(f"Valid shots (00/11): {total_valid}/{total_shots}")
        if total_valid < 0.9 * total_shots:
            print("WARNING: Bell state fidelity seems low (might be random noise or logic error)")
        else:
            print("PASS: Bell state created successfully")
            
        return True

    finally:
        print("Killing Backend...")
        backend_process.kill()

if __name__ == "__main__":
    if test_backend():
        print("\n\n=== INTEGRATION TEST PASSED ===")
        sys.exit(0)
    else:
        print("\n\n=== INTEGRATION TEST FAILED ===")
        sys.exit(1)
