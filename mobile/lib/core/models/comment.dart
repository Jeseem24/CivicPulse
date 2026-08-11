class Comment {
  final String id;
  final String userName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Anonymous',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
