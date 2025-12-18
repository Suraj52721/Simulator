import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circuit.dart';
import 'gate_tile.dart';
import '../models/gate.dart'; // Added import
import '../dialogs/cnot_dialog.dart';
import '../dialogs/parameter_dialog.dart';

class CircuitGrid extends StatelessWidget {
  const CircuitGrid({super.key});

  // Increased to 20 to allow longer circuits
  static const int maxSteps = 20;
  static const double rowHeight = 60.0;
  static const double cellWidth = 60.0;
  static const double labelWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    final circuit = context.watch<CircuitState>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: labelWidth + (maxSteps * cellWidth) + 40,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                // Background Painter for Lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: CircuitPainter(
                      circuit,
                      rowHeight: CircuitGrid.rowHeight,
                      leftOffset: CircuitGrid.labelWidth,
                      cellWidth: CircuitGrid.cellWidth,
                      maxSteps: CircuitGrid.maxSteps,
                    ),
                  ),
                ),
                // 1. The Grid Rows
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(circuit.numQubits, (qIndex) {
                    return Row(
                      children: [
                        // Qubit Label
                        Container(
                          width: labelWidth,
                          height: rowHeight,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            'q[$qIndex]',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        // Wire + Drop Targets
                        ...List.generate(maxSteps, (stepIndex) {
                          return _buildGridCell(
                            context,
                            qIndex,
                            stepIndex,
                            circuit,
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCell(
    BuildContext context,
    int qIndex,
    int stepIndex,
    CircuitState circuit,
  ) {
    final gate = circuit.getGateAt(qIndex, stepIndex);

    return Container(
      width: cellWidth,
      height: rowHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wire Line
          Container(width: double.infinity, height: 2, color: Colors.grey[700]),
          // Drop Target
          DragTarget<GateType>(
            onAccept: (type) {
              final newGate = QuantumGate(
                id: DateTime.now().toIso8601String(),
                type: type,
                targetQubit: qIndex,
                controlQubit:
                    (type == GateType.cx ||
                        type == GateType.cz ||
                        type == GateType.cp)
                    ? (qIndex > 0 ? qIndex - 1 : qIndex + 1)
                    : null,
                parameter: (type == GateType.cp)
                    ? 1.5708
                    : null, // Default pi/2 for CP
              );

              if (type == GateType.cx ||
                  type == GateType.cz ||
                  type == GateType.cp) {
                int control = qIndex == 0 ? 1 : qIndex - 1;
                context.read<CircuitState>().placeGate(
                  QuantumGate(
                    id: newGate.id,
                    type: type,
                    targetQubit: qIndex,
                    controlQubit: control,
                  ),
                  qIndex,
                  stepIndex,
                );
              } else {
                context.read<CircuitState>().placeGate(
                  newGate,
                  qIndex,
                  stepIndex,
                );
              }
            },
            builder: (context, candidates, projects) {
              return gate != null
                  ? GateTile(
                      type: gate.type,
                      onTap: () async {
                        if (gate.type == GateType.cx ||
                            gate.type == GateType.cz ||
                            gate.type == GateType.swap ||
                            gate.type == GateType.cp) {
                          // CNOT / CZ / SWAP / CP Dialog
                          final result = await showDialog<Map<String, int>>(
                            context: context,
                            builder: (ctx) => CnotDialog(
                              initialControl: gate.controlQubit ?? 0,
                              initialTarget: gate.targetQubit,
                              numQubits: circuit.numQubits,
                            ),
                          );

                          if (result != null) {
                            context.read<CircuitState>().placeGate(
                              QuantumGate(
                                id: gate.id,
                                type: gate.type,
                                targetQubit: result['target']!,
                                controlQubit: result['control']!,
                              ),
                              result['target']!, // Place at new target
                              stepIndex,
                            );
                            // If target changed, we should remove from old target?
                            // actually placeGate overwrites. But if target index changed, old position remains.
                            // So we remove first.
                            if (result['target'] != qIndex) {
                              context.read<CircuitState>().removeGate(
                                qIndex,
                                stepIndex,
                              );
                            }
                          }
                        } else if (gate.type == GateType.rx ||
                            gate.type == GateType.ry ||
                            gate.type == GateType.rz ||
                            gate.type == GateType.phase) {
                          // Parameter Dialog
                          final result = await showDialog(
                            context: context,
                            builder: (ctx) => ParameterDialog(
                              title: "Edit ${gate.type.name.toUpperCase()}",
                              initialValue: gate.parameter ?? 0.0,
                            ),
                          );

                          if (result == "REMOVE") {
                            context.read<CircuitState>().removeGate(
                              qIndex,
                              stepIndex,
                            );
                          } else if (result is double) {
                            context.read<CircuitState>().placeGate(
                              QuantumGate(
                                id: gate.id,
                                type: gate.type,
                                targetQubit: qIndex,
                                parameter: result,
                              ),
                              qIndex,
                              stepIndex,
                            );
                          }
                        } else {
                          // Simple Delete for others (H, X, Y, Z, etc.)
                          context.read<CircuitState>().removeGate(
                            qIndex,
                            stepIndex,
                          );
                        }
                      },
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: candidates.isNotEmpty
                            ? Colors.white10
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }
}

class CircuitPainter extends CustomPainter {
  final CircuitState circuit;
  final double rowHeight;
  final double leftOffset;
  final double cellWidth;
  final int maxSteps;

  CircuitPainter(
    this.circuit, {
    required this.rowHeight,
    required this.leftOffset,
    required this.cellWidth,
    required this.maxSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.fill;

    for (int step = 0; step < maxSteps; step++) {
      for (int q = 0; q < circuit.numQubits; q++) {
        final gate = circuit.getGateAt(q, step);
        if (gate != null) {
          if (gate.type == GateType.cx ||
              gate.type == GateType.cz ||
              gate.type == GateType.swap ||
              gate.type == GateType.cp ||
              gate.type == GateType.phase) {
            final control = gate.controlQubit;
            final target = gate.targetQubit;

            if (control != null) {
              final x = leftOffset + (step * cellWidth) + (cellWidth / 2);
              final yControl = (control * rowHeight) + (rowHeight / 2);
              final yTarget = (target * rowHeight) + (rowHeight / 2);

              canvas.drawLine(Offset(x, yControl), Offset(x, yTarget), paint);
              canvas.drawCircle(Offset(x, yControl), 5.0, dotPaint);

              if (gate.type == GateType.cz) {
                canvas.drawCircle(Offset(x, yTarget), 5.0, dotPaint);
              }
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) {
    return true;
  }
}
