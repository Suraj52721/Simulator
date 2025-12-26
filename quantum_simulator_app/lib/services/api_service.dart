import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/circuit.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // TODO: Replace with your actual deployed backend URL after deploying to Render/Heroku
  static const String _productionUrl =
      'https://quantum-simulator-backend-5thc.onrender.com';
  static const String _localUrl = 'http://127.0.0.1:5000';

  static String get baseUrl => kReleaseMode ? _productionUrl : _localUrl;

  Future<Map<String, dynamic>> runSimulation(
    CircuitState circuit, {
    int shots = 1024,
  }) async {
    final operations = circuit.exportCircuit();

    final body = {
      'num_qubits': circuit.numQubits,
      'operations': operations,
      'shots': shots,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/simulate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<String> generateQasm(String prompt, int numQubits) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_qasm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt, 'num_qubits': numQubits}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['qasm'] as String;
      } else {
        throw Exception('Generative fail: ${response.body}');
      }
    } catch (e) {
      throw Exception('AI Error: $e');
    }
  }
}
