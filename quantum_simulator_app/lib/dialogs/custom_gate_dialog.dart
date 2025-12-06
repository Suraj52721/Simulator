import 'package:flutter/material.dart';

class CustomGateDialog extends StatefulWidget {
  const CustomGateDialog({super.key});

  @override
  State<CustomGateDialog> createState() => _CustomGateDialogState();
}

class _CustomGateDialogState extends State<CustomGateDialog> {
  final _r0c0 = TextEditingController(text: "1");
  final _r0c1 = TextEditingController(text: "0");
  final _r1c0 = TextEditingController(text: "0");
  final _r1c1 = TextEditingController(text: "-1");
  final _nameController = TextEditingController(text: "Z'");

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Custom Gate (2x2)"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Gate Name (e.g. MyGate)",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Matrix (Real numbers for MVP):"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInput(_r0c0)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput(_r0c1)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInput(_r1c0)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput(_r1c1)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            // Parse
            try {
              final mat = [
                [double.parse(_r0c0.text), double.parse(_r0c1.text)],
                [double.parse(_r1c0.text), double.parse(_r1c1.text)],
              ];

              // We don't save to state immediately because we need a target qubit to 'Apply' it.
              // For a "Toolbox" approach, we'd add it to a list of available gates.
              // BUT, the user asked to "add the gate".
              // Let's return the gate definition so the main screen can add it to the toolbox dynamically?
              // Or simpler: Just return it, and let the user drag it?
              // Current Architecture limitation: Toolbox is static list.
              // We will return the Gate Object, but we can't place it without drag.

              // New Plan: Add to a "Custom Gates" list in CircuitState?
              // For now, let's just make this dialog ADD it to a special "Custom" slot in the toolbox?
              // Or simplier: Just place it on Q0 Step 0 (unsafe).

              Navigator.pop(context, {
                'name': _nameController.text,
                'matrix': mat,
              });
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Invalid Numbers: $e")));
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
