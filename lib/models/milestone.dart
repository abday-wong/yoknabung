class Milestone {
  final String id;
  final String label;
  final double percentage;
  final double targetAmount;
  bool isReached;
  DateTime? reachedAt;

  Milestone({
    required this.id,
    required this.label,
    required this.percentage,
    required this.targetAmount,
    this.isReached = false,
    this.reachedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'percentage': percentage,
      'targetAmount': targetAmount,
      'isReached': isReached,
      'reachedAt': reachedAt?.toIso8601String(),
    };
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      label: json['label'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      isReached: json['isReached'] as bool? ?? false,
      reachedAt: json['reachedAt'] != null ? DateTime.parse(json['reachedAt'] as String) : null,
    );
  }
}
