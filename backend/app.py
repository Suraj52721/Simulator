import sys
import os
import logging

# Add parent directory to path to import quantum_lib
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from flask import Flask, request, jsonify
from flask_cors import CORS
import quantum_lib
import numpy as np

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/simulate', methods=['POST'])
def simulate():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Invalid JSON"}), 400
            
        num_qubits = data.get('num_qubits')
        operations = data.get('operations')
        shots = data.get('shots', 1024)
        
        if not num_qubits or not isinstance(num_qubits, int):
            return jsonify({"error": "num_qubits must be an integer > 0"}), 400
        if not operations or not isinstance(operations, list):
            return jsonify({"error": "operations must be a list of gate objects"}), 400

        # Initialize circuit
        circuit = quantum_lib.QuantumCircuit(num_qubits)
        
        # Apply operations
        for op in operations:
            gate_type = op.get('type')
            if not gate_type:
                continue
                
            gate_type = gate_type.lower()
            
            try:
                if gate_type == 'h':
                    circuit.h(op['qubit'])
                elif gate_type == 'x':
                    circuit.x(op['qubit'])
                elif gate_type == 'y':
                    circuit.y(op['qubit'])
                elif gate_type == 'z':
                    circuit.z(op['qubit'])
                elif gate_type == 't':
                    circuit.t(op['qubit'])
                elif gate_type == 's':
                    circuit.s(op['qubit'])
                elif gate_type == 'rx':
                    circuit.rx(op['qubit'], op.get('theta', 0.0))
                elif gate_type == 'ry':
                    circuit.ry(op['qubit'], op.get('theta', 0.0))
                elif gate_type == 'rz':
                    circuit.rz(op['qubit'], op.get('theta', 0.0))
                elif gate_type == 'phase':
                    circuit.phase(op['qubit'], op.get('theta', 0.0))
                elif gate_type == 'cx':
                    circuit.cx(op['control'], op['target'])
                elif gate_type == 'cz':
                    circuit.cz(op['control'], op['target'])
                elif gate_type == 'swap':
                    circuit.swap(op['qubit1'], op['qubit2'])
                elif gate_type == 'measure':
                     # Explicit measurement
                     # Backend expects (qubit, cbit)
                     # We map q -> cbit (same index for simplicity in this API version unless specified)
                     q = op['qubit']
                     c = op.get('cbit', q) 
                     circuit.measure(q, c)
                elif gate_type == 'custom':
                    # Custom gate: expects 'matrix' (2D list) and 'qubit'
                    matrix = op.get('matrix')
                    if not matrix:
                        return jsonify({"error": "Custom gate requires 'matrix'"}), 400
                    
                    # Convert list to numpy array
                    np_matrix = np.array(matrix)
                    circuit.operations.append(('custom', op['qubit'], np_matrix))
                    
                else:
                    logger.warning(f"Unknown gate type: {gate_type}")
            except KeyError as e:
                return jsonify({"error": f"Missing parameter for gate {gate_type}: {str(e)}"}), 400
            except Exception as e:
                return jsonify({"error": f"Error applying gate {gate_type}: {str(e)}"}), 400

        # Auto-measure ALL qubits IF AND ONLY IF no explicit measurements exist
        if not circuit.measurements:
            for i in range(num_qubits):
                circuit.measure(i, i)

        # Run simulation
        simulator = quantum_lib.Simulator()
        
        # Run and get counts
        # Note: quantum_lib.Simulator.run returns counts dict
        try:
            counts = simulator.run(circuit, shots=shots)
        except Exception as e:
            logger.error(f"Simulation error: {e}")
            # Fallback/Debug: print full stack trace if needed, but for now sane error msg
            return jsonify({"error": f"Simulation execution failed: {str(e)}"}), 500

        return jsonify({
            "counts": counts,
            "shots": shots,
            "num_qubits": num_qubits
        })

    except Exception as e:
        logger.exception("Global server error")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000, debug=True)
