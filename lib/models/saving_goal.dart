import 'transaction.dart';
import 'milestone.dart';

class SavingGoal {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final String category;
  final List<Milestone> milestones;
  final List<Transaction> transactions;
  final bool isCompleted;
  final String? notes;

  SavingGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.startDate,
    required this.targetDate,
    required this.category,
    required this.milestones,
    required this.transactions,
    this.isCompleted = false,
    this.notes,
  });

  double get currentAmount {
    double total = 0.0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.deposit) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  SavingGoal copyWith({
    String? title,
    String? emoji,
    double? targetAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? category,
    List<Milestone>? milestones,
    List<Transaction>? transactions,
    bool? isCompleted,
    String? notes,
  }) {
    return SavingGoal(
      id: this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      milestones: milestones ?? this.milestones,
      transactions: transactions ?? this.transactions,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'targetAmount': targetAmount,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: json['category'] as String,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((m) => Milestone.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}
