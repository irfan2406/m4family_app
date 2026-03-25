class TicketModel {
  final String id;
  final String subject;
  final String category;
  final String message;
  final String status;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'General Query',
      message: json['message'] ?? '',
      status: json['status'] ?? 'Open',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  TicketModel copyWith({
    String? id,
    String? subject,
    String? category,
    String? message,
    String? status,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
