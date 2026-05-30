import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_dialog.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String numStr = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (numStr.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final intVal = int.parse(numStr);
    final formatter = NumberFormat('#,###', 'id_ID');
    String formatted = formatter.format(intVal).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddEditTransactionScreen extends StatefulWidget {
  final String goalId;
  final Transaction? existingTransaction;

  const AddEditTransactionScreen({
    super.key,
    required this.goalId,
    this.existingTransaction,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  late double _amount;
  late DateTime _date;
  late String _note;
  String? _proofImagePath;

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;

    _type = tx?.type ?? TransactionType.deposit;
    _amount = tx?.amount ?? 0.0;
    _date = tx?.date ?? DateTime.now();
    _note = tx?.note ?? '';
    _proofImagePath = tx?.proofImagePath;

    String amountText = '';
    if (tx != null) {
      final formatter = NumberFormat('#,###', 'id_ID');
      amountText = formatter.format(tx.amount.toInt()).replaceAll(',', '.');
    }

    _amountController = TextEditingController(text: amountText);
    _noteController = TextEditingController(text: _note);

    _amountController.addListener(() {
      String cleanStr = _amountController.text.replaceAll('.', '');
      setState(() {
        _amount = double.tryParse(cleanStr) ?? 0.0;
      });
    });

    _noteController.addListener(() {
      setState(() {
        _note = _noteController.text;
      });
    });
  }

  Future<String> _saveImagePermanently(String path) async {
    if (kIsWeb) return path;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newFile = File('${directory.path}/$name');
      final savedFile = await File(path).copy(newFile.path);
      return savedFile.path;
    } catch (e) {
      debugPrint('Failed to save image permanently: $e');
      return path;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final permanentPath = await _saveImagePermanently(image.path);
        setState(() {
          _proofImagePath = permanentPath;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        NeoDialog.showNeoSnackbar(context, message: 'Gagal mengambil gambar');
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final provider = Provider.of<SavingsProvider>(context, listen: false);
        final isDark = provider.isDarkMode;
        final textColor = isDark ? Colors.white : const Color(0xFF111111);
        final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final borderColor = isDark ? Colors.white : const Color(0xFF111111);

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [BoxShadow(color: borderColor, offset: const Offset(4, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                ),
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  'Pilih Sumber Foto Bukti',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: textColor),
                title: Text(
                  'Kamera',
                  style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              Container(height: 2, color: borderColor),
              ListTile(
                leading: Icon(Icons.photo_library, color: textColor),
                title: Text(
                  'Galeri Foto',
                  style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF111111),
              onPrimary: Color(0xFFFFFDE7),
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _addQuickAmount(double value) {
    double currentVal = 0.0;
    String cleanStr = _amountController.text.replaceAll('.', '');
    if (cleanStr.isNotEmpty) {
      currentVal = double.tryParse(cleanStr) ?? 0.0;
    }

    double newVal = currentVal + value;
    final formatter = NumberFormat('#,###', 'id_ID');
    String formatted = formatter.format(newVal.toInt()).replaceAll(',', '.');

    setState(() {
      _amountController.text = formatted;
      _amount = newVal;
    });
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    if (_amount <= 0) {
      NeoDialog.showNeoSnackbar(context, message: 'Nominal transaksi harus lebih besar dari 0');
      return;
    }

    if (_type == TransactionType.deposit && _proofImagePath == null) {
      NeoDialog.showNeoSnackbar(context, message: 'Wajib melampirkan bukti foto untuk transaksi deposit!');
      return;
    }

    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);

    double balanceExcludingTx = goal.currentAmount;
    if (widget.existingTransaction != null) {
      final oldTx = widget.existingTransaction!;
      if (oldTx.type == TransactionType.deposit) {
        balanceExcludingTx -= oldTx.amount;
      } else {
        balanceExcludingTx += oldTx.amount;
      }
    }

    if (_type == TransactionType.withdrawal) {
      if (_amount > balanceExcludingTx) {
        NeoDialog.showNeoSnackbar(
          context,
          message: 'Nominal penarikan melebihi saldo tabungan saat ini (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balanceExcludingTx)})',
        );
        return;
      }
    }

    if (widget.existingTransaction == null) {
      final newTx = Transaction(
        id: const Uuid().v4(),
        amount: _amount,
        date: _date,
        note: _note.trim().isEmpty ? (_type == TransactionType.deposit ? 'Setoran' : 'Penarikan') : _note,
        type: _type,
        proofImagePath: _proofImagePath,
      );
      final milestone = provider.addTransaction(widget.goalId, newTx);
      if (milestone != null) {
        _showMilestoneCelebration(context, milestone, 'Transaksi berhasil dicatat!');
      } else {
        Navigator.pop(context);
        NeoDialog.showNeoSnackbar(context, message: 'Transaksi berhasil dicatat!');
      }
    } else {
      final updatedTx = Transaction(
        id: widget.existingTransaction!.id,
        amount: _amount,
        date: _date,
        note: _note.trim().isEmpty ? (_type == TransactionType.deposit ? 'Setoran' : 'Penarikan') : _note,
        type: _type,
        proofImagePath: _proofImagePath,
      );
      final milestone = provider.updateTransaction(widget.goalId, updatedTx);
      if (milestone != null) {
        _showMilestoneCelebration(context, milestone, 'Transaksi berhasil diubah!');
      } else {
        Navigator.pop(context);
        NeoDialog.showNeoSnackbar(context, message: 'Transaksi berhasil diubah!');
      }
    }
  }

  void _showMilestoneCelebration(BuildContext context, double percentage, String successMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => MilestoneCelebrationDialog(
        percentage: percentage,
        onDismiss: () {
          Navigator.pop(dialogCtx);
          Navigator.pop(context);
          NeoDialog.showNeoSnackbar(context, message: successMessage);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existingTransaction != null;
    final DateFormat df = DateFormat('dd MMMM yyyy', 'id_ID');

    final provider = Provider.of<SavingsProvider>(context);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? Colors.white30 : Colors.black38;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          isEdit ? 'Edit Transaksi' : 'Catat Transaksi',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            color: borderColor,
            height: 2.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jenis Transaksi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = TransactionType.deposit;
                          });
                        },
                        child: Container(
                          height: 50,
                          color: _type == TransactionType.deposit
                              ? const Color(0xFF00C49A)
                              : cardBgColor,
                          child: Center(
                            child: Text(
                              'DEPOSIT (MASUK)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _type == TransactionType.deposit ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 2.5, height: 50, color: borderColor),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = TransactionType.withdrawal;
                          });
                        },
                        child: Container(
                          height: 50,
                          color: _type == TransactionType.withdrawal
                              ? const Color(0xFFFF5733)
                              : cardBgColor,
                          child: Center(
                            child: Text(
                              'TARIK (KELUAR)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _type == TransactionType.withdrawal ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Nominal (Rp)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Masukkan nominal transaksi';
                    }
                    return null;
                  },
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textColor),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  NeoButton(
                    text: '+100rb',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: cardBgColor,
                    textColor: textColor,
                    onPressed: () => _addQuickAmount(100000),
                  ),
                  NeoButton(
                    text: '+500rb',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: cardBgColor,
                    textColor: textColor,
                    onPressed: () => _addQuickAmount(500000),
                  ),
                  NeoButton(
                    text: '+1jt',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: cardBgColor,
                    textColor: textColor,
                    onPressed: () => _addQuickAmount(1000000),
                  ),
                  NeoButton(
                    text: '+5jt',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: cardBgColor,
                    textColor: textColor,
                    onPressed: () => _addQuickAmount(5000000),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Tanggal Transaksi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    border: Border.all(color: borderColor, width: 2.5),
                    boxShadow: [BoxShadow(color: borderColor, offset: const Offset(2, 2))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        df.format(_date),
                        style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Icon(Icons.calendar_today, color: textColor),
                    ],
                  ),
                ),
              ),
              if (_type == TransactionType.deposit) ...[
                const SizedBox(height: 20),
                Text(
                  'Bukti Foto Nabung (Wajib)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      border: Border.all(color: borderColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor,
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: _proofImagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: textColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ambil Foto atau Pilih dari Galeri',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? Image.network(
                                      _proofImagePath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_proofImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _proofImagePath = null;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5733),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(color: borderColor, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              Text(
                'Keterangan (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Catatan kecil, misal: Gajian, Bonus, dsb.',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              NeoButton(
                text: isEdit ? 'Simpan Transaksi' : 'Catat Transaksi Baru',
                color: const Color(0xFFFFE500),
                textColor: const Color(0xFF111111),
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  int type; // 0: square, 1: circle, 2: triangle

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.15; // gravity
    vx *= 0.98; // drag
    rotation += rotationSpeed;
  }
}

class MilestoneCelebrationDialog extends StatefulWidget {
  final double percentage;
  final VoidCallback onDismiss;

  const MilestoneCelebrationDialog({
    super.key,
    required this.percentage,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebrationDialog> createState() => _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        if (!mounted) return;
        setState(() {
          for (var p in _particles) {
            p.update();
            if (p.y > MediaQuery.of(context).size.height) {
              p.y = -20;
              p.x = _random.nextDouble() * MediaQuery.of(context).size.width;
              p.vy = _random.nextDouble() * 5 + 2;
            }
          }
        });
      });
    _animationController.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final double width = MediaQuery.of(context).size.width;
      final colors = [
        const Color(0xFFFFE500),
        const Color(0xFFFF5733),
        const Color(0xFF00C49A),
        const Color(0xFF4361EE),
        const Color(0xFFFF007F),
      ];
      for (int i = 0; i < 50; i++) {
        _particles.add(
          ConfettiParticle(
            x: _random.nextDouble() * width,
            y: _random.nextDouble() * -200 - 20,
            vx: _random.nextDouble() * 6 - 3,
            vy: _random.nextDouble() * 5 + 3,
            size: _random.nextDouble() * 8 + 8,
            color: colors[_random.nextInt(colors.length)],
            rotation: _random.nextDouble() * pi,
            rotationSpeed: _random.nextDouble() * 0.1 - 0.05,
            type: _random.nextInt(3),
          ),
        );
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.percentage >= 100.0;
    
    return Material(
      color: Colors.black.withAlpha(178),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(particles: _particles),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: NeoCard(
                color: isFinished ? const Color(0xFF00C49A) : const Color(0xFFFFE500),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isFinished ? '🏆 TARGET TERCAPAI!' : '🎉 SETENGAH JALAN!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFinished
                          ? 'Selamat! Tabungan lu udah kekumpul 100%. Perjuangan lu membuahkan hasil, sekarang saatnya beli barang impian lu! 🥳'
                          : 'Mantap! Tabungan lu udah keisi ${widget.percentage.toInt()}%. Tetap konsisten ya, dikit lagi target lu tercapai! 💪',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF111111), width: 3),
                        ),
                        child: Text(
                          isFinished ? '👑' : '⭐',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    NeoButton(
                      text: isFinished ? 'Sip, Selesai! 🏁' : 'Lanjut Nabung! 🚀',
                      color: const Color(0xFF111111),
                      textColor: Colors.white,
                      onPressed: widget.onDismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.type == 0) {
        // Square
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
      } else if (p.type == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Triangle
        final path = Path()
          ..moveTo(0, -p.size / 2)
          ..lineTo(p.size / 2, p.size / 2)
          ..lineTo(-p.size / 2, p.size / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
