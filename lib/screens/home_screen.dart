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
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'add_edit_transaction_screen.dart';

class GlobalTransaction {
  final Transaction transaction;
  final SavingGoal goal;

  GlobalTransaction({required this.transaction, required this.goal});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  String _timeStr = '';
  int _currentIndex = 0; // 0 = Goals, 1 = History

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

          if (_currentIndex == 0) {
            return _buildGoalsView(context, provider, currencyFormatter);
          } else {
            return _buildHistoryView(context, provider, currencyFormatter);
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFF111111), width: 2.5),
          ),
        ),
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 0),
                child: Container(
                  color: _currentIndex == 0 ? const Color(0xFFFFE500) : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.track_changes,
                        color: const Color(0xFF111111),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Goal Saya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 2.5, color: const Color(0xFF111111)),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  color: _currentIndex == 1 ? const Color(0xFFFFE500) : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: const Color(0xFF111111),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Histori Tabungan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
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
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  color: const Color(0xFFFFE500), // Yellow
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
                  color: const Color(0xFF00C49A), // Green
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
                  color: const Color(0xFFFF5733), // Red-orange
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
                                  fontSize: 12),
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
  }

  Widget _buildHistoryView(BuildContext context, SavingsProvider provider, NumberFormat currencyFormatter) {
    final DateFormat dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    // Aggregate all transactions
    final List<GlobalTransaction> allTxs = [];
    for (var goal in provider.goals) {
      for (var tx in goal.transactions) {
        allTxs.add(GlobalTransaction(transaction: tx, goal: goal));
      }
    }

    // Sort by date in reverse chronological order
    allTxs.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    if (allTxs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: NeoCard(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_toggle_off,
                  size: 48,
                  color: Colors.black38,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada riwayat menabung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Setiap setoran atau penarikan yang Anda lakukan pada goal tabungan akan tampil di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
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
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Goal Emoji container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE500),
                    border: Border.all(color: const Color(0xFF111111), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      item.goal.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Note, date, and goal title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note.isEmpty ? (isDeposit ? 'Deposit' : 'Penarikan') : tx.note,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4361EE).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFF111111), width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: Text(
                              item.goal.title,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormatter.format(tx.date),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isDeposit ? "+" : "-"}${currencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDeposit ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
