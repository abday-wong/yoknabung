import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoknabung/models/saving_goal.dart';
import 'package:yoknabung/models/transaction.dart';
import 'package:yoknabung/providers/savings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SavingsProvider Calculation Tests', () {
    late SavingsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = SavingsProvider();
    });

    test('getDaysRemaining normalizes date arithmetic correctly', () {
      final now = DateTime.now();
      final goal = SavingGoal(
        id: 'test_goal',
        title: 'Test',
        emoji: '💰',
        targetAmount: 100000,
        startDate: DateTime(now.year, now.month, now.day - 5),
        targetDate: DateTime(now.year, now.month, now.day + 10),
        category: 'other',
        milestones: [],
        transactions: [],
      );

      final daysRemaining = provider.getDaysRemaining(goal);
      expect(daysRemaining, 10);
    });

    test('getDailyTarget calculates target correctly', () {
      final now = DateTime.now();
      final goal = SavingGoal(
        id: 'test_goal',
        title: 'Test',
        emoji: '💰',
        targetAmount: 150000,
        startDate: DateTime(now.year, now.month, now.day),
        targetDate: DateTime(now.year, now.month, now.day + 15),
        category: 'other',
        milestones: [],
        transactions: [],
      );

      final dailyTarget = provider.getDailyTarget(goal);
      expect(dailyTarget, 10000.0);
    });

    test('getAverageDailyDeposit uses normalized dates', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - 2);
      final goal = SavingGoal(
        id: 'test_goal',
        title: 'Test',
        emoji: '💰',
        targetAmount: 300000,
        startDate: startDate,
        targetDate: DateTime(now.year, now.month, now.day + 10),
        category: 'other',
        milestones: [],
        transactions: [
          Transaction(
            id: 't1',
            amount: 150000,
            type: TransactionType.deposit,
            date: startDate,
            note: '',
          ),
        ],
      );

      final avgDaily = provider.getAverageDailyDeposit(goal);
      expect(avgDaily, 50000.0);
    });

    test('getEffectiveDailyRate returns average daily if deposits exist, otherwise target', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - 4);
      
      final goalNoDeposits = SavingGoal(
        id: 'test_goal_1',
        title: 'Test 1',
        emoji: '💰',
        targetAmount: 50000,
        startDate: startDate,
        targetDate: DateTime(now.year, now.month, now.day + 4),
        category: 'other',
        milestones: [],
        transactions: [],
      );
      
      final dailyTarget = provider.getDailyTarget(goalNoDeposits);
      final rateNoDeposits = provider.getEffectiveDailyRate(goalNoDeposits);
      expect(rateNoDeposits, dailyTarget);

      final goalWithDeposits = SavingGoal(
        id: 'test_goal_2',
        title: 'Test 2',
        emoji: '💰',
        targetAmount: 100000,
        startDate: startDate,
        targetDate: DateTime(now.year, now.month, now.day + 5),
        category: 'other',
        milestones: [],
        transactions: [
          Transaction(
            id: 't2',
            amount: 25000,
            type: TransactionType.deposit,
            date: startDate,
            note: '',
          ),
        ],
      );

      final rateWithDeposits = provider.getEffectiveDailyRate(goalWithDeposits);
      expect(rateWithDeposits, 5000.0);
    });

    test('getProjectedCompletion calculates correct future date', () {
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      final startDate = DateTime(now.year, now.month, now.day - 1);
      final goal = SavingGoal(
        id: 'test_goal',
        title: 'Test',
        emoji: '💰',
        targetAmount: 100000,
        startDate: startDate,
        targetDate: DateTime(now.year, now.month, now.day + 10),
        category: 'other',
        milestones: [],
        transactions: [
          Transaction(
            id: 't1',
            amount: 20000,
            type: TransactionType.deposit,
            date: startDate,
            note: '',
          ),
        ],
      );

      final projected = provider.getProjectedCompletion(goal);
      expect(projected, todayOnly.add(const Duration(days: 8)));
    });

    test('SavingGoal supports imageUrl, targetUrl, and plannedDailySavings serialization and copyWith', () {
      final goal = SavingGoal(
        id: 'test_goal',
        title: 'Test',
        emoji: '💰',
        targetAmount: 100000,
        startDate: DateTime.now(),
        targetDate: DateTime.now().add(const Duration(days: 10)),
        category: 'other',
        milestones: [],
        transactions: [],
        imageUrl: '/path/to/image.png',
        targetUrl: 'https://example.com',
        plannedDailySavings: 10000.0,
      );

      final json = goal.toJson();
      expect(json['imageUrl'], '/path/to/image.png');
      expect(json['targetUrl'], 'https://example.com');
      expect(json['plannedDailySavings'], 10000.0);

      final fromJson = SavingGoal.fromJson(json);
      expect(fromJson.imageUrl, '/path/to/image.png');
      expect(fromJson.targetUrl, 'https://example.com');
      expect(fromJson.plannedDailySavings, 10000.0);

      final copied = fromJson.copyWith(clearImage: true, clearUrl: true, clearPlannedDailySavings: true);
      expect(copied.imageUrl, isNull);
      expect(copied.targetUrl, isNull);
      expect(copied.plannedDailySavings, isNull);

      final copiedWithValues = fromJson.copyWith(
        imageUrl: '/path/to/new_image.png',
        targetUrl: 'https://new.example.com',
        plannedDailySavings: 20000.0,
      );
      expect(copiedWithValues.imageUrl, '/path/to/new_image.png');
      expect(copiedWithValues.targetUrl, 'https://new.example.com');
      expect(copiedWithValues.plannedDailySavings, 20000.0);
    });

    test('Transaction supports proofImagePath serialization and deserialization', () {
      final tx = Transaction(
        id: 't_proof',
        amount: 50000.0,
        date: DateTime.parse('2026-05-30T12:00:00Z'),
        note: 'Setoran dengan bukti',
        type: TransactionType.deposit,
        proofImagePath: '/path/to/proof.jpg',
      );

      final json = tx.toJson();
      expect(json['proofImagePath'], '/path/to/proof.jpg');

      final fromJson = Transaction.fromJson(json);
      expect(fromJson.proofImagePath, '/path/to/proof.jpg');
      expect(fromJson.id, 't_proof');
      expect(fromJson.amount, 50000.0);
      expect(fromJson.note, 'Setoran dengan bukti');
      expect(fromJson.type, TransactionType.deposit);
    });

    test('getGlobalStreak and getGlobalLevel calculations work correctly', () {
      // Clear sample goals
      for (var g in List.from(provider.goals)) {
        provider.deleteGoal(g.id);
      }

      final now = DateTime.now();
      final goal = SavingGoal(
        id: 'test_g',
        title: 'Goal',
        emoji: '🎯',
        targetAmount: 100000,
        startDate: now.subtract(const Duration(days: 10)),
        targetDate: now.add(const Duration(days: 10)),
        category: 'other',
        milestones: [],
        transactions: [],
      );
      
      provider.addGoal(goal);
      
      expect(provider.getGlobalStreak(), 0);
      expect(provider.getGlobalLevel(), 1);
      expect(provider.getLevelTitle(1), 'cupu luwh');

      final txToday = Transaction(
        id: 'tx_today',
        amount: 100000,
        date: now,
        note: 'Hari ini',
        type: TransactionType.deposit,
      );
      provider.addTransaction('test_g', txToday);

      expect(provider.getGlobalStreak(), 1);
      expect(provider.getGlobalLevel(), 1);

      final txYesterday = Transaction(
        id: 'tx_yesterday',
        amount: 100000,
        date: now.subtract(const Duration(days: 1)),
        note: 'Kemarin',
        type: TransactionType.deposit,
      );
      provider.addTransaction('test_g', txYesterday);

      expect(provider.getGlobalStreak(), 2);

      for (int i = 0; i < 3; i++) {
        provider.addTransaction(
          'test_g',
          Transaction(
            id: 'tx_extra_$i',
            amount: 100000,
            date: now.subtract(Duration(days: i + 2)),
            note: 'Extra',
            type: TransactionType.deposit,
          ),
        );
      }

      expect(provider.getGlobalStreak(), 5);
      expect(provider.getGlobalLevel(), 2);
      expect(provider.getLevelTitle(2), 'bole laa');
    });

    test('getStreakEmoji, getStreakStatus, and getStreakBadgeColor return correct values for milestones', () {
      // Clear sample goals
      for (var g in List.from(provider.goals)) {
        provider.deleteGoal(g.id);
      }

      final now = DateTime.now();
      final goal = SavingGoal(
        id: 'test_streak_g',
        title: 'Goal Streak',
        emoji: '🎯',
        targetAmount: 50000000,
        startDate: now.subtract(const Duration(days: 600)),
        targetDate: now.add(const Duration(days: 10)),
        category: 'other',
        milestones: [],
        transactions: [],
      );
      provider.addGoal(goal);

      // 0 days
      expect(provider.getStreakEmoji(), '🔥');
      expect(provider.getStreakStatus(), 'iseng doang');
      expect(provider.getStreakBadgeColor(), const Color(0xFFFF9F1C));

      // 1 day
      provider.addTransaction('test_streak_g', Transaction(
        id: 'tx_d0',
        amount: 1000,
        date: now,
        type: TransactionType.deposit,
        note: '',
      ));
      expect(provider.getStreakEmoji(), '🔥');
      expect(provider.getStreakStatus(), 'iseng doang');

      // Helper function to add transactions for i days ago
      void addStreakDays(int start, int end) {
        for (int i = start; i <= end; i++) {
          provider.addTransaction('test_streak_g', Transaction(
            id: 'tx_d$i',
            amount: 1000,
            date: now.subtract(Duration(days: i)),
            type: TransactionType.deposit,
            note: '',
          ));
        }
      }

      // Add 11 days (total 12 days streak)
      addStreakDays(1, 11);
      expect(provider.getGlobalStreak(), 12);
      expect(provider.getStreakEmoji(), '⚡');
      expect(provider.getStreakStatus(), 'lumayan gacor');
      expect(provider.getStreakBadgeColor(), const Color(0xFFFFE500));

      // Add up to 32 days streak
      addStreakDays(12, 31);
      expect(provider.getGlobalStreak(), 32);
      expect(provider.getStreakEmoji(), '💥');
      expect(provider.getStreakStatus(), 'sepuh nabung');
      expect(provider.getStreakBadgeColor(), const Color(0xFFFF5A5F));

      // Add up to 52 days streak
      addStreakDays(32, 51);
      expect(provider.getGlobalStreak(), 52);
      expect(provider.getStreakEmoji(), '👑');
      expect(provider.getStreakStatus(), 'otewe kaya');
      expect(provider.getStreakBadgeColor(), const Color(0xFF00C49A));

      // Add up to 102 days streak
      addStreakDays(52, 101);
      expect(provider.getGlobalStreak(), 102);
      expect(provider.getStreakEmoji(), '🏆');
      expect(provider.getStreakStatus(), 'juragan tabungan');
      expect(provider.getStreakBadgeColor(), const Color(0xFF8B5CF6));

      // Add up to 302 days streak
      addStreakDays(102, 301);
      expect(provider.getGlobalStreak(), 302);
      expect(provider.getStreakEmoji(), '🔮');
      expect(provider.getStreakStatus(), 'kink abiez');
      expect(provider.getStreakBadgeColor(), const Color(0xFF4361EE));

      // Add up to 502 days streak
      addStreakDays(302, 501);
      expect(provider.getGlobalStreak(), 502);
      expect(provider.getStreakEmoji(), '🐉');
      expect(provider.getStreakStatus(), 'dah mentok kink');
      expect(provider.getStreakBadgeColor(), const Color(0xFFF72585));
    });

    test('Persistent EXP history keeps EXP and Level even when saving goals are deleted', () {
      final now = DateTime.now();
      final goal = SavingGoal(
        id: 'test_persist_g',
        title: 'Tabungan Keren',
        emoji: '🚀',
        targetAmount: 1000000,
        startDate: now.subtract(const Duration(days: 10)),
        targetDate: now.add(const Duration(days: 10)),
        category: 'other',
        milestones: [],
        transactions: [],
      );

      provider.addGoal(goal);
      expect(provider.getGlobalExp(), 0.0);

      // Add a deposit transaction of 500,000 EXP
      final tx = Transaction(
        id: 'tx_p1',
        amount: 500000,
        date: now,
        note: 'Gajian',
        type: TransactionType.deposit,
      );
      provider.addTransaction('test_persist_g', tx);

      expect(provider.getGlobalExp(), 500000.0);
      expect(provider.getGlobalLevel(), 2);
      expect(provider.expHistory.length, 1);
      expect(provider.expHistory.first.amount, 500000.0);

      // Now delete the saving goal
      provider.deleteGoal('test_persist_g');

      // Global EXP and Level should remain persistent!
      expect(provider.getGlobalExp(), 500000.0);
      expect(provider.getGlobalLevel(), 2);
      expect(provider.expHistory.length, 1);
    });
  });
}
