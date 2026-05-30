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
  });
}
