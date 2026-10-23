import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          '''Conditions Générales d'Utilisation — Flash Deals

1. ACCEPTATION
En utilisant l'application Flash Deals, vous acceptez les présentes conditions.

2. SERVICE
Flash Deals met en relation des clients avec des grandes surfaces proposant des articles en promotion ou liquidation.

3. COMMANDES
Toute commande est ferme et définitive après paiement.

4. LIVRAISON
Les frais de livraison sont calculés selon la zone et le poids. Le service de livraison est exclusivement assuré par Flash Deals.

5. PAIEMENT
Le paiement est 100% en ligne (Mobile Money, CB, Wallet).

6. RETOURS
Les articles périssables ne sont pas remboursables sauf en cas de vice caché.

7. RESPONSABILITÉ
Flash Deals ne peut être tenu responsable de l'indisponibilité des produits chez les partenaires.

8. DONNÉES PERSONNELLES
Vos données sont traitées conformément à notre politique de confidentialité.

Dernière mise à jour : 2025''',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}
