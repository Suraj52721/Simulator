import 'package:flutter/material.dart';

class CnotDialog extends StatefulWidget {
  final int initialControl;
  final int initialTarget;
  final int numQubits;

  const CnotDialog({
    super.key,
    required this.initialControl,
    required this.initialTarget,
    required this.numQubits,
  });

  @override
  State<CnotDialog> createState() => _CnotDialogState();
}

class _CnotDialogState extends State<CnotDialog> {
  late int control;
  late int target;

  @override
  void initState() {
    super.initState();
    control = widget.initialControl;
    target = widget.initialTarget;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Configure CNOT"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDropdown("Control Qubit", control, (val) {
            setState(() => control = val!);
          }),
          const SizedBox(height: 16),
          _buildDropdown("Target Qubit", target, (val) {
            setState(() => target = val!);
          }),
          if (control == target)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Control and Target must be different!",
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: (control == target)
              ? null
              : () {
                  Navigator.pop(context, {
                    'control': control,
                    'target': target,
                  });
                },
          child: const Text("Update"),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, int value, ValueChanged<int?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        DropdownButton<int>(
          value: value,
          items: List.generate(
            widget.numQubits,
            (i) => DropdownMenuItem(value: i, child: Text("q[$i]")),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
