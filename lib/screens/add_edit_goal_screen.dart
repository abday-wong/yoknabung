import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/savings_calculator_widget.dart';

class AddEditGoalScreen extends StatefulWidget {
  final SavingGoal? existingGoal;

  const AddEditGoalScreen({
    super.key,
    this.existingGoal,
  });

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _title;
  late double _targetAmount;
  late String _category;
  late String _emoji;
  late DateTime _startDate;
  late DateTime _targetDate;
  String? _notes;

  bool _useDailyPrediction = false;
  double _plannedDailySavings = 0.0;
  late TextEditingController _dailySavingsController;

  final List<String> _emojis = ['📱', '🏖️', '🚗', '🎓', '🏠', '💰', '💻', '✈️', '🎁', '🎮', '🍕', '💪'];
  final List<Map<String, String>> _categories = [
    {'value': 'vacation', 'label': 'Liburan'},
    {'value': 'gadget', 'label': 'Gadget'},
    {'value': 'emergency', 'label': 'Dana Darurat'},
    {'value': 'education', 'label': 'Pendidikan'},
    {'value': 'vehicle', 'label': 'Kendaraan'},
    {'value': 'property', 'label': 'Properti'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _targetUrlController;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _amountController = TextEditingController(
      text: goal != null ? goal.targetAmount.toInt().toString() : '',
    );
    _notesController = TextEditingController(text: goal?.notes ?? '');
    _targetUrlController = TextEditingController(text: goal?.targetUrl ?? '');
    _imageUrl = goal?.imageUrl;

    _title = goal?.title ?? '';
    _targetAmount = goal?.targetAmount ?? 0.0;
    _category = goal?.category ?? 'gadget';
    _emoji = goal?.emoji ?? '📱';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = goal != null
        ? DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day)
        : today;
    _targetDate = goal != null
        ? DateTime(goal.targetDate.year, goal.targetDate.month, goal.targetDate.day)
        : today.add(const Duration(days: 30));
    _notes = goal?.notes;

    double initialDailySavings = 0.0;
    if (goal != null) {
      if (goal.plannedDailySavings != null && goal.plannedDailySavings! > 0) {
        initialDailySavings = goal.plannedDailySavings!;
        _useDailyPrediction = true;
      } else {
        final start = DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day);
        final target = DateTime(goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);
        int totalDays = target.difference(start).inDays;
        if (totalDays <= 0) totalDays = 1;
        initialDailySavings = goal.targetAmount / totalDays;
        _useDailyPrediction = false;
      }
    }
    _dailySavingsController = TextEditingController(
      text: initialDailySavings > 0 ? initialDailySavings.toInt().toString() : '',
    );
    _plannedDailySavings = initialDailySavings;

