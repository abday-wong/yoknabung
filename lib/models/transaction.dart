enum TransactionType {
  deposit,
  withdrawal,
}

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final TransactionType type;
  final String? proofImagePath;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
    this.proofImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
      'proofImagePath': proofImagePath,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      proofImagePath: json['proofImagePath'] as String?,
    );
  }
}
