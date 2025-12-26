import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/circuit.dart';
import 'ai_prompt_field.dart';

class CodeEditor extends StatefulWidget {
  final VoidCallback? onRun;
  const CodeEditor({super.key, this.onRun});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate via state instead
    // _controller.text = ...
    // Listen to changes
    final circuit = context.read<CircuitState>();
    _controller.text = circuit.generatedCode;

    circuit.addListener(_onCircuitChanged);
  }

  @override
  void dispose() {
    context.read<CircuitState>().removeListener(_onCircuitChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onCircuitChanged() {
    // Only update if text is different to avoid cursor jumps / loops (if we were typing)
    // For MVP phase 3, we assume one way sync priority: Drag > Code.
    // If the user drags, code updates.
    // If user types, they hit apply.
    // We need to know if the change came from 'fromText' or 'Grid'.
    // Simple check:
    final newCode = context.read<CircuitState>().generatedCode;
    if (_controller.text != newCode) {
      // Check if the simulator is simpler?
      // Just update it.
      // Note: This might overwrite typing if a background process triggered it, but usually fine here.
      _controller.text = newCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.black26,
          child: Row(
            children: [
              const Icon(Icons.code, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                "QASM-lite Editor (e.g. 'H 0', 'CX 0 1')",
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<CircuitState>().fromText(_controller.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Circuit Applied!")),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text("Apply to Grid"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              style: GoogleFonts.firaCode(
                color: const Color(0xFF03DAC6),
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Type commands here...",
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ),
        ),
        // Run Button Row
        if (widget.onRun != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: widget.onRun,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  "RUN",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03DAC6).withOpacity(0.3),
                  foregroundColor: const Color(0xFF03DAC6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF03DAC6), width: 2),
                  ),
                  minimumSize: const Size(100, 48), // Match FAB standard height
                ),
              ),
            ),
          ),
        AIPromptField(
          onCodeGenerated: (qasm) {
            // 1. Update text editor immediately
            setState(() {
              _controller.text = qasm;
            });
            // 2. Parse and Apply to Circuit
            final circuit = context.read<CircuitState>();
            circuit.fromText(qasm);

            // 3. Feedback
            if (circuit.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Applied with warning: ${circuit.error}"),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("AI Circuit Applied Successfully!"),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
