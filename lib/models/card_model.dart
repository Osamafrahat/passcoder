import 'package:json_annotation/json_annotation.dart';

part 'card_model.g.dart';

@JsonSerializable()
class CardModel {
  final String id;
  final String userId;
  final String cardholderName;
  final String cardNumberEncrypted;
  final String expiryDateEncrypted;
  final String cvvEncrypted;
  final String? cardType;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  CardModel({
    required this.id,
    required this.userId,
    required this.cardholderName,
    required this.cardNumberEncrypted,
    required this.expiryDateEncrypted,
    required this.cvvEncrypted,
    this.cardType,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);

  Map<String, dynamic> toJson() => _$CardModelToJson(this);
}
