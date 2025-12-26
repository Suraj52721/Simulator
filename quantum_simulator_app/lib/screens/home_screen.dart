import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circuit.dart';
import '../models/gate.dart'; // Added import
import '../services/api_service.dart';
import '../widgets/circuit_grid.dart';
import '../widgets/gate_tile.dart';
import '../widgets/results_section.dart';
import '../widgets/code_editor.dart';
import '../dialogs/custom_gate_dialog.dart';
import '../models/preset.dart'; // Added import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _singleShot = false;
  double _visualPanelRatio = 0.6; // Initial ratio (3/5)
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
      // Also update on animation end for smoother transitions if needed
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                        GateType.cp, // Added CP
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
                      const SizedBox(width: 16),
                      // Presets Dropdown (Moved here)
                      PopupMenuButton<Preset?>(
                        tooltip: "Presets",
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.playlist_play,
                                size: 20,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Presets",
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                        onSelected: (preset) {
                          if (preset != null) {
                            context.read<CircuitState>().loadPreset(preset);
                          }
                        },
                        itemBuilder: (context) {
                          final presets = context
                              .read<CircuitState>()
                              .allPresets;
                          return [
                            ...presets.map(
                              (p) =>
                                  PopupMenuItem(value: p, child: Text(p.name)),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: null,
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) async {
                                  final name = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) {
                                      final controller =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: const Text("Save Custom Preset"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            labelText: "Preset Name",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (controller.text.isNotEmpty)
                                                Navigator.pop(
                                                  ctx,
                                                  controller.text,
                                                );
                                            },
                                            child: const Text("Save"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (name != null && context.mounted) {
                                    await context
                                        .read<CircuitState>()
                                        .saveCustomPreset(name);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Saved $name")),
                                    );
                                  }
                                });
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.save, color: Colors.black54),
                                  SizedBox(width: 8),
                                  Text("Save Current"),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),

                      const SizedBox(width: 8),
                      // Single Shot Toggle
                      Row(
                        children: [
                          Checkbox(
                            value: _singleShot,
                            onChanged: (v) =>
                                setState(() => _singleShot = v ?? false),
                            fillColor: MaterialStateProperty.all(
                              const Color(0xFF03DAC6),
                            ),
                          ),
                          const Text(
                            "Single Shot",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
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

    // Run Simulation Logic
    Future<void> runSimulation() async {
      if (circuit.isLoading) return;
      final state = context.read<CircuitState>();
      state.setLoading(true);
      try {
        final results = await api.runSimulation(
          state,
          shots: _singleShot ? 1 : 1024,
        );
        state.setResults(results);
      } catch (e) {
        state.setError(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    // Shared FAB
    FloatingActionButton buildFab() {
      // Logic duplicated or reused? Reuse runSimulation
      return FloatingActionButton.extended(
        onPressed: circuit.isLoading
            ? null
            : runSimulation, // Use shared function
        icon: const Icon(Icons.play_arrow),
        label: const Text("RUN", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03DAC6).withOpacity(0.3),
        foregroundColor: const Color(0xFF03DAC6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF03DAC6), width: 2),
        ),
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
          // Presets Menu REMOVED
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
            body: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final visualWidth = width * _visualPanelRatio;

                return Row(
                  children: [
                    SizedBox(width: visualWidth, child: buildVisualEditor()),
                    // Resizable Divider
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          // Update ratio based on delta
                          // Clamp between 0.3 and 0.7 to avoid breaking UI
                          final newRatio =
                              _visualPanelRatio + (details.delta.dx / width);
                          if (newRatio > 0.3 && newRatio < 0.7) {
                            _visualPanelRatio = newRatio;
                          }
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: Container(
                          width: 16,
                          color: Colors.transparent, // transparent touch area
                          child: Center(
                            child: Container(
                              width: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: CodeEditor(
                        onRun: circuit.isLoading ? null : runSimulation,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } else {
          // --- MOBILE / NARROW: Tab View ---
          // --- MOBILE / NARROW: Tab View ---
          return Scaffold(
            appBar: buildAppBar(
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on), text: "Visual"),
                  Tab(icon: Icon(Icons.code), text: "Code"),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                buildVisualEditor(),
                // Pass null to onRun so the internal button is hidden on mobile
                const CodeEditor(onRun: null),
              ],
            ),
            floatingActionButton: Padding(
              // Shift up if on Code tab (index 1) to avoid overlapping prompt box
              padding: EdgeInsets.only(
                bottom: _tabController.index == 1 ? 80.0 : 0.0,
              ),
              child: buildFab(),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }
      },
    );
  }
}
