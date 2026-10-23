import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Confidentialité')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          '''Politique de Confidentialité — Flash Deals

1. DONNÉES COLLECTÉES
- Nom, téléphone, email
- Adresses de livraison
- Historique de commandes
- Localisation (pour la livraison)

2. UTILISATION
Vos données servent à :
- Traiter vos commandes
- Améliorer votre expérience
- Vous envoyer des notifications personnalisées

3. PARTAGE
Nous ne partageons PAS vos données avec des tiers, sauf obligation légale.

4. SÉCURITÉ
Vos données sont chiffrées et stockées de manière sécurisée.

5. VOS DROITS
Vous pouvez demander la suppression de vos données à tout moment.

6. CONTACT
privacy@flashdeals.ci

Dernière mise à jour : 2025''',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}
