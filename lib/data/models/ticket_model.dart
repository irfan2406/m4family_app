class TicketModel {
  final String id;
  final String? ticketId;
  final String subject;
  final String category;
  final String? message;
  final String status;
  final String priority;
  final List<dynamic> messages;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    this.ticketId,
    required this.subject,
    required this.category,
    this.message,
    required this.status,
    this.priority = 'Medium',
    this.messages = const [],
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] ?? '',
      ticketId: json['ticketId'],
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'General Query',
      message: json['message'],
      status: json['status'] ?? 'Open',
      priority: json['priority'] ?? 'Medium',
      messages: json['messages'] ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  String get displayId => ticketId ?? (id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase());

  TicketModel copyWith({
    String? id,
    String? ticketId,
    String? subject,
    String? category,
    String? message,
    String? status,
    String? priority,
    List<dynamic>? messages,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      message: message ?? this.message,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
