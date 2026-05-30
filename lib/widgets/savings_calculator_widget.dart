import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../providers/savings_provider.dart';
import 'neo_card.dart';

class SavingsCalculatorWidget extends StatelessWidget {
  final SavingGoal goal;

  const SavingsCalculatorWidget({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
    final double avgDaily = provider.getAverageDailyDeposit(goal);

    int daysRemaining = provider.getDaysRemaining(goal);
    bool isUrgent = daysRemaining < 30;

    DateTime? projectedDate = provider.getProjectedCompletion(goal);
    String projectedDateText = '-';
    if (projectedDate != null) {
      projectedDateText = dateFormatter.format(projectedDate);
    } else {
      projectedDateText = 'Belum ada proyeksi';
    }

    Widget buildCalculatorRow(String label, String value, Color rowBg, {bool isValRed = false, bool forceDarkText = false}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: rowBg,
          border: Border.all(color: borderColor, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: forceDarkText ? const Color(0xFF111111) : textColor,
                fontSize: 13,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isValRed
                      ? const Color(0xFFFF5733)
                      : (forceDarkText ? const Color(0xFF111111) : textColor),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NeoCard(
      color: cardBgColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kalkulator Tabungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          buildCalculatorRow('Mulai Menabung', dateFormatter.format(goal.startDate), isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          buildCalculatorRow('Target Selesai', dateFormatter.format(goal.targetDate), isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          buildCalculatorRow('Durasi Rencana', durationText, const Color(0xFFFFE500), forceDarkText: true),
          buildCalculatorRow('Perlu nabung/hari', currencyFormatter.format(dailyTarget), const Color(0xFF00C49A), forceDarkText: true),
          buildCalculatorRow('Perlu nabung/minggu', currencyFormatter.format(weeklyTarget), isDark ? const Color(0xFF4361EE).withValues(alpha: 0.3) : const Color(0xFF4361EE).withValues(alpha: 0.15)),
          buildCalculatorRow('Perlu nabung/bulan', currencyFormatter.format(monthlyTarget), isDark ? const Color(0xFF4361EE).withValues(alpha: 0.3) : const Color(0xFF4361EE).withValues(alpha: 0.15)),
          buildCalculatorRow('Sisa Waktu Target', '$daysRemaining hari lagi', isUrgent ? (isDark ? const Color(0xFFFF5733).withValues(alpha: 0.3) : const Color(0xFFFF5733).withValues(alpha: 0.2)) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100), isValRed: isUrgent),
          buildCalculatorRow('Proyeksi Selesai (Riil)', projectedDateText, isDark ? const Color(0xFFFF5733).withValues(alpha: 0.2) : const Color(0xFFFF5733).withValues(alpha: 0.1)),
          buildCalculatorRow('Tabungan Harian Rata-rata', currencyFormatter.format(avgDaily), isDark ? const Color(0xFF00C49A).withValues(alpha: 0.2) : const Color(0xFF00C49A).withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
              border: Border.all(color: borderColor, width: 2),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      avgDaily >= dailyTarget
                          ? Icons.check_circle
                          : (avgDaily == 0 ? Icons.info : Icons.warning),
                      color: avgDaily >= dailyTarget
                          ? const Color(0xFF00C49A)
                          : (avgDaily == 0 ? const Color(0xFF4361EE) : const Color(0xFFFF5733)),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Adaptasi Kebiasaan Nabung',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  avgDaily == 0
                      ? 'Belum ada transaksi menabung. Mulai catat tabungan masuk untuk menganalisis kebiasaan menabungmu dan memproyeksikan tanggal selesai riil!'
                      : (avgDaily >= dailyTarget
                          ? 'Luar biasa! Rata-rata tabungan harianmu (${currencyFormatter.format(avgDaily)}) berada di atas target wajib harian (${currencyFormatter.format(dailyTarget)}). Dengan kecepatan ini, kamu diproyeksikan selesai lebih cepat pada $projectedDateText!'
                          : 'Rata-rata tabungan harianmu (${currencyFormatter.format(avgDaily)}) masih di bawah target wajib harian (${currencyFormatter.format(dailyTarget)}). Berdasarkan kebiasaan ini, kamu diproyeksikan baru akan selesai pada $projectedDateText.'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
