class PasswordModel {
  final String id;
  final String userId;
  final String title;
  final String? username;
  final String passwordEncrypted;
  final String? url;
  final String? notes;
  final String category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordModel({
    required this.id,
    required this.userId,
    required this.title,
    this.username,
    required this.passwordEncrypted,
    this.url,
    this.notes,
    this.category = 'General',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      username: json['username'] as String?,
      passwordEncrypted: json['password_encrypted'] as String,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String? ?? 'General',
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'username': username,
      'password_encrypted': passwordEncrypted,
      'url': url,
      'notes': notes,
      'category': category,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
