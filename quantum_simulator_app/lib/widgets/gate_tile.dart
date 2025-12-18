import 'package:flutter/material.dart';
import '../models/gate.dart'; // Added import

class GateTile extends StatelessWidget {
  final GateType type;
  final VoidCallback? onTap;

  const GateTile({super.key, required this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Draggable<GateType>(
      data: type,
      feedback: _buildBox(context, isFeedback: true),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildBox(context)),
      child: GestureDetector(onTap: onTap, child: _buildBox(context)),
    );
  }

  Widget _buildBox(BuildContext context, {bool isFeedback = false}) {
    Color color;
    String label = type.name.toUpperCase();

    // Handle specific label overrides
    switch (type) {
      case GateType.phase:
      case GateType.cp:
        label = "PHASE";
        break;
      default:
        // Default label is already type.name.toUpperCase()
        break;
    }

    switch (type) {
      case GateType.h:
        color = Colors.orangeAccent;
        break;
      case GateType.x:
      case GateType.y:
      case GateType.z:
        color = Colors.blueAccent;
        break;
      case GateType.cx:
      case GateType.cz:
        color = Colors.purpleAccent;
        break;
      case GateType.swap:
        color = Colors.tealAccent;
        break;
      case GateType.measure:
        color = Colors.grey[800]!;
        // Use icon for measure? We'll handle label below.
        break;
      case GateType.rx:
      case GateType.ry:
      case GateType.rz:
      case GateType.phase:
      case GateType.cp:
        color = Colors.pinkAccent;
        break;
      case GateType.s:
      case GateType.t:
        color = Colors.indigoAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: color.withOpacity(isFeedback ? 0.9 : 0.8),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: isFeedback
              ? [BoxShadow(color: color, blurRadius: 10)]
              : [],
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: type == GateType.measure
              ? const Icon(Icons.speed, color: Colors.white)
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
