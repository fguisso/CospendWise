class Project {
  final String id;
  final String name;
  final String description;
  final String? contactEmail;
  final String? autoExport;
  final String currencyName;
  final bool deletionDisabled;
  final String categorySort;
  final String paymentModeSort;
  final int? archivedTs;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.contactEmail,
    this.autoExport,
    this.currencyName = 'EUR',
    this.deletionDisabled = false,
    this.categorySort = 'manual',
    this.paymentModeSort = 'manual',
    this.archivedTs,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      contactEmail: json['contact_email'] as String?,
      autoExport: json['autoExport'] as String?,
      currencyName: json['currencyName'] as String? ?? 'EUR',
      deletionDisabled: json['deletionDisabled'] as bool? ?? false,
      categorySort: json['categorySort'] as String? ?? 'manual',
      paymentModeSort: json['paymentModeSort'] as String? ?? 'manual',
      archivedTs: json['archivedTs'] as int?,
      memberIds: List<String>.from(json['memberIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contact_email': contactEmail,
      'autoExport': autoExport,
      'currencyName': currencyName,
      'deletionDisabled': deletionDisabled,
      'categorySort': categorySort,
      'paymentModeSort': paymentModeSort,
      'archivedTs': archivedTs,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? contactEmail,
    String? autoExport,
    String? currencyName,
    bool? deletionDisabled,
    String? categorySort,
    String? paymentModeSort,
    int? archivedTs,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      autoExport: autoExport ?? this.autoExport,
      currencyName: currencyName ?? this.currencyName,
      deletionDisabled: deletionDisabled ?? this.deletionDisabled,
      categorySort: categorySort ?? this.categorySort,
      paymentModeSort: paymentModeSort ?? this.paymentModeSort,
      archivedTs: archivedTs ?? this.archivedTs,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 