class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;

  /// Website deep-link (e.g. "/support/tickets/:id"). The app ignores this for
  /// routing and uses [metadata] instead, but it is kept for completeness.
  final String? link;

  /// Server-supplied routing hints, e.g. {type: "TICKET_REPLY", ticketId: ...}.
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.link,
    this.metadata = const {},
  });

  /// `metadata.type` — e.g. "TICKET_REPLY" when an admin answered a ticket.
  String? get metaType => metadata['type']?.toString();

  /// `metadata.ticketId` — the ticket to open for a TICKET_REPLY notification.
  String? get ticketId => metadata['ticketId']?.toString();

  /// True when this notification is an admin reply on a support ticket.
  bool get isTicketReply =>
      metaType == 'TICKET_REPLY' && (ticketId?.isNotEmpty ?? false);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'Announcement',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      link: json['link']?.toString(),
      metadata: rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : const {},
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
    String? link,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      link: link ?? this.link,
      metadata: metadata ?? this.metadata,
    );
  }
}
