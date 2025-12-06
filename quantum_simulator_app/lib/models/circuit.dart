import 'package:flutter/foundation.dart';

enum GateType {
  h,
  x,
  y,
  z,
  cx,
  cz,
  swap,
  phase,
  t,
  s,
  rx,
  ry,
  rz,
  measure,
  custom,
}

class QuantumGate {
  final String id;
  final GateType type;
  final int targetQubit;
  final int? controlQubit; // For CX, CZ
  final double? parameter; // For Phase, Rx, Ry, Rz
  final List<List<double>>? matrix; // For Custom Gates

  QuantumGate({
    required this.id,
    required this.type,
    required this.targetQubit,
    this.controlQubit,
    this.parameter,
    this.matrix,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'type': type.name.toUpperCase()};

    // Backend mapping
    data['type'] = type.name;

    if (type == GateType.cx || type == GateType.cz) {
      data['control'] = controlQubit;
      data['target'] = targetQubit;
    } else if (type == GateType.swap) {
      data['qubit1'] = controlQubit; // Swap uses two qubits, reusing fields
      data['qubit2'] = targetQubit;
    } else if (type == GateType.measure) {
      // Backend expects 'qubit'
      data['qubit'] = targetQubit;
      // Optional: data['cbit'] = targetQubit; (default behavior in backend)
    } else {
      data['qubit'] = targetQubit;
      if (parameter != null) {
        data['theta'] = parameter;
      }
      if (type == GateType.custom && matrix != null) {
        data['matrix'] = matrix;
      }
    }
    return data;
  }
}

class CircuitState extends ChangeNotifier {
  int numQubits = 3;
  // grid[qubitIndex][stepIndex] = Gate?
  final Map<int, Map<int, QuantumGate>> _grid = {};
  final List<QuantumGate> _customGates = [];

  List<String> get customGateNames =>
      _customGates.map((g) => g.id).toSet().toList();

  String _generatedCode = "";
  String get generatedCode => _generatedCode;

  // Phase 3: QASM Logic
  void updateCodeFromGrid() {
    StringBuffer buffer = StringBuffer();

    // 1. Calculate max step
    int maxStep = 0;
    _grid.values.forEach((map) {
      if (map.keys.isNotEmpty) {
        int m = map.keys.reduce((a, b) => a > b ? a : b);
        if (m > maxStep) maxStep = m;
      }
    });

    // 2. Iterate
    for (int step = 0; step <= maxStep; step++) {
      for (int q = 0; q < numQubits; q++) {
        final gate = getGateAt(q, step);
        if (gate != null) {
          if (gate.type == GateType.h)
            buffer.writeln("H $q");
          else if (gate.type == GateType.x)
            buffer.writeln("X $q");
          else if (gate.type == GateType.y)
            buffer.writeln("Y $q");
          else if (gate.type == GateType.z)
            buffer.writeln("Z $q");
          else if (gate.type == GateType.t)
            buffer.writeln("T $q");
          else if (gate.type == GateType.s)
            buffer.writeln("S $q");
          else if (gate.type == GateType.rx)
            buffer.writeln("RX $q ${gate.parameter ?? 0.0}");
          else if (gate.type == GateType.ry)
            buffer.writeln("RY $q ${gate.parameter ?? 0.0}");
          else if (gate.type == GateType.rz)
            buffer.writeln("RZ $q ${gate.parameter ?? 0.0}");
          else if (gate.type == GateType.phase)
            buffer.writeln("PHASE $q ${gate.parameter ?? 0.0}");
          else if (gate.type == GateType.measure)
            buffer.writeln("MEASURE $q");
          else if (gate.type == GateType.cx || gate.type == GateType.custom) {
            if (gate.type == GateType.cx) {
              buffer.writeln("CX ${gate.controlQubit} ${gate.targetQubit}");
            } else {
              buffer.writeln("CUSTOM ${gate.id} $q");
            }
          } else if (gate.type == GateType.swap) {
            buffer.writeln("SWAP ${gate.controlQubit} ${gate.targetQubit}");
          }
        }
      }
    }
    _generatedCode = buffer.toString();
  }

  void addQubit() {
    numQubits++;
    updateCodeFromGrid();
    notifyListeners();
  }

  void removeQubit() {
    if (numQubits > 1) {
      _grid.remove(numQubits - 1);
      numQubits--;
      updateCodeFromGrid();
      notifyListeners();
    }
  }

