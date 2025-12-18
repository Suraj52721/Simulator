import 'dart:math';
import 'gate.dart';

typedef CircuitGenerator = List<QuantumGate> Function(int numQubits);

class Preset {
  final String name;
  final String id;
  final CircuitGenerator generator;

  const Preset({required this.name, required this.id, required this.generator});

  // Helper for real QFT
  static List<QuantumGate> _realQFT(int n) {
    List<QuantumGate> gates = [];
    for (int i = 0; i < n; i++) {
      // H on qubit i
      gates.add(QuantumGate(id: "H", type: GateType.h, targetQubit: i));

      // Controlled Phase rotations
      for (int j = i + 1; j < n; j++) {
        // theta = pi / 2^(j-i)
        double theta = pi / pow(2, j - i);
        gates.add(
          QuantumGate(
            id: "CP",
            type: GateType.cp,
            targetQubit: j,
            controlQubit: i,
            parameter: theta,
          ),
        );
      }
    }
    // Swaps
    for (int i = 0; i < n ~/ 2; i++) {
      gates.add(
        QuantumGate(
          id: "SWAP",
          type: GateType.swap,
          targetQubit: n - 1 - i,
          controlQubit: i,
        ),
      );
    }
    return gates;
  }

  static List<Preset> builtins = [
    Preset(
      name: "Bell State",
      id: "bell",
      generator: (n) {
        if (n < 2) return [];
        return [
          QuantumGate(id: "H", type: GateType.h, targetQubit: 0),
          QuantumGate(
            id: "CX",
            type: GateType.cx,
            targetQubit: 1,
            controlQubit: 0,
          ),
        ];
      },
    ),
    Preset(
      name: "GHZ State",
      id: "ghz",
      generator: (n) {
        if (n < 3) return [];
        List<QuantumGate> gates = [
          QuantumGate(id: "H", type: GateType.h, targetQubit: 0),
        ];
        for (int i = 0; i < n - 1; i++) {
          gates.add(
            QuantumGate(
              id: "CX",
              type: GateType.cx,
              targetQubit: i + 1,
              controlQubit: i,
            ),
          );
        }
        return gates;
      },
    ),
    Preset(name: "QFT (Real)", id: "qft_real", generator: (n) => _realQFT(n)),
    Preset(
      name: "Grover (2 Qubits)",
      id: "grover_2",
      generator: (n) {
        if (n < 2) return [];
        List<QuantumGate> g = [];
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 0));
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 1));
        g.add(
          QuantumGate(
            id: "CZ",
            type: GateType.cz,
            targetQubit: 1,
            controlQubit: 0,
          ),
        );
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 0));
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 1));
        g.add(QuantumGate(id: "Z", type: GateType.z, targetQubit: 0));
        g.add(QuantumGate(id: "Z", type: GateType.z, targetQubit: 1));
        g.add(
          QuantumGate(
            id: "CZ",
            type: GateType.cz,
            targetQubit: 1,
            controlQubit: 0,
          ),
        );
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 0));
        g.add(QuantumGate(id: "H", type: GateType.h, targetQubit: 1));
        return g;
      },
    ),
    Preset(
      name: "Teleportation",
      id: "teleport",
      generator: (n) {
        if (n < 3) return [];
        return [
          QuantumGate(id: "H", type: GateType.h, targetQubit: 1),
          QuantumGate(
            id: "CX",
            type: GateType.cx,
            targetQubit: 2,
            controlQubit: 1,
          ),
          QuantumGate(
            id: "CX",
            type: GateType.cx,
            targetQubit: 1,
            controlQubit: 0,
          ),
          QuantumGate(id: "H", type: GateType.h, targetQubit: 0),
          QuantumGate(id: "M", type: GateType.measure, targetQubit: 0),
          QuantumGate(id: "M", type: GateType.measure, targetQubit: 1),
        ];
      },
    ),
  ];
}
