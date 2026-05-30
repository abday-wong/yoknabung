import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  String _selectedCategory = 'Kritik & Saran';

  final List<String> _categories = [
    'Kritik & Saran',
    'Laporan Bug',
    'Pengaduan Layanan',
    'Pertanyaan',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final category = _selectedCategory;
    final message = _messageController.text.trim();

    final StringBuffer bodyBuffer = StringBuffer();
    bodyBuffer.writeln('=== PENGADUAN & SARAN YOKNABUNG ===');
    bodyBuffer.writeln('Kategori: $category');
    bodyBuffer.writeln('Nama Pengirim: ${name.isNotEmpty ? name : 'Pengguna Anonim'}');
    bodyBuffer.writeln('Email Pengirim: ${email.isNotEmpty ? email : 'Tidak disediakan'}');
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
          _showManualEmailDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showManualEmailDialog();
      }
    }
  }

  void _showManualEmailDialog() {
    NeoDialog.showNeoDialog(
      context: context,
      title: 'Aplikasi Email Tidak Ditemukan',
      body: 'Gagal membuka aplikasi email secara otomatis. Silakan kirimkan kritik & saran Anda secara manual ke email:\n\nabday.hafidz23@gmail.com',
      primaryLabel: 'Tutup',
      primaryColor: const Color(0xFFFF5733),
      onPrimaryPressed: () {
        Navigator.pop(context);
      },
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
                          'Hubungi Kami',
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
                      'Suara Anda sangat berharga bagi kami. Tulis kritik, saran, laporan kendala, atau pengaduan Anda di bawah ini dan kirimkan ke email pengembang.',
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
              const SizedBox(height: 24),

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

              NeoButton(
                text: 'Kirim via Email',
                color: const Color(0xFF00C49A),
                icon: Icons.mail_outline,
                onPressed: _submitFeedback,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
