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
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _encryptionService = EncryptionService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscureCvv = true;
  String _cardType = 'Visa';

  final _cardTypes = ['Visa', 'Mastercard', 'Amex', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _nameController.text = widget.card!.cardholderName;
      _cardType = widget.card!.cardType ?? 'Other';
      _loadEncryptedFields();
    }
    _numberController.addListener(_detectCardType);
  }

  Future<void> _loadEncryptedFields() async {
    try { _numberController.text = await _encryptionService.decryptData(widget.card!.cardNumberEncrypted); } catch (_) {}
    try { _expiryController.text = await _encryptionService.decryptData(widget.card!.expiryDateEncrypted); } catch (_) {}
    try { _cvvController.text = await _encryptionService.decryptData(widget.card!.cvvEncrypted); } catch (_) {}
  }

  void _detectCardType() {
    final num = _numberController.text.replaceAll(RegExp(r'\D'), '');
    String type = 'Other';
    if (num.startsWith('4')) type = 'Visa';
    else if (num.startsWith('5') || num.startsWith('2')) type = 'Mastercard';
    else if (num.startsWith('3')) type = 'Amex';
    if (type != _cardType) setState(() => _cardType = type);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final encryptedNumber = await _encryptionService.encryptData(_numberController.text.replaceAll(RegExp(r'\s'), ''));
      final encryptedExpiry = await _encryptionService.encryptData(_expiryController.text);
      final encryptedCvv = await _encryptionService.encryptData(_cvvController.text);
      final data = {
        'user_id': userId, 'cardholder_name': _nameController.text,
        'card_number_encrypted': encryptedNumber,
        'card_type': _cardType,
        'expiry_date_encrypted': encryptedExpiry,
        'cvv_encrypted': encryptedCvv,
      };
      if (widget.card != null) {
        await _supabase.from('cards').update(data).eq('id', widget.card!.id);
      } else {
        await _supabase.from('cards').insert(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.card != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Card' : 'New Card'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(_nameController, 'Cardholder Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_numberController, 'Card Number', Icons.credit_card, keyboard: TextInputType.number, maxLength: 19),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildField(_expiryController, 'MM/YY', Icons.calendar_today, keyboard: TextInputType.datetime, maxLength: 5)),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(
                controller: _cvvController, obscureText: _obscureCvv,
                maxLength: 4,
                decoration: InputDecoration(labelText: 'CVV', prefixIcon: const Icon(Icons.lock_outlined),
                  counterText: '',
                  filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  suffixIcon: IconButton(icon: Icon(_obscureCvv ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => _obscureCvv = !_obscureCvv)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              )),
            ]),
            const SizedBox(height: 20),
            Text('Card Network', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _cardTypes.map((t) {
                final selected = _cardType == t;
                return ChoiceChip(label: Text(t), selected: selected, onSelected: (_) => setState(() => _cardType = t),
                  selectedColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  labelStyle: TextStyle(color: selected ? Colors.white : theme.colorScheme.onSurface),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isLoading ? const CircularProgressIndicator() : Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {TextInputType? keyboard, int? maxLength}) {
    return TextFormField(
      controller: c, keyboardType: keyboard, maxLength: maxLength,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), counterText: '',
        filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
