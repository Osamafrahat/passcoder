import 'package:json_annotation/json_annotation.dart';

part 'password_model.g.dart';

@JsonSerializable()
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

  factory PasswordModel.fromJson(Map<String, dynamic> json) =>
      _$PasswordModelFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordModelToJson(this);
}