  Map<String, dynamic> _lastResults = {};
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get lastResults => _lastResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  QuantumGate? getGateAt(int qubit, int step) {
    if (_grid.containsKey(qubit)) {
      return _grid[qubit]![step];
    }
    return null;
  }

  void clear() {
    _grid.clear();
    _lastResults = {};
    _error = null;
    updateCodeFromGrid();
    notifyListeners();
  }

  void placeGate(QuantumGate gate, int qubit, int step) {
    if (!_grid.containsKey(qubit)) _grid[qubit] = {};
    _grid[qubit]![step] = gate;
    updateCodeFromGrid();
    notifyListeners();
  }

  void removeGate(int qubit, int step) {
    if (_grid.containsKey(qubit)) {
      _grid[qubit]!.remove(step);
      updateCodeFromGrid();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> exportCircuit() {
    List<Map<String, dynamic>> ops = [];
    int maxStep = 0;
    _grid.values.forEach((map) {
      if (map.keys.isNotEmpty) {
        int m = map.keys.reduce((a, b) => a > b ? a : b);
        if (m > maxStep) maxStep = m;
      }
    });

    for (int step = 0; step <= maxStep; step++) {
      for (int q = 0; q < numQubits; q++) {
        final gate = getGateAt(q, step);
        if (gate != null) {
          ops.add(gate.toJson());
        }
      }
    }
    return ops;
  }

  void setResults(Map<String, dynamic> results) {
    _lastResults = results;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void setError(String err) {
    _error = err;
    _isLoading = false;
    notifyListeners();
  }

  void updateQubitCount(int count) {
    numQubits = count;
    _grid.clear();
    _lastResults = {};
    updateCodeFromGrid();
    notifyListeners();
  }

  // Phase 2: Code Editor Parser
  void fromText(String code) {
    clear();
    try {
      final lines = code.split('\n');
      int step = 0;

      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty || parts[0].isEmpty) continue;

        final cmd = parts[0].toLowerCase();

        if (cmd == 'h') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'H', type: GateType.h, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 'x') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'X', type: GateType.x, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 'y') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'Y', type: GateType.y, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 'z') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'Z', type: GateType.z, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 't') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'T', type: GateType.t, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 's') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'S', type: GateType.s, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 'measure') {
          int q = int.parse(parts[1]);
          placeGate(
            QuantumGate(id: 'M', type: GateType.measure, targetQubit: q),
            q,
            step,
          );
        } else if (cmd == 'rx' ||
            cmd == 'ry' ||
            cmd == 'rz' ||
            cmd == 'phase') {
          int q = int.parse(parts[1]);
          double theta = double.parse(parts[2]);
          GateType type;
          String id;
          if (cmd == 'rx') {
            type = GateType.rx;
            id = 'RX';
          } else if (cmd == 'ry') {
            type = GateType.ry;
            id = 'RY';
          } else if (cmd == 'rz') {
            type = GateType.rz;
            id = 'RZ';
          } else {
            type = GateType.phase;
            id = 'P';
          }

          placeGate(
            QuantumGate(id: id, type: type, targetQubit: q, parameter: theta),
            q,
            step,
          );
        } else if (cmd == 'cx' || cmd == 'cnot') {
          int ctrl = int.parse(parts[1]);
          int trgt = int.parse(parts[2]);
          placeGate(
            QuantumGate(
              id: 'CX',
              type: GateType.cx,
              targetQubit: trgt,
              controlQubit: ctrl,
            ),
            trgt,
            step,
          );
        } else if (cmd == 'cz') {
          int ctrl = int.parse(parts[1]);
          int trgt = int.parse(parts[2]);
          placeGate(
            QuantumGate(
              id: 'CZ',
              type: GateType.cz,
              targetQubit: trgt,
              controlQubit: ctrl,
            ),
            trgt,
            step,
          );
        } else if (cmd == 'swap') {
          int q1 = int.parse(parts[1]);
          int q2 = int.parse(parts[2]);
          placeGate(
            QuantumGate(
              id: 'SWAP',
              type: GateType.swap,
              targetQubit: q2,
              controlQubit: q1,
            ),
            q2,
            step,
          );
          // Also make sure to show it on q1 visually?
          // Currently visualizer handles control/swap gates via painter,
          // but `placeGate` only stores at target.
        }
        step++;
      }
    } catch (e) {
      setError("Parse Error: $e");
    }
  }
}
