import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../providers/savings_provider.dart';
import 'neo_card.dart';

class SavingsCalculatorWidget extends StatelessWidget {
  final SavingGoal goal;

  const SavingsCalculatorWidget({
    Key? key,
    required this.goal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final DateFormat dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');

    int totalDays = goal.targetDate.difference(goal.startDate).inDays;
    if (totalDays <= 0) totalDays = 1;
    double totalWeeks = totalDays / 7.0;
    double totalMonths = totalDays / 30.0;

    String durationText = '$totalDays hari / ${totalWeeks.toStringAsFixed(1)} mgg / ${totalMonths.toStringAsFixed(1)} bln';

    double dailyTarget = provider.getDailyTarget(goal);
    double weeklyTarget = provider.getWeeklyTarget(goal);
    double monthlyTarget = provider.getMonthlyTarget(goal);

    int daysRemaining = provider.getDaysRemaining(goal);
    bool isUrgent = daysRemaining < 30;

    DateTime? projectedDate = provider.getProjectedCompletion(goal);
    String projectedDateText = '-';
    if (projectedDate != null) {
      projectedDateText = dateFormatter.format(projectedDate);
    } else {
      projectedDateText = 'Belum ada proyeksi';
    }

    Widget buildCalculatorRow(String label, String value, Color rowBg, {bool isValRed = false}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: rowBg,
          border: Border.all(color: const Color(0xFF111111), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
                fontSize: 13,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isValRed ? const Color(0xFFFF5733) : const Color(0xFF111111),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NeoCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kalkulator Tabungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          buildCalculatorRow('Durasi Total', durationText, const Color(0xFFFFE500)),
          buildCalculatorRow('Perlu nabung/hari', currencyFormatter.format(dailyTarget), const Color(0xFF00C49A)),
          buildCalculatorRow('Perlu nabung/minggu', currencyFormatter.format(weeklyTarget), const Color(0xFF4361EE).withOpacity(0.15)),
          buildCalculatorRow('Perlu nabung/bulan', currencyFormatter.format(monthlyTarget), const Color(0xFF4361EE).withOpacity(0.15)),
          buildCalculatorRow('Sisa waktu', '$daysRemaining hari lagi', isUrgent ? const Color(0xFFFF5733).withOpacity(0.2) : Colors.grey.shade100, isValRed: isUrgent),
          buildCalculatorRow('Proyeksi selesai', projectedDateText, const Color(0xFFFF5733).withOpacity(0.1)),
        ],
      ),
    );
  }
}
