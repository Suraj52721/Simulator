import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'gate.dart';
import 'preset.dart';

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
          } else if (gate.type == GateType.cz) {
            buffer.writeln("CZ ${gate.controlQubit} ${gate.targetQubit}");
          } else if (gate.type == GateType.cp) {
            buffer.writeln(
              "CP ${gate.controlQubit} ${gate.targetQubit} ${gate.parameter ?? 0.0}",
            );
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
        } else if (cmd == 'cp') {
          int ctrl = int.parse(parts[1]);
          int trgt = int.parse(parts[2]);
          double theta = double.parse(parts[3]);
          placeGate(
            QuantumGate(
              id: "CP",
              type: GateType.cp,
              targetQubit: trgt,
              controlQubit: ctrl,
              parameter: theta,
            ),
            trgt,
            step,
          );
        }
        step++;
      }
    } catch (e) {
      setError("Parse Error: $e");
    }
  }

  // --- PRESETS & PERSISTENCE ---

  List<Preset> _customPresets = [];
  List<Preset> get allPresets => [...Preset.builtins, ..._customPresets];

  CircuitState() {
    _init();
  }

  Future<void> _init() async {
    await _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('custom_presets');
    if (saved != null) {
      _customPresets = saved.map((jsonStr) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return Preset(
          name: map['name'],
          id: map['id'],
          generator: (n) {
            final List<dynamic> gateList = map['gates'];
            return gateList
                .map((gJson) => QuantumGate.fromJson(gJson))
                .toList();
          },
        );
      }).toList();
      notifyListeners();
    }
  }

  Future<void> saveCustomPreset(String name) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Capture current gates
    List<QuantumGate> currentGates = [];
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
          // We need to preserve the step information implicitly by order?
          // Or explicitly?
          // The generator returns a List<QuantumGate>.
          // If we just return a list, how does `loadPreset` know where to put them?
          // `loadPreset` below will likely just place them sequentially or use their original positions if stored.
          // BUT `QuantumGate` doesn't store 'step'.
          // Limitation: Our simple Preset system assumes generated gates are placed sequentially or logic dictates placement.
          // For Custom Presets, we want to SAVE the exact circuit.
          // So we should serialize the GRID structure or easier:
          // Just serialize the list of gates, but we lose 'empty steps'.
          // If we want exact replica, we need "step" in QuantumGate or wrapper.
          // Let's hack: The Preset Generator for custom presets will return gates with "targetQubit" preserved.
          // But "step"?
          // Let's rely on the fact that `loadPreset` will try to place them.
          // If `loadPreset` places them sequentially, we lose specific timing.
          // For now, let's just save the gates and place them sequentially.
          currentGates.add(gate);
        }
      }
    }

    final newPreset = Preset(
      name: name,
      id: "custom_${DateTime.now().millisecondsSinceEpoch}",
      generator: (n) => currentGates, // Closure captures currentGates
    );

    _customPresets.add(newPreset);

    // Persist
    List<String> toSave = _customPresets.map((p) {
      // We need to serialize the generator result (the gates)
      // We assume custom presets don't depend on 'n' dynamically in the closure
      // (they are static snapshots).
      final gates = p.generator(0); // n doesn't matter for specific snapshot
      Map<String, dynamic> data = {
        'name': p.name,
        'id': p.id,
        'gates': gates.map((g) => g.toJson()).toList(),
      };
      return jsonEncode(data);
    }).toList();

    await prefs.setStringList('custom_presets', toSave);
    notifyListeners();
  }

  void loadPreset(Preset preset) {
    clear();
    // Dynamic adjustment?
    // If preset is "QFT", it uses current numQubits.
    // If preset is "Custom", it has fixed gates.
    // We should probably check if custom preset qubits > current numQubits?
    // For now, just try to place.

    List<QuantumGate> gates = preset.generator(numQubits);

    // Crude placement logic:
    // If gates collide on a qubit, move to next step.
    // This is "ASAP" scheduling.

    // helper to track used steps per qubit
    Map<int, int> qubitNextStep = {};
    for (int i = 0; i < numQubits; i++) qubitNextStep[i] = 0;

    for (final gate in gates) {
      if (gate.targetQubit >= numQubits) {
        // Skip gates that don't fit
        continue;
      }

      int bestStep = qubitNextStep[gate.targetQubit]!;

      if (gate.type == GateType.cx ||
          gate.type == GateType.cz ||
          gate.type == GateType.swap ||
          gate.type == GateType.cp) {
        int control = gate.controlQubit!;
        if (control >= numQubits) continue;

        bestStep = max(bestStep, qubitNextStep[control]!);
      }

      placeGate(gate, gate.targetQubit, bestStep);

      qubitNextStep[gate.targetQubit] = bestStep + 1;
      if (gate.type == GateType.cx ||
          gate.type == GateType.cz ||
          gate.type == GateType.swap ||
          gate.type == GateType.cp) {
        qubitNextStep[gate.controlQubit!] = bestStep + 1;
      }
    }
    notifyListeners();
  }

  // Helper for max
  int max(int a, int b) => a > b ? a : b;
}
