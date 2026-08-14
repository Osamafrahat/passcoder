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
  final List<String> tags;
  final String? twoFactorCode;
  final DateTime? deletedAt;
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
    this.tags = const [],
    this.twoFactorCode,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrashed => deletedAt != null;

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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      twoFactorCode: json['two_factor_code'] as String?,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
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
      'tags': tags,
      'two_factor_code': twoFactorCode,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
