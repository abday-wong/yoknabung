import 'dart:io';
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
      provider.addTransaction(widget.goalId, newTx);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Transaksi berhasil dicatat!');
    } else {
      final updatedTx = Transaction(
        id: widget.existingTransaction!.id,
        amount: _amount,
        date: _date,
        note: _note.trim().isEmpty ? (_type == TransactionType.deposit ? 'Setoran' : 'Penarikan') : _note,
        type: _type,
        proofImagePath: _proofImagePath,
      );
      provider.updateTransaction(widget.goalId, updatedTx);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Transaksi berhasil diubah!');
    }
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
