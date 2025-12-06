import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circuit.dart';
import '../services/api_service.dart';
import '../widgets/circuit_grid.dart';
import '../widgets/gate_tile.dart';
import '../widgets/results_section.dart';
import '../widgets/code_editor.dart';
import '../dialogs/custom_gate_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch circuit to keep FAB enabled/disabled state
    final circuit = context.watch<CircuitState>();
    final api = ApiService();

    // Define the Visual Editor Part (Toolbox + Grid + Results)
    Widget buildVisualEditor() {
      return Column(
        children: [
          // 1. Controls & Toolbox
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Column(
              children: [
                // Toolbox Row
                SizedBox(
                  height: 70,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    children: [
                      ...[
                        GateType.h,
                        GateType.x,
                        GateType.y,
                        GateType.z,
                        GateType.cx,
                        GateType.swap,
                        GateType.rx,
                        GateType.ry,
                        GateType.rz,
                        GateType.phase,
                        GateType.s,
                        GateType.t,
                        GateType.measure,
                      ].map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GateTile(type: t),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: "Custom Gate",
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (_) => const CustomGateDialog(),
                          );
                          if (result is Map) {
                            final mat = (result['matrix'] as List)
                                .map((r) => (r as List).cast<double>())
                                .toList();
                            context.read<CircuitState>().placeGate(
                              QuantumGate(
                                id: result['name'],
                                type: GateType.custom,
                                targetQubit: 0,
                                matrix: mat,
                              ),
                              0,
                              0,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Qubit Manager Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Text("Qubits: "),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, size: 20),
                        onPressed: () =>
                            context.read<CircuitState>().removeQubit(),
                      ),
                      Text("${circuit.numQubits}"),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 20),
                        onPressed: () =>
                            context.read<CircuitState>().addQubit(),
                      ),
                      const Spacer(),
                      // On Mobile, this header helps. On Desktop, it's implied.
                      const Text(
                        "Visual Editor",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Circuit Grid
          const Expanded(flex: 3, child: CircuitGrid()),

          Divider(height: 1, color: Colors.white.withOpacity(0.1)),

          // 3. Results
          const Expanded(flex: 2, child: ResultsSection()),
        ],
      );
    }

    // Shared FAB
    FloatingActionButton buildFab() {
      return FloatingActionButton.extended(
        onPressed: circuit.isLoading
            ? null
            : () async {
                final state = context.read<CircuitState>();
                state.setLoading(true);
                try {
                  final results = await api.runSimulation(state);
                  state.setResults(results);
                } catch (e) {
                  state.setError(e.toString());
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
        icon: const Icon(Icons.play_arrow),
        label: const Text("RUN"),
        backgroundColor: const Color(0xFF03DAC6),
      );
    }

    // Shared AppBar
    PreferredSizeWidget buildAppBar({TabBar? bottom}) {
      return AppBar(
        title: const Text("Quantum Simulator"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: bottom,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Circuit',
            onPressed: () {
              context.read<CircuitState>().clear();
            },
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 900px
        if (constraints.maxWidth >= 900) {
          // --- DESKTOP / WIDE: Split View ---
          return Scaffold(
            appBar: buildAppBar(),
            body: Row(
              children: [
                Expanded(flex: 3, child: buildVisualEditor()),
                VerticalDivider(width: 1, color: Colors.white.withOpacity(0.1)),
                const Expanded(flex: 2, child: CodeEditor()),
              ],
            ),
            floatingActionButton: buildFab(),
          );
        } else {
          // --- MOBILE / NARROW: Tab View ---
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: buildAppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on), text: "Visual"),
                    Tab(icon: Icon(Icons.code), text: "Code"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [buildVisualEditor(), const CodeEditor()],
              ),
              floatingActionButton: buildFab(),
            ),
          );
        }
      },
    );
  }
}