    _titleController.addListener(() {
      setState(() {
        _title = _titleController.text;
      });
    });
    _amountController.addListener(() {
      setState(() {
        _targetAmount = double.tryParse(_amountController.text) ?? 0.0;
        if (_useDailyPrediction) {
          _updatePredictedTargetDate();
        }
      });
    });
    _notesController.addListener(() {
      setState(() {
        _notes = _notesController.text;
      });
    });
    _dailySavingsController.addListener(() {
      setState(() {
        _plannedDailySavings = double.tryParse(_dailySavingsController.text) ?? 0.0;
        if (_useDailyPrediction) {
          _updatePredictedTargetDate();
        }
      });
    });
  }

  void _updatePredictedTargetDate() {
    if (_targetAmount > 0 && _plannedDailySavings > 0) {
      final daysNeeded = (_targetAmount / _plannedDailySavings).ceil();
      if (daysNeeded > 0 && daysNeeded < 365 * 100) {
        final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _targetDate = start.add(Duration(days: daysNeeded));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dailySavingsController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startDate : _targetDate;
    final DateTime firstDate = isStart
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate.add(const Duration(days: 1));
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365 * 10));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF111111),
              onPrimary: Color(0xFFFFFDE7),
              onSurface: Color(0xFF111111),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111111),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final pickedDate = DateTime(picked.year, picked.month, picked.day);
        if (isStart) {
          _startDate = pickedDate;
          if (_useDailyPrediction) {
            _updatePredictedTargetDate();
          } else {
            if (_targetDate.isBefore(_startDate)) {
              _targetDate = _startDate.add(const Duration(days: 1));
            }
          }
        } else {
          _targetDate = pickedDate;
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (!isMobile) {
        if (mounted) {
          NeoDialog.showNeoSnackbar(
            context,
            message: 'Kamera hanya tersedia pada perangkat mobile (Android/iOS). Silakan gunakan opsi Galeri.',
          );
        }
        return;
      }
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageUrl = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        NeoDialog.showNeoSnackbar(context, message: 'Gagal mengambil gambar: $e');
      }
    }
  }

  void _showImageSourceOptions() {
    NeoDialog.showNeoBottomSheet(
      context: context,
      title: 'Pilih Sumber Foto',
      children: [
        NeoButton(
          text: 'Kamera',
          color: const Color(0xFFFFE500),
          icon: Icons.camera_alt,
          onPressed: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
        const SizedBox(height: 12),
        NeoButton(
          text: 'Galeri',
          color: const Color(0xFF00C49A),
          icon: Icons.photo_library,
          onPressed: () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    if (_targetAmount <= 0) {
      NeoDialog.showNeoSnackbar(context, message: 'Target jumlah tabungan harus lebih dari 0');
      return;
    }

    if (!_targetDate.isAfter(_startDate)) {
      NeoDialog.showNeoSnackbar(context, message: 'Tanggal target harus setelah tanggal mulai');
      return;
    }

    final provider = Provider.of<SavingsProvider>(context, listen: false);

    final cleanUrl = _targetUrlController.text.trim().isEmpty ? null : _targetUrlController.text.trim();

    if (widget.existingGoal == null) {
      final goalId = const Uuid().v4();
      final newGoal = SavingGoal(
        id: goalId,
        title: _title,
        emoji: _emoji,
        targetAmount: _targetAmount,
        startDate: _startDate,
        targetDate: _targetDate,
        category: _category,
        milestones: [],
        transactions: [],
        notes: _notes?.isEmpty == true ? null : _notes,
        imageUrl: _imageUrl,
        targetUrl: cleanUrl,
        plannedDailySavings: _useDailyPrediction ? _plannedDailySavings : null,
      );
      provider.addGoal(newGoal);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Goal "$_title" berhasil dibuat!');
    } else {
      final updatedGoal = widget.existingGoal!.copyWith(
        title: _title,
        emoji: _emoji,
        targetAmount: _targetAmount,
        startDate: _startDate,
        targetDate: _targetDate,
        category: _category,
        notes: _notes?.isEmpty == true ? null : _notes,
        imageUrl: _imageUrl,
        targetUrl: cleanUrl,
        clearImage: _imageUrl == null,
        clearUrl: cleanUrl == null,
        plannedDailySavings: _useDailyPrediction ? _plannedDailySavings : null,
        clearPlannedDailySavings: !_useDailyPrediction,
      );
      provider.updateGoal(updatedGoal);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Goal "$_title" berhasil diperbarui!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existingGoal != null;
    final DateFormat df = DateFormat('dd MMMM yyyy', 'id_ID');

    final provider = Provider.of<SavingsProvider>(context);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? Colors.white30 : Colors.black38;

    final previewGoal = SavingGoal(
      id: widget.existingGoal?.id ?? 'preview',
      title: _title.isEmpty ? 'Preview Goal' : _title,
      emoji: _emoji,
      targetAmount: _targetAmount <= 0 ? 1.0 : _targetAmount,
      startDate: _startDate,
      targetDate: _targetDate,
      category: _category,
      milestones: [],
      transactions: widget.existingGoal?.transactions ?? [],
      notes: _notes,
      imageUrl: _imageUrl,
      targetUrl: _targetUrlController.text.trim().isEmpty ? null : _targetUrlController.text.trim(),
      plannedDailySavings: _useDailyPrediction ? _plannedDailySavings : null,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          isEdit ? 'Edit Goal' : 'Tambah Goal Baru',
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
                'Pilih Emoji',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              NeoCard(
                color: cardBgColor,
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: _emojis.map((e) {
                    final isSelected = _emoji == e;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _emoji = e;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFE500) : cardBgColor,
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: borderColor, offset: const Offset(2, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Nama Goal Tabungan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama goal tidak boleh kosong';
                    }
                    return null;
                  },
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Misal: Laptop Baru, Liburan Bali',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Pilih Kategori',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = _category == c['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _category = c['value']!;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4361EE) : cardBgColor,
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: isSelected
                            ? [BoxShadow(color: borderColor, offset: const Offset(2, 2))]
                            : [BoxShadow(color: borderColor, offset: const Offset(1, 1))],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        c['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text(
                'Target Jumlah Tabungan (Rp)',
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
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Target nominal tidak boleh kosong';
                    }
                    if (double.tryParse(val) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Misal: 10000000',
                    hintStyle: TextStyle(color: Colors.black38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Metode Target Selesai',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _useDailyPrediction = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_useDailyPrediction ? const Color(0xFFFFE500) : cardBgColor,
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: !_useDailyPrediction
                              ? [BoxShadow(color: borderColor, offset: const Offset(2, 2))]
                              : [BoxShadow(color: borderColor, offset: const Offset(1, 1))],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'MANUAL TANGGAL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: !_useDailyPrediction ? const Color(0xFF111111) : textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _useDailyPrediction = true;
                          _updatePredictedTargetDate();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _useDailyPrediction ? const Color(0xFFFFE500) : cardBgColor,
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: _useDailyPrediction
                              ? [BoxShadow(color: borderColor, offset: const Offset(2, 2))]
                              : [BoxShadow(color: borderColor, offset: const Offset(1, 1))],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'PREDIKSI HARIAN',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _useDailyPrediction ? const Color(0xFF111111) : textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_useDailyPrediction) ...[
                Text(
                  'Nominal Tabungan Harian (Rp/hari)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    border: Border.all(color: borderColor, width: 2.5),
                  ),
                  child: TextFormField(
                    controller: _dailySavingsController,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (_useDailyPrediction) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nominal tabungan harian tidak boleh kosong';
                        }
                        if (double.tryParse(val) == null || double.parse(val) <= 0) {
                          return 'Masukkan nominal yang valid (> 0)';
                        }
                      }
                      return null;
                    },
                    style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Misal: 50000',
                      hintStyle: TextStyle(color: hintColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                      errorStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                    ),
                  ),
                ),
                if (widget.existingGoal != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final provider = Provider.of<SavingsProvider>(context, listen: false);
                      final avgDaily = provider.getAverageDailyDeposit(widget.existingGoal!);
                      if (avgDaily > 0) {
                        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _dailySavingsController.text = avgDaily.toInt().toString();
                                _plannedDailySavings = avgDaily;
                                _updatePredictedTargetDate();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C49A).withValues(alpha: 0.15),
                                border: Border.all(color: borderColor, width: 1.5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                '🎯 Gunakan rata-rata riwayat: ${currencyFormatter.format(avgDaily)}/hari',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Mulai',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: [BoxShadow(color: borderColor, offset: const Offset(2, 2))],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    df.format(_startDate),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 16, color: textColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Selesai',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _useDailyPrediction ? null : () => _selectDate(context, false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _useDailyPrediction ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : cardBgColor,
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: _useDailyPrediction
                                  ? null
                                  : [BoxShadow(color: borderColor, offset: const Offset(2, 2))],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    df.format(_targetDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _useDailyPrediction ? (isDark ? Colors.white38 : Colors.black54) : textColor,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _useDailyPrediction ? (isDark ? Colors.white30 : Colors.black38) : textColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Catatan Tambahan (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Tulis keterangan atau motivasi di sini...',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Link Web Target (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: TextFormField(
                  controller: _targetUrlController,
                  keyboardType: TextInputType.url,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Masukkan link referensi barang, misal Tokopedia, Shopee...',
                    hintStyle: TextStyle(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Foto Target (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              _imageUrl == null
                  ? GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          border: Border.all(color: borderColor, width: 2.5),
                          boxShadow: [BoxShadow(color: borderColor, offset: const Offset(3, 3))],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 36, color: textColor),
                            const SizedBox(height: 8),
                            Text(
                              'Ambil atau Pilih Foto Target',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            border: Border.all(color: borderColor, width: 2.5),
                            boxShadow: [BoxShadow(color: borderColor, offset: const Offset(4, 4))],
                          ),
                          child: ClipRRect(
                            child: Image.file(
                              File(_imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                text: 'Ganti Foto',
                                color: const Color(0xFFFFE500),
                                icon: Icons.edit,
                                onPressed: _showImageSourceOptions,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NeoButton(
                                text: 'Hapus Foto',
                                color: const Color(0xFFFF5733),
                                icon: Icons.delete_forever,
                                onPressed: () {
                                  setState(() {
                                    _imageUrl = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 28),

              Text(
                'Live Kalkulasi & Proyeksi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 10),
              SavingsCalculatorWidget(goal: previewGoal),
              const SizedBox(height: 32),

              NeoButton(
                text: isEdit ? 'Simpan Perubahan' : 'Buat Goal Tabungan',
                color: const Color(0xFF00C49A),
                onPressed: _saveGoal,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
