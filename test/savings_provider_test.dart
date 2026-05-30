import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoknabung/models/saving_goal.dart';
import 'package:yoknabung/models/transaction.dart';
import 'package:yoknabung/providers/savings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('SavingsProvider Calculation Tests', () {
    late SavingsProvider provider;

    setUp(() {
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
        amount: 10000,
        date: now,
        note: 'Hari ini',
        type: TransactionType.deposit,
      );
      provider.addTransaction('test_g', txToday);

      expect(provider.getGlobalStreak(), 1);
      expect(provider.getGlobalLevel(), 1);

      final txYesterday = Transaction(
        id: 'tx_yesterday',
        amount: 10000,
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
            amount: 5000,
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
  });
}
