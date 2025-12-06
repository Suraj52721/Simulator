import 'package:flutter/material.dart';

class ParameterDialog extends StatefulWidget {
  final String title;
  final double initialValue;

  const ParameterDialog({
    super.key,
    required this.title,
    this.initialValue = 0.0,
  });

  @override
  State<ParameterDialog> createState() => _ParameterDialogState();
}

class _ParameterDialogState extends State<ParameterDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter angle theta (radians):"),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Theta",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, "REMOVE"), // Special sentinel for removal
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Remove Gate"),
        ),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(_controller.text);
            if (val != null) {
              Navigator.pop(context, val);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Invalid number")));
            }
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
