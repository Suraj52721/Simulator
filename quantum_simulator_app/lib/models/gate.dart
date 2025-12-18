enum GateType {
  h,
  x,
  y,
  z,
  cx,
  cz,
  swap,
  phase,
  cp, // Controlled-Phase
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
    } else if (type == GateType.cp) {
      data['control'] = controlQubit;
      data['target'] = targetQubit;
      data['theta'] = parameter ?? 0.0;
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

  factory QuantumGate.fromJson(Map<String, dynamic> json) {
    String typeStr = json['type'].toString().toLowerCase();

    // Reverse mapping
    GateType type = GateType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr,
      orElse: () => GateType.custom, // Fallback
    );

    int target = json['qubit'] ?? json['target'] ?? 0;
    int? control = json['control'] ?? json['qubit1'];
    // Swap quirk: qubit2 is target
    if (type == GateType.swap) {
      target = json['qubit2'] ?? 0;
    }

    double? theta = json['theta'];
    List<List<double>>? matrix;
    if (json['matrix'] != null) {
      matrix = (json['matrix'] as List)
          .map((r) => (r as List).cast<double>())
          .toList();
    }

    String id = type.name.toUpperCase();
    if (type == GateType.rx) id = "RX";
    if (type == GateType.ry) id = "RY";
    if (type == GateType.rz) id = "RZ";
    if (type == GateType.phase) id = "P";
    if (type == GateType.measure) id = "M";

    return QuantumGate(
      id: id,
      type: type,
      targetQubit: target,
      controlQubit: control,
      parameter: theta,
      matrix: matrix,
    );
  }
}
