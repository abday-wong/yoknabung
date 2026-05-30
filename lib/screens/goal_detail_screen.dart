import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'full_screen_image_viewer.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

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
        Navigator.pop(context);
        Navigator.pop(context);
        NeoDialog.showNeoSnackbar(context, message: 'Goal "${goal.title}" telah dihapus');
      },
    );
  }

  void _showTransactionOptions(BuildContext context, SavingsProvider provider, SavingGoal goal, Transaction tx) {
    final bool hasProof = tx.proofImagePath != null;
    NeoDialog.showNeoBottomSheet(
      context: context,
      title: 'Opsi Transaksi',
      children: [
        if (hasProof) ...[
          NeoButton(
            text: 'Lihat Bukti Foto',
            color: const Color(0xFF00C49A),
            icon: Icons.image,
            onPressed: () {
              Navigator.pop(context);
              _showProofImageDialog(context, tx);
            },
          ),
          const SizedBox(height: 12),
        ],
        NeoButton(
          text: 'Edit Transaksi',
          color: const Color(0xFF4361EE),
          icon: Icons.edit,
          onPressed: () {
            Navigator.pop(context);
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
            Navigator.pop(context);
            _deleteTransactionWithUndo(context, provider, goal.id, tx);
          },
        ),
      ],
    );
  }

  void _showProofImageDialog(BuildContext context, Transaction tx) {
    final String path = tx.proofImagePath!;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final provider = Provider.of<SavingsProvider>(context, listen: false);
        final isDark = provider.isDarkMode;
        final textColor = isDark ? Colors.white : const Color(0xFF111111);
        final borderColor = isDark ? Colors.white : const Color(0xFF111111);
        final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bukti Foto Nabung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: textColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imagePath: path,
                          title: 'Bukti Deposit: ${tx.note.isEmpty ? "Deposit" : tx.note}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            child: kIsWeb
                                ? Image.network(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Center(child: Icon(Icons.broken_image, size: 40, color: textColor)),
                                  )
                                : Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Center(child: Icon(Icons.broken_image, size: 40, color: textColor)),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE500),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fullscreen, size: 14, color: Color(0xFF111111)),
                                const SizedBox(width: 4),
                                const Text(
                                  'Lihat Penuh',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NeoButton(
                  text: 'Tutup',
                  color: const Color(0xFFFFE500),
                  textColor: const Color(0xFF111111),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
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

        final isDark = provider.isDarkMode;
        final textColor = isDark ? Colors.white : const Color(0xFF111111);
        final borderColor = isDark ? Colors.white : const Color(0xFF111111);
        final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final subtextColor = isDark ? Colors.white70 : Colors.black54;
        final subtextColorMuted = isDark ? Colors.white30 : Colors.black45;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Text(
              goal.title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: textColor,
              unselectedLabelColor: subtextColor,
              indicatorColor: textColor,
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
                icon: Icon(Icons.edit, color: textColor),
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
                icon: Icon(Icons.more_vert, color: textColor),
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeoCard(
                      color: isGoalCompleted
                          ? const Color(0xFF00C49A).withValues(alpha: isDark ? 0.25 : 0.15)
                          : cardBgColor,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4361EE).withValues(alpha: 0.15),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  _getCategoryIndonesian(goal.category),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Text(
                                isGoalCompleted ? 'Tercapai! 🎉' : '$daysRemaining hari lagi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isGoalCompleted ? const Color(0xFF00C49A) : textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: borderColor,
                                      offset: const Offset(4, 4),
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE500),
                              border: Border.all(color: borderColor, width: 2),
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

                    SavingsCalculatorWidget(goal: goal),
                     const SizedBox(height: 24),

                    if (goal.imageUrl != null || goal.targetUrl != null) ...[
                      Text(
                        'Target Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeoCard(
                        color: cardBgColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (goal.imageUrl != null) ...[
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImageViewer(
                                        imagePath: goal.imageUrl!,
                                        title: 'Foto Target: ${goal.title}',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: borderColor,
                                        offset: const Offset(3, 3),
                                      )
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          child: kIsWeb
                                              ? Image.network(
                                                  goal.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.broken_image, size: 40, color: textColor),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Gagal memuat gambar target',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w800,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  File(goal.imageUrl!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.broken_image, size: 40, color: textColor),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Gagal memuat gambar target',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w800,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFE500),
                                            border: Border.all(color: borderColor, width: 1.5),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.fullscreen, size: 14, color: Color(0xFF111111)),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Lihat Penuh',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF111111),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (goal.targetUrl != null) ...[
                              Text(
                                'Tautan Referensi Barang:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                goal.targetUrl!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(height: 14),
                              NeoButton(
                                text: 'Buka Link Target',
                                color: const Color(0xFFFFE500),
                                icon: Icons.open_in_new,
                                onPressed: () async {
                                  try {
                                    final Uri uri = Uri.parse(goal.targetUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        NeoDialog.showNeoSnackbar(
                                          context,
                                          message: 'Tidak dapat membuka tautan target',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      NeoDialog.showNeoSnackbar(
                                        context,
                                        message: 'Link tidak valid: $e',
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Pencapaian Milestones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    RoadmapWidget(goal: goal),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              goal.transactions.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
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
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111111)),
                              ),
                              Text(
                                currencyFormatter.format(currentVal),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111111)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: borderColor,
                          height: 2,
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: goal.transactions.length,
                            padding: const EdgeInsets.all(16),
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final sortedTxs = List<Transaction>.from(goal.transactions)
                                ..sort((a, b) => b.date.compareTo(a.date));
                              final tx = sortedTxs[index];

                              final isDeposit = tx.type == TransactionType.deposit;

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
                                    border: Border.all(color: borderColor, width: 2),
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
                                    color: cardBgColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isDeposit ? const Color(0xFF00C49A) : const Color(0xFFFF5733),
                                            border: Border.all(color: borderColor, width: 2),
                                          ),
                                          child: Icon(
                                            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      tx.note.isEmpty ? (isDeposit ? 'Deposit' : 'Penarikan') : tx.note,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  if (tx.proofImagePath != null) ...[
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      Icons.image,
                                                      size: 14,
                                                      color: isDark ? const Color(0xFF00C49A) : const Color(0xFF4361EE),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                dateFormatter.format(tx.date),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: subtextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: subtextColorMuted,
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

              _buildChartsTab(context, goal, currencyFormatter),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFFFE500),
            foregroundColor: const Color(0xFF111111),
            shape: Border.all(color: borderColor, width: 2.5),
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
    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (goal.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Nabung dulu untuk melihat grafik tabunganmu! 📈',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
          ),
        ),
      );
    }

    final sortedTxs = List<Transaction>.from(goal.transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

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
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ],
        ),
      );
    }

    final List<FlSpot> cumulativeSpots = [];
    double runningSum = 0;
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
          Text(
            'Grafik Setoran Bulanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 8),
          NeoCard(
            color: cardBgColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: SizedBox(
              height: 200,
              child: barGroups.isEmpty
                  ? Center(child: Text('Belum ada setoran', style: TextStyle(color: textColor)))
                  : BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(
                          border: Border(
                            bottom: BorderSide(color: borderColor, width: 2.5),
                            left: BorderSide(color: borderColor, width: 2.5),
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
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
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
                                String label = '';
                                if (val >= 1000000) {
                                  label = '${(val / 1000000).toStringAsFixed(1)}jt';
                                } else {
                                  label = '${(val / 1000).toStringAsFixed(0)}rb';
                                }
                                return Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
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

          Text(
            'Kurva Pertumbuhan & Target',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 8),
          NeoCard(
            color: cardBgColor,
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
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 2.5),
                      left: BorderSide(color: borderColor, width: 2.5),
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
                          if (idx == 0) return Text('Mulai', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textColor));
                          if (idx == cumulativeSpots.length - 1) return Text('Kini', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textColor));
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
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: textColor,
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
                    LineChartBarData(
                      spots: cumulativeSpots,
                      isCurved: false,
                      color: const Color(0xFF4361EE),
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
