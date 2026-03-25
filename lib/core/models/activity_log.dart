class ActivityLog {
  final String id;
  final String displayId;
  final String title;
  final String status;
  final String type;
  final String description;
  final String actor;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.displayId,
    required this.title,
    required this.status,
    required this.type,
    required this.description,
    required this.actor,
    required this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['_id'] ?? '',
      displayId: json['displayId'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      actor: json['actor'] ?? '',
      details: json['details'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
