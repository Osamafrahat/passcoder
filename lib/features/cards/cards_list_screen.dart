import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/card_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'card_form_screen.dart';

class CardsListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const CardsListScreen({super.key, this.onLogout});
  @override
  State<CardsListScreen> createState() => _CardsListScreenState();
}

class _CardsListScreenState extends State<CardsListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();
  List<CardModel> _cards = [];
  List<Map<String, String>> _decryptedCards = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _loadCards(); }

  Future<void> _loadCards() async {
    setState(() { _isLoading = true; _decryptedCards = []; });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase.from('cards').select('id,user_id,cardholder_name,card_number_encrypted,expiry_date_encrypted,cvv_encrypted,card_type,is_favorite,created_at,updated_at').eq('user_id', userId).order('created_at', ascending: false);
      final cards = data.map((e) => CardModel.fromJson(e)).where((c) => !c.isTrashed).toList();
      final decrypted = <Map<String, String>>[];
      for (final c in cards) {
        String number = '', expiry = '';
        try { number = await _encryption.decryptData(c.cardNumberEncrypted); } catch (_) {}
        try { expiry = await _encryption.decryptData(c.expiryDateEncrypted); } catch (_) {}
        decrypted.add({'number': number, 'expiry': expiry, 'type': c.cardType ?? 'Other'});
      }
      setState(() { _cards = cards; _decryptedCards = decrypted; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Color _cardColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'visa': return const Color(0xFF1A1F71);
      case 'mastercard': return const Color(0xFFEB001B);
      case 'amex': return const Color(0xFF006FCF);
      default: return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCards = _decryptedCards.where((cd) => _searchQuery.isEmpty || cd['number']!.contains(_searchQuery.replaceAll(' ', '')) || cd['type']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cards',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardFormScreen())).then((_) => _loadCards()),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(hintText: 'Search cards...', prefixIcon: const Icon(Icons.search, size: 22),
                  filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : visibleCards.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.credit_card_outlined, size: 48, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text('No cards yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap + to add your first card', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: visibleCards.length,
                        itemBuilder: (_, i) {
                          final c = _cards[_decryptedCards.indexOf(visibleCards[i])];
                          final cd = visibleCards[i];
                          final color = _cardColor(cd['type']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CreditCardWidget(
                              cardholderName: c.cardholderName,
                              cardNumber: cd['number'] ?? '',
                              expiryDate: cd['expiry'] ?? '',
                              cardType: cd['type'] ?? 'Other',
                              color: color,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardFormScreen(card: c))).then((_) => _loadCards()),
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Card'),
                                    content: Text('Delete "${c.cardholderName}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _supabase.from('cards').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', c.id);
                                  } catch (_) {
                                    await _supabase.from('cards').delete().eq('id', c.id);
                                  }
                                  _loadCards();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CreditCardWidget extends StatelessWidget {
  final String cardholderName, cardNumber, expiryDate, cardType;
  final Color color;
  final VoidCallback onTap, onDelete;

  const _CreditCardWidget({required this.cardholderName, required this.cardNumber, required this.expiryDate, required this.cardType, required this.color, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4, shadowColor: color.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 200, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(cardType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    child: const Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.white70), SizedBox(width: 8), Text('Edit', style: TextStyle(color: Colors.white))]),
                    onTap: onTap,
                  ),
                  PopupMenuItem(
                    child: const Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                    onTap: onDelete,
                  ),
                ],
              ),
            ]),
            const Spacer(),
            Text(cardNumber.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} '), style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w500)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CARD HOLDER', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(cardholderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('EXPIRES', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(expiryDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}
