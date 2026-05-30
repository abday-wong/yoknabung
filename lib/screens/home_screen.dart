import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/progress_bar_widget.dart';
import '../widgets/realtime_clock_widget.dart';
import '../widgets/logo_widget.dart';
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'add_edit_transaction_screen.dart';
import 'feedback_screen.dart';

class GlobalTransaction {
  final Transaction transaction;
  final SavingGoal goal;

  GlobalTransaction({required this.transaction, required this.goal});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  String _timeStr = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _showGoalOptions(BuildContext context, SavingsProvider provider, SavingGoal goal) {
    NeoDialog.showNeoBottomSheet(
      context: context,
      title: goal.title,
      children: [
        NeoButton(
          text: 'Edit Tabungan',
          color: const Color(0xFF4361EE),
          icon: Icons.edit,
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditGoalScreen(existingGoal: goal),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        NeoButton(
          text: 'Hapus Goal',
          color: const Color(0xFFFF5733),
          icon: Icons.delete,
          onPressed: () {
            Navigator.pop(context);
            _confirmDeleteGoal(context, provider, goal);
          },
        ),
      ],
    );
  }

  void _confirmDeleteGoal(BuildContext context, SavingsProvider provider, SavingGoal goal) {
    NeoDialog.showNeoDialog(
      context: context,
      title: 'Hapus Goal?',
      body: "Semua data tabungan '${goal.title}' akan dihapus permanen.",
      primaryLabel: 'Ya, Hapus',
      primaryColor: const Color(0xFFFF5733),
      secondaryLabel: 'Batal',
      onPrimaryPressed: () {
        provider.deleteGoal(goal.id);
        Navigator.pop(context);
        NeoDialog.showNeoSnackbar(context, message: 'Goal "${goal.title}" telah dihapus');
      },
    );
  }

  void _showReminderSettingsBottomSheet(BuildContext context, SavingsProvider provider) {
    bool enabled = provider.isReminderEnabled;
    int hour = provider.reminderHour;
    int minute = provider.reminderMinute;
    final TextEditingController messageController = TextEditingController(
      text: provider.reminderMessage,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFDE7),
      elevation: 0,
      shape: Border(
        top: BorderSide(
          color: provider.isDarkMode ? Colors.white : const Color(0xFF111111),
          width: 2.5,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final isDark = provider.isDarkMode;
            final textColor = isDark ? Colors.white : const Color(0xFF111111);
            final borderColor = isDark ? Colors.white : const Color(0xFF111111);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: 20.0 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          color: borderColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pengingat Menabung Harian',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Aktifkan Pengingat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setBottomSheetState(() {
                                enabled = !enabled;
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 34,
                              decoration: BoxDecoration(
                                color: enabled
                                    ? const Color(0xFF00C49A)
                                    : (isDark ? const Color(0xFF2E2E2E) : Colors.white),
                                border: Border.all(color: borderColor, width: 2.5),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 150),
                                    left: enabled ? 28 : 2,
                                    top: 2,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white : const Color(0xFF111111),
                                        border: Border.all(color: borderColor, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: enabled ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !enabled,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Waktu Pengingat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: hour, minute: minute),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: const Color(0xFFFFE500),
                                            onPrimary: const Color(0xFF111111),
                                            surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                            onSurface: textColor,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor: textColor,
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setBottomSheetState(() {
                                      hour = picked.hour;
                                      minute = picked.minute;
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE500),
                                    border: Border.all(color: borderColor, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: borderColor,
                                        offset: const Offset(3, 3),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Color(0xFF111111),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: enabled ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !enabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesan Pengingat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                                  border: Border.all(color: borderColor, width: 2.5),
                                ),
                                child: TextField(
                                  controller: messageController,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kata-kata pengingat menabung...',
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.white30 : Colors.black38,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: NeoButton(
                              text: 'Batal',
                              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                              textColor: textColor,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: NeoButton(
                              text: 'Simpan',
                              color: const Color(0xFFFF5733),
                              textColor: Colors.white,
                              onPressed: () async {
                                final text = messageController.text.trim();
                                final message = text.isEmpty
                                    ? 'Jangan lupa sisihkan uang hari ini untuk mencapai target tabunganmu!'
                                    : text;
                                await provider.updateReminderSettings(enabled, hour, minute, message);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  NeoDialog.showNeoSnackbar(
                                    context,
                                    message: enabled 
                                        ? 'Pengingat harian aktif jam ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
                                        : 'Pengingat harian dimatikan',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryIndonesian(String cat) {
    switch (cat.toLowerCase()) {
      case 'vacation':
        return 'Liburan';
      case 'gadget':
        return 'Gadget';
      case 'emergency':
        return 'Dana Darurat';
      case 'education':
        return 'Pendidikan';
      case 'vehicle':
        return 'Kendaraan';
      case 'property':
        return 'Properti';
      default:
        return 'Lainnya';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoWidget(size: 32, hasBorder: true),
            const SizedBox(width: 8),
            Text(
              'YOKNABUNG',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            color: borderColor,
            height: 2.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.feedback_outlined,
              color: textColor,
            ),
            tooltip: 'Kritik & Saran',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_active_outlined,
              color: textColor,
            ),
            onPressed: () {
              _showReminderSettingsBottomSheet(context, provider);
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nights_stay,
              color: textColor,
            ),
            onPressed: () {
              provider.toggleThemeMode();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border.all(color: borderColor, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _timeStr,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Consumer<SavingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(borderColor),
              ),
            );
          }

          if (_currentIndex == 0) {
            return _buildGoalsView(context, provider, currencyFormatter);
          } else {
            return _buildHistoryView(context, provider, currencyFormatter);
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(color: borderColor, width: 2.5),
          ),
        ),
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 0),
                child: Container(
                  color: _currentIndex == 0
                      ? const Color(0xFFFFE500)
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.track_changes,
                        color: _currentIndex == 0 ? const Color(0xFF111111) : textColor,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Goal Saya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _currentIndex == 0 ? const Color(0xFF111111) : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 2.5, color: borderColor),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  color: _currentIndex == 1
                      ? const Color(0xFFFFE500)
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: _currentIndex == 1 ? const Color(0xFF111111) : textColor,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Histori Tabungan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _currentIndex == 1 ? const Color(0xFF111111) : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsView(BuildContext context, SavingsProvider provider, NumberFormat currencyFormatter) {
    final goals = provider.goals;
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    double totalSaved = 0;
    double totalRemaining = 0;
    for (var g in goals) {
      totalSaved += provider.getCurrentAmount(g);
      double rem = g.targetAmount - provider.getCurrentAmount(g);
      totalRemaining += rem > 0 ? rem : 0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RealtimeClockWidget(),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: NeoCard(
                  color: const Color(0xFFFFE500),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL GOAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${goals.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoCard(
                  color: const Color(0xFF00C49A),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    children: [
                      const Text(
                        'TERKUMPUL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormatter.format(totalSaved),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoCard(
                  color: const Color(0xFFFF5733),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    children: [
                      const Text(
                        'SISA TARGET',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormatter.format(totalRemaining),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Tabungan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (goals.isNotEmpty)
                NeoButton(
                  text: 'Tambah',
                  icon: Icons.add,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditGoalScreen(existingGoal: null),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (goals.isEmpty)
            NeoCard(
              color: cardBgColor,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LogoWidget(size: 80, hasBorder: true),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada tabungan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeoButton(
                    text: 'Buat Goal Pertama',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditGoalScreen(existingGoal: null),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final currentVal = provider.getCurrentAmount(goal);
                final percentage = provider.getCompletionPercentage(goal);
                final daysRemaining = provider.getDaysRemaining(goal);
                final isGoalCompleted = percentage >= 100.0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailScreen(goalId: goal.id),
                      ),
                    );
                  },
                  onLongPress: () => _showGoalOptions(context, provider, goal),
                  child: NeoCard(
                    color: isGoalCompleted
                        ? const Color(0xFF00C49A).withValues(alpha: isDark ? 0.25 : 0.1)
                        : cardBgColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE500),
                                border: Border.all(color: borderColor, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  goal.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4361EE).withValues(alpha: 0.15),
                                      border: Border.all(color: borderColor, width: 1.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text(
                                      _getCategoryIndonesian(goal.category),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            NeoButton(
                              color: const Color(0xFFFFE500),
                              padding: const EdgeInsets.all(8),
                              icon: Icons.add_card,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditTransactionScreen(
                                      goalId: goal.id,
                                      existingTransaction: null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormatter.format(currentVal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00C49A),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'dari ${currencyFormatter.format(goal.targetAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ProgressBarWidget(
                          percentage: percentage,
                          fillColor: isGoalCompleted ? const Color(0xFF00C49A) : const Color(0xFFFFE500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(0)}% Selesai',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                            Text(
                              isGoalCompleted ? 'Goal Tercapai! 🎉' : '$daysRemaining hari lagi',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isGoalCompleted
                                    ? const Color(0xFF00C49A)
                                    : (daysRemaining < 30 ? const Color(0xFFFF5733) : textColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(BuildContext context, SavingsProvider provider, NumberFormat currencyFormatter) {
    final DateFormat dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final iconMutedColor = isDark ? Colors.white38 : Colors.black38;

    final List<GlobalTransaction> allTxs = [];
    for (var goal in provider.goals) {
      for (var tx in goal.transactions) {
        allTxs.add(GlobalTransaction(transaction: tx, goal: goal));
      }
    }

    allTxs.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    if (allTxs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: NeoCard(
            color: cardBgColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 48,
                  color: iconMutedColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat menabung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setiap setoran atau penarikan yang Anda lakukan pada goal tabungan akan tampil di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: allTxs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = allTxs[index];
        final tx = item.transaction;
        final isDeposit = tx.type == TransactionType.deposit;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailScreen(goalId: item.goal.id),
              ),
            );
          },
          child: NeoCard(
            color: cardBgColor,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE500),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      item.goal.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note.isEmpty ? (isDeposit ? 'Deposit' : 'Penarikan') : tx.note,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4361EE).withValues(alpha: 0.15),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: Text(
                              item.goal.title,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormatter.format(tx.date),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${isDeposit ? "+" : "-"}${currencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDeposit ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: subtextColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
