
import os
import json
from app import app
from dotenv import load_dotenv

load_dotenv(override=True)

def test_integration():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("SKIPPING: GEMINI_API_KEY not found in environment.")
        return

    client = app.test_client()
    
    prompt = "Create a bell state"
    payload = {"prompt": prompt, "num_qubits": 2}
    
    print(f"Testing with prompt: '{prompt}'...")
    response = client.post('/generate_qasm', 
                           data=json.dumps(payload),
                           content_type='application/json')
    
    if response.status_code == 200:
        data = response.get_json()
        print("SUCCESS! Response received:")
        print(f"QASM:\n{data.get('qasm')}")
    else:
        print(f"FAILED with status {response.status_code}")
        print(f"Error: {response.get_json()}")

if __name__ == "__main__":
    test_integration()
