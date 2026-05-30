import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../providers/savings_provider.dart';

class RoadmapWidget extends StatelessWidget {
  final SavingGoal goal;

  const RoadmapWidget({
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
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    final avgDaily = provider.getAverageDailyDeposit(goal);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final DateFormat df = DateFormat('dd MMMM yyyy', 'id_ID');

    return Column(
      children: List.generate(goal.milestones.length, (index) {
        final milestone = goal.milestones[index];
        final isReached = milestone.isReached;

        String predictionText = '-';
        if (isReached && milestone.reachedAt != null) {
          predictionText = 'Tercapai pada: ${df.format(milestone.reachedAt!)}';
        } else if (avgDaily > 0) {
          final daysNeeded = (milestone.targetAmount / avgDaily).ceil();
          final predictedDate = goal.startDate.add(Duration(days: daysNeeded));
          predictionText = 'Proyeksi: ${df.format(predictedDate)}';
        } else {
          predictionText = 'Proyeksi: Belum ada data tabungan';
        }

        final isLast = index == goal.milestones.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isReached ? const Color(0xFFFFE500) : cardBgColor,
                      border: Border.all(
                        color: borderColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor,
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isReached
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFF111111),
                              size: 20,
                            )
                          : Text(
                              '${milestone.percentage.toInt()}%',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.5,
                        color: borderColor,
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${formatter.format(milestone.targetAmount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        predictionText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isReached ? const Color(0xFF00C49A) : subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
