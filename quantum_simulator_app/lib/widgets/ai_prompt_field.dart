import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circuit.dart';
import '../services/api_service.dart';

class AIPromptField extends StatefulWidget {
  final Function(String) onCodeGenerated;

  const AIPromptField({super.key, required this.onCodeGenerated});

  @override
  State<AIPromptField> createState() => _AIPromptFieldState();
}

class _AIPromptFieldState extends State<AIPromptField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final numQubits = context.read<CircuitState>().numQubits;
      var qasm = await api.generateQasm(prompt, numQubits);

      // Sanitize: strip markdown, remove semicolons, trim
      qasm = qasm.replaceAll(RegExp(r'```.*'), '').replaceAll('```', '');
      qasm = qasm.replaceAll(';', '');
      qasm = qasm.trim();

      widget.onCodeGenerated(qasm);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("QASM Generated!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF03DAC6).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF03DAC6).withOpacity(0.3),
                blurRadius: _glowAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/8/8a/Google_Gemini_logo.svg',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.auto_awesome, color: Color(0xFF03DAC6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Ask AI to build a circuit...",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submitPrompt(),
                ),
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Color(0xFF03DAC6)),
                onPressed: _isLoading ? null : _submitPrompt,
              ),
            ],
          ),
        );
      },
    );
  }
}
