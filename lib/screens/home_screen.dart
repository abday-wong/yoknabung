import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/progress_bar_widget.dart';
import '../widgets/realtime_clock_widget.dart';
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'add_edit_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  String _timeStr = '';

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
          color: const Color(0xFF4361EE), // blue
          icon: Icons.edit,
          onPressed: () {
            Navigator.pop(context); // close bottom sheet
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
          color: const Color(0xFFFF5733), // red-orange
          icon: Icons.delete,
          onPressed: () {
            Navigator.pop(context); // close bottom sheet
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
        Navigator.pop(context); // close dialog
        NeoDialog.showNeoSnackbar(context, message: 'Goal "${goal.title}" telah dihapus');
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7), // warm cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDE7),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'YOKNABUNG',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 22,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _timeStr,
                  style: const TextStyle(
                    color: Color(0xFF111111),
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111111)),
              ),
            );
          }

          final goals = provider.goals;

          // Compute summary row data
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
                // Real-time Clock Card
                const RealtimeClockWidget(),
                const SizedBox(height: 20),

                // Summary Card Row
                NeoCard(
                  color: const Color(0xFF4361EE).withOpacity(0.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL GOAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${goals.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2.5,
                        height: 40,
                        color: const Color(0xFF111111),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL TERKUMPUL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(totalSaved),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00C49A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2.5,
                        height: 40,
                        color: const Color(0xFF111111),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'SISA TARGET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(totalRemaining),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF5733),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Tabungan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
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

                // Goals List / Empty State
                if (goals.isEmpty)
                  NeoCard(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Belum ada tabungan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
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
                          color: isGoalCompleted ? const Color(0xFF00C49A).withOpacity(0.1) : Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Emoji Bubble
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE500),
                                      border: Border.all(color: const Color(0xFF111111), width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        goal.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title and Category
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111111),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4361EE).withOpacity(0.1),
                                            border: Border.all(color: const Color(0xFF111111), width: 1.5),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            _getCategoryIndonesian(goal.category),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF111111),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quick Deposit FAB-style button
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
                              // Amount values row
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Progress Bar Custom Widget
                              ProgressBarWidget(
                                percentage: percentage,
                                fillColor: isGoalCompleted ? const Color(0xFF00C49A) : const Color(0xFFFFE500),
                              ),
                              const SizedBox(height: 8),
                              // Percentage and remaining days row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(0)}% Selesai',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  Text(
                                    isGoalCompleted ? 'Goal Tercapai! 🎉' : '$daysRemaining hari lagi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isGoalCompleted
                                          ? const Color(0xFF00C49A)
                                          : (daysRemaining < 30 ? const Color(0xFFFF5733) : const Color(0xFF111111)),
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
        },
      ),
    );
  }
}
