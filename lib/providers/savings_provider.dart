import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/milestone.dart';
import '../services/notification_service.dart';

class SavingsProvider with ChangeNotifier {
  List<SavingGoal> _goals = [];
  bool _isLoading = true;
  final Uuid _uuid = const Uuid();
  bool _isDarkMode = false;
  bool _isReminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  String _reminderMessage = 'Jangan lupa sisihkan uang hari ini untuk mencapai target tabunganmu!';

  List<SavingGoal> get goals => _goals;
  bool get isLoading => _isLoading;
    bool get isDarkMode => _isDarkMode;
    bool get isReminderEnabled => _isReminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  String get reminderMessage => _reminderMessage;

  SavingsProvider() {
    loadFromPrefs();
  }

  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }


  void addGoal(SavingGoal goal) {
    final milestones = _generateMilestones(goal.id, goal.targetAmount);
    final newGoal = goal.copyWith(milestones: milestones);
    _goals.add(newGoal);
    checkAndUpdateMilestones(newGoal);
    saveToPrefs();
    notifyListeners();
  }

  void updateGoal(SavingGoal updatedGoal) {
    final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
    if (index != -1) {
      final newMilestones = recalculateMilestones(updatedGoal);
      final finalGoal = updatedGoal.copyWith(milestones: newMilestones);
      _goals[index] = finalGoal;
      checkAndUpdateMilestones(finalGoal);
      saveToPrefs();
      notifyListeners();
    }
  }

  void deleteGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
    saveToPrefs();
    notifyListeners();
  }

  int getGlobalStreak() {
    final List<Transaction> allDeposits = [];
    for (var goal in _goals) {
      allDeposits.addAll(
        goal.transactions.where((t) => t.type == TransactionType.deposit),
      );
    }
    if (allDeposits.isEmpty) return 0;

    final Set<DateTime> uniqueDates = allDeposits
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!uniqueDates.contains(today) && !uniqueDates.contains(yesterday)) {
      return 0;
    }

    DateTime currentCheckDate = uniqueDates.contains(today) ? today : yesterday;
    int streak = 0;

    while (uniqueDates.contains(currentCheckDate)) {
      streak++;
      currentCheckDate = currentCheckDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  double getGlobalExp() {
    return _goals.fold(0.0, (sum, goal) {
      final depositSum = goal.transactions
          .where((t) => t.type == TransactionType.deposit)
          .fold(0.0, (txSum, tx) => txSum + tx.amount);
      return sum + depositSum;
    });
  }

  int getGlobalLevel() {
    final double exp = getGlobalExp();
    if (exp < 50000) return 1;
    if (exp < 200000) return 2;
    if (exp < 1000000) return 3;
    if (exp < 5000000) return 4;
    return 5;
  }

  double getMinExpForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 50000;
    if (level == 3) return 200000;
    if (level == 4) return 1000000;
    return 5000000;
  }

  double getMaxExpForLevel(int level) {
    if (level <= 1) return 50000;
    if (level == 2) return 200000;
    if (level == 3) return 1000000;
    if (level == 4) return 5000000;
    return 5000000;
  }

  String getLevelTitle(int level) {
    if (level <= 1) return "cupu luwh";
    if (level == 2) return "bole laa";
    if (level == 3) return "kelas kink";
    if (level == 4) return "njir banyak duid";
    return "dah mentok kink";
  }

  double? addTransaction(String goalId, Transaction tx) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final previousMilestones = goal.milestones.map((m) => m.isReached).toList();

      final updatedTxList = List<Transaction>.from(goal.transactions)..add(tx);
      final updatedGoal = goal.copyWith(transactions: updatedTxList);
      _goals[index] = updatedGoal;
      checkAndUpdateMilestones(updatedGoal);
      saveToPrefs();
      notifyListeners();

      double? highestNewlyReached;
      final newGoal = _goals[index];
      for (int i = 0; i < newGoal.milestones.length; i++) {
        final wasReached = previousMilestones[i];
        final isReached = newGoal.milestones[i].isReached;
        if (isReached && !wasReached) {
          if (highestNewlyReached == null || newGoal.milestones[i].percentage > highestNewlyReached) {
            highestNewlyReached = newGoal.milestones[i].percentage;
          }
        }
      }
      return highestNewlyReached;
    }
    return null;
  }

  double? updateTransaction(String goalId, Transaction updatedTx) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final previousMilestones = goal.milestones.map((m) => m.isReached).toList();

      final txIndex = goal.transactions.indexWhere((t) => t.id == updatedTx.id);
      if (txIndex != -1) {
        final updatedTxList = List<Transaction>.from(goal.transactions);
        updatedTxList[txIndex] = updatedTx;
        final updatedGoal = goal.copyWith(transactions: updatedTxList);
        _goals[index] = updatedGoal;
        checkAndUpdateMilestones(updatedGoal);
        saveToPrefs();
        notifyListeners();

        double? highestNewlyReached;
        final newGoal = _goals[index];
        for (int i = 0; i < newGoal.milestones.length; i++) {
          final wasReached = previousMilestones[i];
          final isReached = newGoal.milestones[i].isReached;
          if (isReached && !wasReached) {
            if (highestNewlyReached == null || newGoal.milestones[i].percentage > highestNewlyReached) {
              highestNewlyReached = newGoal.milestones[i].percentage;
            }
          }
        }
        return highestNewlyReached;
      }
    }
    return null;
  }

  void deleteTransaction(String goalId, String txId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final updatedTxList = List<Transaction>.from(goal.transactions)
        ..removeWhere((t) => t.id == txId);
      final updatedGoal = goal.copyWith(transactions: updatedTxList);
      _goals[index] = updatedGoal;
      checkAndUpdateMilestones(updatedGoal);
      saveToPrefs();
      notifyListeners();
    }
  }

  void undoDeleteTransaction(String goalId, Transaction tx, int originalIndex) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final updatedTxList = List<Transaction>.from(goal.transactions);
      if (originalIndex >= 0 && originalIndex <= updatedTxList.length) {
        updatedTxList.insert(originalIndex, tx);
      } else {
        updatedTxList.add(tx);
      }
      final updatedGoal = goal.copyWith(transactions: updatedTxList);
      _goals[index] = updatedGoal;
      checkAndUpdateMilestones(updatedGoal);
      saveToPrefs();
      notifyListeners();
    }
  }


  double getCurrentAmount(SavingGoal goal) {
    return goal.currentAmount;
  }

  double getCompletionPercentage(SavingGoal goal) {
    if (goal.targetAmount <= 0) return 0.0;
    final percentage = (goal.currentAmount / goal.targetAmount) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  int getDaysRemaining(SavingGoal goal) {
    final today = _normalizeDate(DateTime.now());
    final target = _normalizeDate(goal.targetDate);
    final diff = target.difference(today).inDays;
    return max(0, diff);
  }

  double getDailyTarget(SavingGoal goal) {
    final start = _normalizeDate(goal.startDate);
    final target = _normalizeDate(goal.targetDate);
    int totalDays = target.difference(start).inDays;
    if (totalDays <= 0) totalDays = 1;
    return goal.targetAmount / totalDays;
  }

  double getWeeklyTarget(SavingGoal goal) {
    final start = _normalizeDate(goal.startDate);
    final target = _normalizeDate(goal.targetDate);
    int totalDays = target.difference(start).inDays;
    if (totalDays <= 0) totalDays = 1;
    double totalWeeks = totalDays / 7.0;
    if (totalWeeks < 0.1) totalWeeks = 0.1;
    return goal.targetAmount / totalWeeks;
  }

  double getMonthlyTarget(SavingGoal goal) {
    final start = _normalizeDate(goal.startDate);
    final target = _normalizeDate(goal.targetDate);
    int totalDays = target.difference(start).inDays;
    if (totalDays <= 0) totalDays = 1;
    double totalMonths = totalDays / 30.0;
    if (totalMonths < 0.1) totalMonths = 0.1;
    return goal.targetAmount / totalMonths;
  }

  double getAverageDailyDeposit(SavingGoal goal) {
    final deposits = goal.transactions
        .where((t) => t.type == TransactionType.deposit)
        .map((t) => t.amount)
        .fold(0.0, (sum, val) => sum + val);

    final start = _normalizeDate(goal.startDate);
    final today = _normalizeDate(DateTime.now());
    int days = today.difference(start).inDays + 1;
    if (days <= 0) days = 1;
    return deposits / days;
  }

  double getEffectiveDailyRate(SavingGoal goal) {
    double avgDaily = getAverageDailyDeposit(goal);
    if (avgDaily <= 0) {
      avgDaily = getDailyTarget(goal);
    }
    return avgDaily;
  }

  DateTime? getProjectedCompletion(SavingGoal goal) {
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) {
      if (goal.transactions.isNotEmpty) {
        return _normalizeDate(goal.transactions.last.date);
      }
      return _normalizeDate(goal.startDate);
    }

    final rate = getEffectiveDailyRate(goal);
    if (rate <= 0) return null;

    final daysNeeded = (remaining / rate).ceil();
    final today = _normalizeDate(DateTime.now());
    return today.add(Duration(days: daysNeeded));
  }

  List<Milestone> recalculateMilestones(SavingGoal goal) {
    final newMilestones = _generateMilestones(goal.id, goal.targetAmount);
    
    for (var newMs in newMilestones) {
      final oldMsIndex = goal.milestones.indexWhere((m) => m.percentage == newMs.percentage);
      if (oldMsIndex != -1) {
        final oldMs = goal.milestones[oldMsIndex];
        newMs.isReached = oldMs.isReached;
        newMs.reachedAt = oldMs.reachedAt;
      }
    }
    return newMilestones;
  }

  void checkAndUpdateMilestones(SavingGoal goal) {
    final currentVal = goal.currentAmount;
    bool anyChanged = false;

    for (var ms in goal.milestones) {
      final wasReached = ms.isReached;
      if (currentVal >= ms.targetAmount) {
        if (!wasReached) {
          ms.isReached = true;
          ms.reachedAt = DateTime.now();
          anyChanged = true;
        }
      } else {
        if (wasReached) {
          ms.isReached = false;
          ms.reachedAt = null;
          anyChanged = true;
        }
      }
    }

    final isNowCompleted = currentVal >= goal.targetAmount;
    if (isNowCompleted != goal.isCompleted) {
      final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
      if (goalIndex != -1) {
        _goals[goalIndex] = goal.copyWith(isCompleted: isNowCompleted);
      }
    }

    if (anyChanged) {
      final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
      if (goalIndex != -1) {
        _goals[goalIndex] = _goals[goalIndex].copyWith(milestones: goal.milestones);
      }
    }
  }

  String getMotivationalMessage(SavingGoal goal) {
    final pct = getCompletionPercentage(goal);
    if (pct >= 100.0) {
      return "GOAL TERCAPAI! Selamat! 🎉";
    } else if (pct >= 75.0) {
      return "Hampir sampai! Jangan berhenti sekarang! ⚡";
    } else if (pct >= 50.0) {
      return "Setengahnya sudah! Terus pantang menyerah! 🔥";
    } else if (pct >= 25.0) {
      return "Seperempat jalan, luar biasa! 🎯";
    } else {
      return "Baru mulai, semangat! 💪";
    }
  }


  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(_goals.map((g) => g.toJson()).toList());
      await prefs.setString('savings_goals', data);
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  Future<void> loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isReminderEnabled = prefs.getBool('is_reminder_enabled') ?? false;
      _reminderHour = prefs.getInt('reminder_hour') ?? 20;
      _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
      _reminderMessage = prefs.getString('reminder_message') ??
          'Jangan lupa sisihkan uang hari ini untuk mencapai target tabunganmu!';

      final String? data = prefs.getString('savings_goals');
      if (data == null || data.isEmpty) {
        _loadSampleData();
      } else {
        final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
        _goals = decoded.map((item) => SavingGoal.fromJson(item as Map<String, dynamic>)).toList();
        
        for (var goal in _goals) {
          checkAndUpdateMilestones(goal);
        }
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
      _loadSampleData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReminderSettings(bool enabled, int hour, int minute, String message) async {
    _isReminderEnabled = enabled;
    _reminderHour = hour;
    _reminderMinute = minute;
    _reminderMessage = message;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_reminder_enabled', _isReminderEnabled);
      await prefs.setInt('reminder_hour', _reminderHour);
      await prefs.setInt('reminder_minute', _reminderMinute);
      await prefs.setString('reminder_message', _reminderMessage);

      if (_isReminderEnabled) {
        await NotificationService().requestPermissions();
        await NotificationService().scheduleDailyReminder(
          hour: _reminderHour,
          minute: _reminderMinute,
          body: _reminderMessage,
        );
      } else {
        await NotificationService().cancelReminder();
      }
    } catch (e) {
      debugPrint('Error updating reminder settings: $e');
    }

    notifyListeners();
  }


  List<Milestone> _generateMilestones(String goalId, double targetAmount) {
    return [
      Milestone(
        id: '${goalId}_25',
        label: '25% Terkumpul',
        percentage: 25.0,
        targetAmount: targetAmount * 0.25,
      ),
      Milestone(
        id: '${goalId}_50',
        label: '50% Terkumpul',
        percentage: 50.0,
        targetAmount: targetAmount * 0.50,
      ),
      Milestone(
        id: '${goalId}_75',
        label: '75% Terkumpul',
        percentage: 75.0,
        targetAmount: targetAmount * 0.75,
      ),
      Milestone(
        id: '${goalId}_100',
        label: 'Goal Tercapai!',
        percentage: 100.0,
        targetAmount: targetAmount,
      ),
    ];
  }

  void _loadSampleData() {
    final now = DateTime.now();

    final goal1Id = _uuid.v4();
    final goal1StartDate = now.subtract(const Duration(days: 90));
    final goal1TargetDate = now.add(const Duration(days: 180));
    final goal1Txs = [
      Transaction(
        id: _uuid.v4(),
        amount: 500000,
        date: goal1StartDate.add(const Duration(days: 10)),
        note: 'Tabungan awal',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 1000000,
        date: goal1StartDate.add(const Duration(days: 30)),
        note: 'Bonus kerja sampingan',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 750000,
        date: goal1StartDate.add(const Duration(days: 45)),
        note: 'Sisa uang jajan',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 1500000,
        date: goal1StartDate.add(const Duration(days: 60)),
        note: 'Gajian bulanan',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 2000000,
        date: goal1StartDate.add(const Duration(days: 75)),
        note: 'Uang thr',
        type: TransactionType.deposit,
      ),
    ];

    final goal1 = SavingGoal(
      id: goal1Id,
      title: 'iPhone 16 Pro',
      emoji: '📱',
      targetAmount: 20000000,
      startDate: goal1StartDate,
      targetDate: goal1TargetDate,
      category: 'gadget',
      milestones: _generateMilestones(goal1Id, 20000000),
      transactions: goal1Txs,
      notes: 'Beli yang warna titanium gurih!',
    );

    final goal2Id = _uuid.v4();
    final goal2StartDate = now.subtract(const Duration(days: 30));
    final goal2TargetDate = now.add(const Duration(days: 120));
    final goal2Txs = [
      Transaction(
        id: _uuid.v4(),
        amount: 500000,
        date: goal2StartDate.add(const Duration(days: 5)),
        note: 'Deposit pertama',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 1000000,
        date: goal2StartDate.add(const Duration(days: 15)),
        note: 'Tabungan mingguan',
        type: TransactionType.deposit,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 300000,
        date: goal2StartDate.add(const Duration(days: 25)),
        note: 'Hemat makan luar',
        type: TransactionType.deposit,
      ),
    ];

    final goal2 = SavingGoal(
      id: goal2Id,
      title: 'Liburan Bali',
      emoji: '🏖️',
      targetAmount: 8000000,
      startDate: goal2StartDate,
      targetDate: goal2TargetDate,
      category: 'vacation',
      milestones: _generateMilestones(goal2Id, 8000000),
      transactions: goal2Txs,
      notes: 'Tiket pesawat & penginapan di Ubud.',
    );

    _goals = [goal1, goal2];

    for (var g in _goals) {
      checkAndUpdateMilestones(g);
    }

    saveToPrefs();
  }
}
