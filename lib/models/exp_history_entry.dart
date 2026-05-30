class ExpHistoryEntry {
  final String id;
  final DateTime date;
  final double amount;
  final String goalTitle;
  final String note;

  ExpHistoryEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.goalTitle,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'goalTitle': goalTitle,
      'note': note,
    };
  }

  factory ExpHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExpHistoryEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      goalTitle: json['goalTitle'] as String,
      note: json['note'] as String? ?? '',
    );
  }
}
