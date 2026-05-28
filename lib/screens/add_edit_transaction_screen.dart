import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_card.dart';
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
    Key? key,
    required this.goalId,
    this.existingTransaction,
  }) : super(key: key);

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  late double _amount;
  late DateTime _date;
  late String _note;

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;

    _type = tx?.type ?? TransactionType.deposit;
    _amount = tx?.amount ?? 0.0;
    _date = tx?.date ?? DateTime.now();
    _note = tx?.note ?? '';

    // Format amount for display if editing
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

    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);

    // Calculate current amount excluding this transaction if editing
    double balanceExcludingTx = goal.currentAmount;
    if (widget.existingTransaction != null) {
      final oldTx = widget.existingTransaction!;
      if (oldTx.type == TransactionType.deposit) {
        balanceExcludingTx -= oldTx.amount;
      } else {
        balanceExcludingTx += oldTx.amount;
      }
    }

    // Validation for withdrawal limits
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
      // Add Mode
      final newTx = Transaction(
        id: const Uuid().v4(),
        amount: _amount,
        date: _date,
        note: _note.trim().isEmpty ? (_type == TransactionType.deposit ? 'Setoran' : 'Penarikan') : _note,
        type: _type,
      );
      provider.addTransaction(widget.goalId, newTx);
      Navigator.pop(context);
      NeoDialog.showNeoSnackbar(context, message: 'Transaksi berhasil dicatat!');
    } else {
      // Edit Mode
      final updatedTx = Transaction(
        id: widget.existingTransaction!.id,
        amount: _amount,
        date: _date,
        note: _note.trim().isEmpty ? (_type == TransactionType.deposit ? 'Setoran' : 'Penarikan') : _note,
        type: _type,
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDE7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        title: Text(
          isEdit ? 'Edit Transaksi' : 'Catat Transaksi',
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
              // Toggle Deposit / Withdrawal (Neo Brutalist Style)
              const Text(
                'Jenis Transaksi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF111111), width: 2.5),
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
                              ? const Color(0xFF00C49A) // Green
                              : Colors.white,
                          child: Center(
                            child: Text(
                              'DEPOSIT (MASUK)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _type == TransactionType.deposit ? Colors.white : const Color(0xFF111111),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 2.5, height: 50, color: const Color(0xFF111111)),
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
                              ? const Color(0xFFFF5733) // Red-orange
                              : Colors.white,
                          child: Center(
                            child: Text(
                              'TARIK (KELUAR)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _type == TransactionType.withdrawal ? Colors.white : const Color(0xFF111111),
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

              // Amount Field
              const Text(
                'Nominal (Rp)',
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111111)),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.black26),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick injection buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  NeoButton(
                    text: '+100rb',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.white,
                    onPressed: () => _addQuickAmount(100000),
                  ),
                  NeoButton(
                    text: '+500rb',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.white,
                    onPressed: () => _addQuickAmount(500000),
                  ),
                  NeoButton(
                    text: '+1jt',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.white,
                    onPressed: () => _addQuickAmount(1000000),
                  ),
                  NeoButton(
                    text: '+5jt',
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.white,
                    onPressed: () => _addQuickAmount(5000000),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Picker
              const Text(
                'Tanggal Transaksi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF111111), width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        df.format(_date),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111111)),
                      ),
                      const Icon(Icons.calendar_today, color: Color(0xFF111111)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note Field
              const Text(
                'Keterangan (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2.5),
                ),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                  decoration: const InputDecoration(
                    hintText: 'Catatan kecil, misal: Gajian, Bonus, dsb.',
                    hintStyle: TextStyle(color: Colors.black38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              NeoButton(
                text: isEdit ? 'Simpan Transaksi' : 'Catat Transaksi Baru',
                color: const Color(0xFFFFE500),
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
