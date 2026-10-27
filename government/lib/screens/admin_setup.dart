import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  String? _jwtToken;
  bool _isLoading = false;
  bool _isSyncing = false;
  List<String> _parsedNames = [];

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/v1/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text,
          'password': _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _jwtToken = data['token']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication Server Offline')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndParseCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final String fileContent = utf8.decode(result.files.single.bytes!);
        
        // Simple split by new lines (much more reliable than CSV parser for this demo)
        List<String> extractedNames = fileContent
            .split('\n')
            .map((e) => e.replaceAll('\r', '').trim()) 
            .where((e) => e.isNotEmpty) 
            .where((e) => e.toLowerCase() != 'name') 
            .toList();

        setState(() => _parsedNames = extractedNames);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully extracted ${extractedNames.length} names.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }

  Future<void> _syncData() async {
    if (_jwtToken == null || _parsedNames.isEmpty) return;
    setState(() => _isSyncing = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/v1/sync-customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
        body: jsonEncode({'customers': _parsedNames}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database synced successfully.')));
          setState(() => _parsedNames = []);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Failed')));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Admin'),
        actions: [
          if (_jwtToken != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () => setState(() => _jwtToken = null),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Secure Logout'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),
            )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _jwtToken == null ? _buildLoginScreen() : _buildDashboard(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Authentication', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text('Authorized personnel only.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 32),
          const Text('Username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextField(
            controller: _userController,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: const InputDecoration(hintText: 'Enter admin ID'),
          ),
          const SizedBox(height: 20),
          const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextField(
            controller: _passController,
            obscureText: true,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: const InputDecoration(hintText: '••••••••'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Authenticate'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Session Secured', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Firewall Dictionary Sync', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text('Upload a CSV file exported from your CRM containing customer names. The firewall will instantly redact these names from AI prompts.', style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
          const SizedBox(height: 32),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(Icons.upload_file, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                const Text('Upload Customer Database', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text('Only .CSV files are supported', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _pickAndParseCsv,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Select CSV File'),
                ),
              ],
            ),
          ),

          if (_parsedNames.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text('${_parsedNames.length} Names Ready to Sync', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _parsedNames.take(5).join(', ') + (_parsedNames.length > 5 ? '...' : ''),
                    style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncData,
                child: _isSyncing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text('Encrypt & Sync ${_parsedNames.length} Names to Firewall'),
              ),
            )
          ]
        ],
      ),
    );
  }
}