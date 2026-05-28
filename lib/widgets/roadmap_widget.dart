import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/saving_goal.dart';
import '../models/milestone.dart';
import '../providers/savings_provider.dart';

class RoadmapWidget extends StatelessWidget {
  final SavingGoal goal;

  const RoadmapWidget({
    Key? key,
    required this.goal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final avgDaily = provider.getAverageDailyDeposit(goal);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final DateFormat df = DateFormat('dd MMMM yyyy', 'id_ID');

    return Column(
      children: List.generate(goal.milestones.length, (index) {
        final milestone = goal.milestones[index];
        final isReached = milestone.isReached;

        // Calculate predicted date
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
              // Timeline Column (Circle + Line)
              Column(
                children: [
                  // Circle Indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isReached ? const Color(0xFFFFE500) : Colors.white,
                      border: Border.all(
                        color: const Color(0xFF111111),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF111111),
                          offset: Offset(3, 3),
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
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  // Vertical Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.5,
                        color: const Color(0xFF111111),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
              const SizedBox(width: 16),
              // Content Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${formatter.format(milestone.targetAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        predictionText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isReached ? const Color(0xFF00C49A) : Colors.black54,
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
