import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aide & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _faq('Comment passer une commande ?',
              'Ajoutez des produits au panier, puis cliquez sur "Passer la commande".'),
          _faq('Quels sont les frais de livraison ?',
              'Livraison dynamique selon la zone et le poids. Récupération : 1000 FCFA.'),
          _faq('Comment suivre ma livraison ?',
              'Allez dans "Mes commandes" → cliquez sur la commande.'),
          _faq('Comment obtenir des points fidélité ?',
              'Chaque commande vous rapporte des points. 1 point = 10 FCFA.'),
          _faq('Puis-je annuler une commande ?',
              'Oui, tant qu\'elle n\'est pas en cours de livraison.'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('Contacter le support',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(a, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
