import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/payment/paiement_pro_service.dart';
import '../../../core/constants/app_colors.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Deals Cash'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletStreamProvider);
          ref.invalidate(transactionsStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            walletAsync.when(
              data: (wallet) => _BalanceCard(wallet: wallet),
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erreur : $e'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRecharge(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Recharger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleWithdraw(context, ref),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Retirer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Historique des transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Aucune transaction pour le moment.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: transactions
                      .map((tx) => _TransactionTile(transaction: tx))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur : $e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWithdraw(BuildContext context, WidgetRef ref) async {
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+225');
    String operator = 'WAVE';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Retirer Deals Cash'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (min 500 FCFA)',
                    prefixIcon: Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numero (+225...)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: operator,
                  decoration: const InputDecoration(
                    labelText: 'Operateur',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'WAVE', child: Text('Wave')),
                    DropdownMenuItem(value: 'ORANGE', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'MTN', child: Text('MTN MoMo')),
                    DropdownMenuItem(value: 'FLOOZ', child: Text('Moov Money')),
                  ],
                  onChanged: (v) => setStateDialog(() => operator = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount < 500) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Montant minimum : 500 FCFA')),
                  );
                  return;
                }
                if (!phoneCtrl.text.startsWith('+225')) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Format : +225XXXXXXXXXX')),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'amount': amount,
                  'phone': phoneCtrl.text.trim(),
                  'operator': operator,
                });
              },
              child: const Text('Retirer'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://flash-deals-server.onrender.com/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.uid,
          'amount': result['amount'],
          'phone': result['phone'],
          'operator': result['operator'],
        }),
      );

      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retrait initie ! Verifiez votre compte'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(walletStreamProvider);
          ref.invalidate(transactionsStreamProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur reseau : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRecharge(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '2000');
    final montant = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recharger Deals Cash'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant (FCFA)',
            prefixIcon: Icon(Icons.money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('Payer'),
          ),
        ],
      ),
    );

    if (montant == null || montant <= 0) return;

    final authUser = ref.read(authUserProvider);
    if (authUser == null) return;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PaiementProWebView(
            amount: montant,
            channel: 'WAVECI',
            referenceNumber: PaiementProService.generateReference(),
            customerEmail: authUser.email ?? 'client@flashdeals.ci',
            customerFirstName: 'Kouassi',
            customerLastName: 'Christophe',
            customerPhone: '0718148779',
            description: 'Recharge Deals Cash',
            returnURL: 'flashdeals://payment-return',
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement réussi ! Wallet à créditer manuellement.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onFailure: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement annulé ou échoué'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

class _BalanceCard extends StatelessWidget {
  final dynamic wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('Solde disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${wallet.balance.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wallet.currency,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'credit';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} F',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
