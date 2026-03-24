// lib/screens/client/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Naviguer vers écran notifications si besoin
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Sécurité'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Naviguer vers écran sécurité
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Choix langue
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Écran à propos
            },
          ),
        ],
      ),
    );
  }
}