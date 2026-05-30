import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_dialog.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiUrlController = TextEditingController(text: 'https://httpbin.org/post');
  
  String _selectedCategory = 'Kritik & Saran';
  bool _useApi = false;
  bool _isSending = false;
  String? _apiResponse;
  bool _isSuccess = false;

  final List<String> _categories = [
    'Kritik & Saran',
    'Laporan Bug',
    'Pengaduan Layanan',
    'Pertanyaan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadApiUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('feedback_api_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        setState(() {
          _apiUrlController.text = savedUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading API URL: $e');
    }
  }

  Future<void> _sendFeedback() async {
    if (_useApi) {
      await _sendFeedbackApi();
    } else {
      await _sendFeedbackEmail();
    }
  }

  Future<void> _sendFeedbackEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final category = _selectedCategory;
    final message = _messageController.text.trim();

    final StringBuffer bodyBuffer = StringBuffer();
    bodyBuffer.writeln('=== PENGADUAN & SARAN YOKNABUNG ===');
    bodyBuffer.writeln('Kategori: $category');
    if (name.isNotEmpty) bodyBuffer.writeln('Nama Pengirim: $name');
    if (email.isNotEmpty) bodyBuffer.writeln('Email Pengirim: $email');
    bodyBuffer.writeln('-----------------------------------');
    bodyBuffer.writeln('Pesan:');
    bodyBuffer.writeln(message);
    bodyBuffer.writeln('-----------------------------------');

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'abday.hafidz23@gmail.com',
      queryParameters: {
        'subject': '[YokNabung] $category - ${name.isNotEmpty ? name : 'Pengguna'}',
        'body': bodyBuffer.toString(),
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          NeoDialog.showNeoSnackbar(
            context,
            message: 'Membuka aplikasi email Anda...',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showFeedbackErrorDialog(bodyBuffer.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        _showFeedbackErrorDialog(bodyBuffer.toString());
      }
    }
  }

  Future<void> _sendFeedbackApi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _apiResponse = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final category = _selectedCategory;
    final message = _messageController.text.trim();
    final url = _apiUrlController.text.trim();

    final payload = {
      'name': name,
      'email': email,
      'category': category,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('feedback_api_url', url);

      setState(() {
        _isSending = false;
        _apiResponse = 'Status Code: ${response.statusCode}\n\nResponse Body:\n${response.body}';
        _isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      });

      if (_isSuccess) {
        if (mounted) {
          NeoDialog.showNeoSnackbar(context, message: 'Pengaduan berhasil terkirim via API!');
        }
      } else {
        if (mounted) {
          NeoDialog.showNeoSnackbar(context, message: 'Gagal: Server merespons dengan status ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _apiResponse = 'Error: $e';
        _isSuccess = false;
      });
      if (mounted) {
        NeoDialog.showNeoSnackbar(context, message: 'Gagal menghubungi server API.');
      }
    }
  }

  void _showFeedbackErrorDialog(String bodyContent) {
    NeoDialog.showNeoDialog(
      context: context,
      title: 'Email Tidak Terbuka',
      body: 'Aplikasi email tidak terdeteksi. Silakan kirimkan kritik & saran secara manual ke abday.hafidz23@gmail.com.',
      primaryLabel: 'Tutup',
      primaryColor: const Color(0xFFFF5733),
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? Colors.white30 : Colors.black38;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFFDE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Kritik & Saran',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            color: borderColor,
            height: 2.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeoCard(
                color: const Color(0xFFFFE500),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback, color: const Color(0xFF111111), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Kirim Pengaduan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Suara Anda sangat berharga bagi kami. Kirim kritik, saran, atau pengaduan secara langsung ke email pengembang atau kirim ke server API/Postman Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mode Selector Switcher
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useApi = false;
                        _apiResponse = null;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_useApi ? const Color(0xFFFFE500) : cardBgColor,
                          border: Border.all(color: borderColor, width: 2.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Kirim Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: !_useApi ? const Color(0xFF111111) : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useApi = true;
                        _apiResponse = null;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _useApi ? const Color(0xFFFFE500) : cardBgColor,
                          border: Border.all(color: borderColor, width: 2.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Kirim via API / Postman',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _useApi ? const Color(0xFF111111) : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_useApi) ...[
                Text(
                  'API Endpoint URL (Target Postman)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    border: Border.all(color: borderColor, width: 2.5),
                  ),
                  child: TextFormField(
                    controller: _apiUrlController,
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'URL API tidak boleh kosong';
                      }
                      if (!value.startsWith('http://') && !value.startsWith('https://')) {
                        return 'URL harus diawali http:// atau https://';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'https://api.domain.com/feedback',
                      hintStyle: TextStyle(color: hintColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                'Nama Lengkap (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _nameController,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Nama Anda...',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Alamat Email (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Email Anda...',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Kategori Pengaduan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: cardBgColor,
                    isExpanded: true,
                    style: TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 14),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Isi Pengaduan / Kritik / Saran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Isi pengaduan tidak boleh kosong';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Tulis kritik, saran, laporan bug, atau pengaduan Anda di sini...',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _isSending
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C49A)),
                        ),
                      ),
                    )
                  : NeoButton(
                      text: _useApi ? 'Kirim via API POST' : 'Kirim Email',
                      color: const Color(0xFF00C49A),
                      icon: _useApi ? Icons.cloud_upload : Icons.send,
                      onPressed: _sendFeedback,
                    ),

              if (_apiResponse != null) ...[
                const SizedBox(height: 24),
                Text(
                  'HTTP Response (Hasil Postman-compatible):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? const Color(0xFF00C49A).withValues(alpha: 0.15)
                        : const Color(0xFFFF5733).withValues(alpha: 0.15),
                    border: Border.all(
                      color: _isSuccess ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _apiResponse!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
