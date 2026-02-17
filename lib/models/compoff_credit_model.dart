class CompoffCredit {
  final String id;
  final String employeeId;
  final DateTime earnedDate;
  final String earnedSource;
  final DateTime expiryDate;
  final String status;
  final String grantedBy;
  final DateTime grantedAt;
  final DateTime? usedAt;
  final String? leaveId;

  CompoffCredit({
    required this.id,
    required this.employeeId,
    required this.earnedDate,
    required this.earnedSource,
    required this.expiryDate,
    required this.status,
    required this.grantedBy,
    required this.grantedAt,
    this.usedAt,
    this.leaveId,
  });

  factory CompoffCredit.fromJson(Map<String, dynamic> json) {
    return CompoffCredit(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      earnedDate: DateTime.parse(json['earnedDate']),
      earnedSource: json['earnedSource'] ?? '',
      expiryDate: DateTime.parse(json['expiryDate']),
      status: json['status'] ?? 'AVAILABLE',
      grantedBy: json['grantedBy'] ?? '',
      grantedAt: json['grantedAt'] != null
          ? DateTime.parse(json['grantedAt'])
          : DateTime.now(),
      usedAt: json['usedAt'] != null ? DateTime.tryParse(json['usedAt']) : null,
      leaveId: json['leaveId'],
    );
  }
}
