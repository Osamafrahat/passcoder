class CardModel {
  final String id;
  final String userId;
  final String cardholderName;
  final String cardNumberEncrypted;
  final String expiryDateEncrypted;
  final String cvvEncrypted;
  final String? cardType;
  final bool isFavorite;
  final DateTime? deletedAt;
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
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrashed => deletedAt != null;

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardholderName: json['cardholder_name'] as String,
      cardNumberEncrypted: json['card_number_encrypted'] as String,
      expiryDateEncrypted: json['expiry_date_encrypted'] as String,
      cvvEncrypted: json['cvv_encrypted'] as String,
      cardType: json['card_type'] as String?,
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
      'cardholder_name': cardholderName,
      'card_number_encrypted': cardNumberEncrypted,
      'expiry_date_encrypted': expiryDateEncrypted,
      'cvv_encrypted': cvvEncrypted,
      'card_type': cardType,
      'is_favorite': isFavorite,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
