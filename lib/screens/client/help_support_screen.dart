import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              'FAQ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Q: Comment changer ma compagnie?\n'
              'R: Rendez-vous dans "Modifier Profil" et sélectionnez votre compagnie.\n\n'
              'Q: J\'ai oublié mon mot de passe?\n'
              'R: Utilisez la fonctionnalité "Mot de passe oublié" à l\'écran de connexion.\n\n'
              'Pour toute autre question, contactez support@cardoil.com',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}