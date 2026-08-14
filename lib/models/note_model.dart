class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String contentEncrypted;
  final String category;
  final bool isFavorite;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.contentEncrypted,
    this.category = 'General',
    this.isFavorite = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrashed => deletedAt != null;

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      contentEncrypted: json['content_encrypted'] as String,
      category: json['category'] as String? ?? 'General',
      isFavorite: json['is_favorite'] as bool? ?? false,
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
      'content_encrypted': contentEncrypted,
      'category': category,
      'is_favorite': isFavorite,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
