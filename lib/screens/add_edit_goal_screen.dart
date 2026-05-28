import 'package:flutter/material.dart';
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
    Key? key,
    this.existingGoal,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _amountController = TextEditingController(
      text: goal != null ? goal.targetAmount.toInt().toString() : '',
    );
    _notesController = TextEditingController(text: goal?.notes ?? '');

    _title = goal?.title ?? '';
    _targetAmount = goal?.targetAmount ?? 0.0;
    _category = goal?.category ?? 'gadget';
    _emoji = goal?.emoji ?? '📱';
    _startDate = goal?.startDate ?? DateTime.now();
    _targetDate = goal?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    _notes = goal?.notes;

    // Listen to changes to rebuild live preview
    _titleController.addListener(() {
      setState(() {
        _title = _titleController.text;
      });
    });
    _amountController.addListener(() {
      setState(() {
        _targetAmount = double.tryParse(_amountController.text) ?? 0.0;
      });
    });
    _notesController.addListener(() {
      setState(() {
        _notes = _notesController.text;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
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
        if (isStart) {
          _startDate = picked;
          if (_targetDate.isBefore(_startDate)) {
            _targetDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _targetDate = picked;
        }
      });
    }
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

    if (widget.existingGoal == null) {
      // Create mode
      final goalId = const Uuid().v4();
      final newGoal = SavingGoal(
        id: goalId,
        title: _title,
        emoji: _emoji,
        targetAmount: _targetAmount,
        startDate: _startDate,
        targetDate: _targetDate,
        category: _category,
        milestones: [], // Auto-generated by provider
        transactions: [],
        notes: _notes?.isEmpty == true ? null : _notes,
      );
      provider.addGoal(newGoal);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Goal "$_title" berhasil dibuat!');
    } else {
      // Edit mode
      final updatedGoal = widget.existingGoal!.copyWith(
        title: _title,
        emoji: _emoji,
        targetAmount: _targetAmount,
        startDate: _startDate,
        targetDate: _targetDate,
        category: _category,
        notes: _notes?.isEmpty == true ? null : _notes,
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

    // Create a temporary goal for live preview
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
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDE7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        title: Text(
          isEdit ? 'Edit Goal' : 'Tambah Goal Baru',
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            color: const Color(0xFF111111),
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
              // Emoji Selector
              const Text(
                'Pilih Emoji',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              NeoCard(
                color: Colors.white,
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
                          color: isSelected ? const Color(0xFFFFE500) : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF111111),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))]
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

              // Title Field
              const Text(
                'Nama Goal Tabungan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2.5),
                ),
                child: TextFormField(
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama goal tidak boleh kosong';
                    }
                    return null;
                  },
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                  decoration: const InputDecoration(
                    hintText: 'Misal: Laptop Baru, Liburan Bali',
                    hintStyle: TextStyle(color: Colors.black38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector (Chips)
              const Text(
                'Pilih Kategori',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
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
                        color: isSelected ? const Color(0xFF4361EE) : Colors.white,
                        border: Border.all(color: const Color(0xFF111111), width: 2),
                        boxShadow: isSelected
                            ? const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))]
                            : const [BoxShadow(color: Color(0xFF111111), offset: Offset(1, 1))],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        c['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF111111),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Target Amount
              const Text(
                'Target Jumlah Tabungan (Rp)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2.5),
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
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                  decoration: const InputDecoration(
                    hintText: 'Misal: 10000000',
                    hintStyle: TextStyle(color: Colors.black38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dates Selection (Start / Target)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Mulai',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    df.format(_startDate),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
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
                        const Text(
                          'Target Selesai',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    df.format(_targetDate),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
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

              // Notes field
              const Text(
                'Catatan Tambahan (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2.5),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                  decoration: const InputDecoration(
                    hintText: 'Tulis keterangan atau motivasi di sini...',
                    hintStyle: TextStyle(color: Colors.black38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Savings Calculator Live Preview
              const Text(
                'Live Kalkulasi & Proyeksi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 10),
              SavingsCalculatorWidget(goal: previewGoal),
              const SizedBox(height: 32),

              // Save Button
              NeoButton(
                text: isEdit ? 'Simpan Perubahan' : 'Buat Goal Tabungan',
                color: const Color(0xFF00C49A), // green
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
