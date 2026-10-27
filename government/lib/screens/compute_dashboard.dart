import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ComputeDashboard extends StatefulWidget {
  const ComputeDashboard({super.key});

  @override
  State<ComputeDashboard> createState() => _ComputeDashboardState();
}

class _ComputeDashboardState extends State<ComputeDashboard> {
  final TextEditingController _promptController = TextEditingController();
  String _originalText = '';
  String _redactedText = '';
  int _entitiesFound = 0;
  bool _isProcessing = false;
  bool _hasProcessed = false;

  Future<void> _processPrompt() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _originalText = _promptController.text;
      _hasProcessed = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/v1/redact'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'sk_test_demo', // Using the test API key
        },
        body: jsonEncode({'text': _promptController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _redactedText = data['redacted_text'];
          _entitiesFound = data['entities_found'] ?? 0;
          _hasProcessed = true;
        });
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'API Error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e (Is the Node.js server running?)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Playground'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('API Online', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test the NLP Redaction API',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Type any sentence with a name, phone number, or citizen ID. The AI will redact it in real-time before it reaches an LLM.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Raw Text (Unsafe)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          Text('x-api-key: sk_test_demo', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptController,
                        maxLines: 4,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Please process a refund for Sujal Rai at 9841234567 with ID 1234567890.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _processPrompt,
                            icon: _isProcessing 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bolt, size: 18),
                            label: Text(_isProcessing ? 'Processing...' : 'Redact PII'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_hasProcessed) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Text('API Response', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_entitiesFound entities redacted',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B), // Dark editor theme for raw text
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Before API', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_originalText, style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981), width: 1),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('After API', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_redactedText, style: const TextStyle(color: Color(0xFFF8FAFC), height: 1.5, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}