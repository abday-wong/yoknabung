import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../providers/savings_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/progress_bar_widget.dart';
import '../widgets/roadmap_widget.dart';
import '../widgets/savings_calculator_widget.dart';
import 'add_edit_goal_screen.dart';
import 'add_edit_transaction_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({
    Key? key,
    required this.goalId,
  }) : super(key: key);

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        Navigator.pop(context); // pop detail screen
        NeoDialog.showNeoSnackbar(context, message: 'Goal "${goal.title}" telah dihapus');
      },
    );
  }

  void _showTransactionOptions(BuildContext context, SavingsProvider provider, SavingGoal goal, Transaction tx) {
    NeoDialog.showNeoBottomSheet(
      context: context,
      title: 'Opsi Transaksi',
      children: [
        NeoButton(
          text: 'Edit Transaksi',
          color: const Color(0xFF4361EE),
          icon: Icons.edit,
          onPressed: () {
            Navigator.pop(context); // close bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditTransactionScreen(
                  goalId: goal.id,
                  existingTransaction: tx,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        NeoButton(
          text: 'Hapus Transaksi',
          color: const Color(0xFFFF5733),
          icon: Icons.delete,
          onPressed: () {
            Navigator.pop(context); // close bottom sheet
            _deleteTransactionWithUndo(context, provider, goal.id, tx);
          },
        ),
      ],
    );
  }

  void _deleteTransactionWithUndo(BuildContext context, SavingsProvider provider, String goalId, Transaction tx) {
    final goal = provider.goals.firstWhere((g) => g.id == goalId);
    final originalIndex = goal.transactions.indexWhere((t) => t.id == tx.id);

    provider.deleteTransaction(goalId, tx.id);

    NeoDialog.showNeoSnackbar(
      context,
      message: 'Transaksi dihapus',
      actionLabel: 'Undo',
      onAction: () {
        provider.undoDeleteTransaction(goalId, tx, originalIndex);
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
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    return Consumer<SavingsProvider>(
      builder: (context, provider, child) {
        // Find goal, safety guard if deleted
        final goalIndex = provider.goals.indexWhere((g) => g.id == widget.goalId);
        if (goalIndex == -1) {
          return const Scaffold(
            body: Center(
              child: Text('Goal tidak ditemukan'),
            ),
          );
        }

        final goal = provider.goals[goalIndex];
        final currentVal = provider.getCurrentAmount(goal);
        final percentage = provider.getCompletionPercentage(goal);
        final daysRemaining = provider.getDaysRemaining(goal);
        final isGoalCompleted = percentage >= 100.0;
        final motivationalMsg = provider.getMotivationalMessage(goal);

        DateTime? projectedDate = provider.getProjectedCompletion(goal);
        String projectionStr = '-';
        if (projectedDate != null) {
          projectionStr = dateFormatter.format(projectedDate);
        } else {
          projectionStr = 'Nabung dulu untuk melihat proyeksi!';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFFDE7),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFDE7),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF111111)),
            title: Text(
              goal.title,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF111111),
              unselectedLabelColor: Colors.black54,
              indicatorColor: const Color(0xFF111111),
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(text: 'Ringkasan'),
                Tab(text: 'Transaksi'),
                Tab(text: 'Grafik'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF111111)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditGoalScreen(existingGoal: goal),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF111111)),
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDeleteGoal(context, provider, goal);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus Goal',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5733)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // --- TAB 1: OVERVIEW & ROADMAP ---
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overview header card
                    NeoCard(
                      color: isGoalCompleted ? const Color(0xFF00C49A).withOpacity(0.15) : Colors.white,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4361EE).withOpacity(0.15),
                                  border: Border.all(color: const Color(0xFF111111), width: 1.5),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  _getCategoryIndonesian(goal.category),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                isGoalCompleted ? 'Tercapai! 🎉' : '$daysRemaining hari lagi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isGoalCompleted ? const Color(0xFF00C49A) : const Color(0xFF111111),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Custom Circular Progress Display
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF111111), width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF111111),
                                      offset: Offset(4, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    goal.emoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 136,
                                height: 136,
                                child: CircularProgressIndicator(
                                  value: percentage / 100.0,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE500)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            currencyFormatter.format(currentVal),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00C49A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'dari target ${currencyFormatter.format(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ProgressBarWidget(
                            percentage: percentage,
                            fillColor: const Color(0xFFFF5733),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${percentage.toStringAsFixed(1)}% Terkumpul',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          // Motivational message banner
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE500),
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              motivationalMsg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Savings Calculator
                    SavingsCalculatorWidget(goal: goal),
                    const SizedBox(height: 24),

                    // Roadmap Section Title
                    const Text(
                      'Pencapaian Milestones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Roadmap Timeline Widget
                    RoadmapWidget(goal: goal),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // --- TAB 2: TRANSACTIONS LIST ---
              goal.transactions.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 16),
                        NeoButton(
                          text: 'Tambah Tabungan',
                          icon: Icons.add,
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
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: const Color(0xFFFFE500),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SALDO SEKARANG:',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Text(
                                currencyFormatter.format(currentVal),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: const Color(0xFF111111),
                          height: 2,
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: goal.transactions.length,
                            padding: const EdgeInsets.all(16),
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              // Sort reverse chronological
                              final sortedTxs = List<Transaction>.from(goal.transactions)
                                ..sort((a, b) => b.date.compareTo(a.date));
                              final tx = sortedTxs[index];

                              final isDeposit = tx.type == TransactionType.deposit;

                              // Calculate running balance up to this transaction
                              double runningBalance = 0;
                              final chronTxs = List<Transaction>.from(goal.transactions)
                                ..sort((a, b) => a.date.compareTo(b.date));
                              for (var t in chronTxs) {
                                if (t.type == TransactionType.deposit) {
                                  runningBalance += t.amount;
                                } else {
                                  runningBalance -= t.amount;
                                }
                                if (t.id == tx.id) break;
                              }

                              return Dismissible(
                                key: Key(tx.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5733),
                                    border: Border.all(color: const Color(0xFF111111), width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  _deleteTransactionWithUndo(context, provider, goal.id, tx);
                                },
                                child: GestureDetector(
                                  onTap: () => _showTransactionOptions(context, provider, goal, tx),
                                  child: NeoCard(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Type icon bubble
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isDeposit ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                                            border: Border.all(color: const Color(0xFF111111), width: 2),
                                          ),
                                          child: Icon(
                                            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Note & Date
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
                                              const SizedBox(height: 2),
                                              Text(
                                                dateFormatter.format(tx.date),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amount & Running Balance
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isDeposit ? "+" : "-"}${currencyFormatter.format(tx.amount)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: isDeposit ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Saldo: ${currencyFormatter.format(runningBalance)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black45,
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
                          ),
                        ),
                      ],
                    ),

              // --- TAB 3: CHARTS TRAJECTORY ---
              _buildChartsTab(context, goal, currencyFormatter),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFFFE500),
            foregroundColor: const Color(0xFF111111),
            shape: Border.all(color: const Color(0xFF111111), width: 2.5),
            elevation: 4,
            child: const Icon(Icons.add, size: 30),
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
        );
      },
    );
  }

  Widget _buildChartsTab(BuildContext context, SavingGoal goal, NumberFormat currencyFormatter) {
    if (goal.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nabung dulu untuk melihat grafik tabunganmu! 📈',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
          ),
        ),
      );
    }

    // Sort chronologically for computing cumulative sum
    final sortedTxs = List<Transaction>.from(goal.transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // 1. Group Monthly Deposits
    // Let's create a map of "Month Year" -> Sum
    final Map<String, double> monthlySums = {};
    for (var tx in sortedTxs) {
      if (tx.type == TransactionType.deposit) {
        final monthStr = DateFormat('MMM yy', 'id_ID').format(tx.date);
        monthlySums[monthStr] = (monthlySums[monthStr] ?? 0.0) + tx.amount;
      }
    }

    final monthlyKeys = monthlySums.keys.toList();
    final List<BarChartGroupData> barGroups = [];
    double maxMonthlyValue = 1.0;
    for (int i = 0; i < monthlyKeys.length; i++) {
      final val = monthlySums[monthlyKeys[i]]!;
      if (val > maxMonthlyValue) maxMonthlyValue = val;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: const Color(0xFF00C49A),
              width: 18,
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: Color(0xFF111111), width: 2),
            ),
          ],
        ),
      );
    }

    // 2. Cumulative Growth Spots
    final List<FlSpot> cumulativeSpots = [];
    double runningSum = 0;
    // Add start date spot
    cumulativeSpots.add(const FlSpot(0, 0));
    
    for (int i = 0; i < sortedTxs.length; i++) {
      final tx = sortedTxs[i];
      if (tx.type == TransactionType.deposit) {
        runningSum += tx.amount;
      } else {
        runningSum -= tx.amount;
      }
      cumulativeSpots.add(FlSpot((i + 1).toDouble(), runningSum));
    }

    double maxLineVal = goal.targetAmount;
    if (runningSum > maxLineVal) maxLineVal = runningSum;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Monthly Deposits Bar Chart
          const Text(
            'Grafik Setoran Bulanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 8),
          NeoCard(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: SizedBox(
              height: 200,
              child: barGroups.isEmpty
                  ? const Center(child: Text('Belum ada setoran'))
                  : BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFF111111), width: 2.5),
                            left: BorderSide(color: Color(0xFF111111), width: 2.5),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double val, TitleMeta meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < monthlyKeys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      monthlyKeys[idx],
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (double val, TitleMeta meta) {
                                if (val == 0) return const SizedBox();
                                // Simplify text to M / K
                                String label = '';
                                if (val >= 1000000) {
                                  label = '${(val / 1000000).toStringAsFixed(1)}jt';
                                } else {
                                  label = '${(val / 1000).toStringAsFixed(0)}rb';
                                }
                                return Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111111),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Cumulative Line Chart
          const Text(
            'Kurva Pertumbuhan & Target',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 8),
          NeoCard(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxLineVal * 1.1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF111111), width: 2.5),
                      left: BorderSide(color: Color(0xFF111111), width: 2.5),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double val, TitleMeta meta) {
                          final idx = val.toInt();
                          if (idx == 0) return const Text('Mulai', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800));
                          if (idx == cumulativeSpots.length - 1) return const Text('Kini', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800));
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (double val, TitleMeta meta) {
                          if (val == 0) return const SizedBox();
                          String label = '';
                          if (val >= 1000000) {
                            label = '${(val / 1000000).toStringAsFixed(1)}jt';
                          } else {
                            label = '${(val / 1000).toStringAsFixed(0)}rb';
                          }
                          return Text(
                            label,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal.targetAmount,
                        color: const Color(0xFFFF5733),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            color: Color(0xFFFF5733),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          labelResolver: (line) => 'Target',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    // Cumulative growth line
                    LineChartBarData(
                      spots: cumulativeSpots,
                      isCurved: false,
                      color: const Color(0xFF4361EE), // blue
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
