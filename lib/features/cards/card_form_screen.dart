import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/card_model.dart';
import '../../core/encryption/encryption_service.dart';

class CardFormScreen extends StatefulWidget {
  final CardModel? card;

  const CardFormScreen({super.key, this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardholderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();

  String? _cardType;
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _obscureCvv = true;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _cardholderNameController.text = widget.card!.cardholderName;
      _isFavorite = widget.card!.isFavorite;
      _cardType = widget.card!.cardType;
      _decryptExistingCard();
    }
  }

  Future<void> _decryptExistingCard() async {
    if (widget.card != null) {
      try {
        final cardNumber = await _encryptionService.decryptData(widget.card!.cardNumberEncrypted);
        final expiryDate = await _encryptionService.decryptData(widget.card!.expiryDateEncrypted);
        final cvv = await _encryptionService.decryptData(widget.card!.cvvEncrypted);

        setState(() {
          _cardNumberController.text = cardNumber;
          _expiryDateController.text = expiryDate;
          _cvvController.text = cvv;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error decrypting card: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _detectCardType(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+\d|\D'), '');
    if (cleaned.startsWith('4')) {
      setState(() => _cardType = 'Visa');
    } else if (cleaned.startsWith(RegExp(r'^5[1-5]'))) {
      setState(() => _cardType = 'Mastercard');
    } else if (cleaned.startsWith(RegExp(r'^3[47]'))) {
      setState(() => _cardType = 'American Express');
    } else if (cleaned.startsWith(RegExp(r'^6(?:011|5)'))) {
      setState(() => _cardType = 'Discover');
    } else {
      setState(() => _cardType = null);
    }
  }

  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  String _formatExpiryDate(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 2) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    }
    return cleaned;
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final encryptedCardNumber = await _encryptionService.encryptData(_cardNumberController.text.replaceAll(RegExp(r'\s'), ''));
      final encryptedExpiryDate = await _encryptionService.encryptData(_expiryDateController.text);
      final encryptedCvv = await _encryptionService.encryptData(_cvvController.text);

      final cardData = {
        'user_id': userId,
        'cardholder_name': _cardholderNameController.text.trim(),
        'card_number_encrypted': encryptedCardNumber,
        'expiry_date_encrypted': encryptedExpiryDate,
        'cvv_encrypted': encryptedCvv,
        'card_type': _cardType,
        'is_favorite': _isFavorite,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.card != null) {
        await _supabase
            .from('credit_cards')
            .update(cardData)
            .eq('id', widget.card!.id);
      } else {
        cardData['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('credit_cards').insert(cardData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.card != null ? 'Card updated' : 'Card saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card != null ? 'Edit Card' : 'Add Card'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cardholderNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name *',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: InputDecoration(
                  labelText: 'Card Number *',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: const OutlineInputBorder(),
                  suffixIcon: _cardType != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _cardType!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  _detectCardType(value);
                  final formatted = _formatCardNumber(value);
                  if (formatted != value) {
                    _cardNumberController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final cleaned = value.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 13 || cleaned.length > 19) {
                    return 'Please enter a valid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        hintText: 'MM/YY',
                      ),
                      onChanged: (value) {
                        final formatted = _formatExpiryDate(value);
                        if (formatted != value) {
                          _expiryDateController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return 'MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: _obscureCvv,
                      decoration: InputDecoration(
                        labelText: 'CVV *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCvv
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscureCvv = !_obscureCvv);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _saveCard,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.card != null ? 'Update Card' : 'Save Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
