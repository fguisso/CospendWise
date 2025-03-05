class Currency {
  final int id;
  final String name;
  final double rate;
  final String projectId;

  Currency({
    required this.id,
    required this.name,
    required this.rate,
    required this.projectId,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] as int,
      name: json['name'] as String,
      rate: json['rate'] as double,
      projectId: json['projectId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'projectId': projectId,
    };
  }

  Currency copyWith({
    int? id,
    String? name,
    double? rate,
    String? projectId,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      projectId: projectId ?? this.projectId,
    );
  }

  // Helper method to convert amount to base currency
  double convertToBase(double amount) {
    return amount * rate;
  }

  // Helper method to convert amount from base currency
  double convertFromBase(double amount) {
    return amount / rate;
  }
} 