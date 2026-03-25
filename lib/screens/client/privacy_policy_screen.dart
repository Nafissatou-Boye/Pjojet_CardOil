import 'package:flutter/material.dart';
import '../../langue/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.privacyTitle),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.privacy_tip,
                    size: 40,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Titre
              Center(
                child: Text(
                  t.privacyTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Intro
              Text(
                t.privacyIntro,
                style: const TextStyle(
                  fontSize: 15, height: 1.6, color: Color(0xFF4B5563)),
              ),

              const SizedBox(height: 32),

              // Sections
              _buildSection(t.privacySection1Title, t.privacySection1Content),
              _buildSection(t.privacySection2Title, t.privacySection2Content),
              _buildSection(t.privacySection3Title, t.privacySection3Content),
              _buildSection(t.privacySection4Title, t.privacySection4Content),
              _buildSection(t.privacySection5Title, t.privacySection5Content),
              _buildSection(t.privacySection6Title, t.privacySection6Content),
              _buildSection(t.privacySection7Title, t.privacySection7Content),
              _buildSection(
                t.privacySection8Title,
                '${t.privacySection8Content}\n${t.privacyContactEmail}',
                isLast: true,
              ),

              const SizedBox(height: 32),

              // Bouton contact
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir email ou support
                  },
                  icon: const Icon(Icons.email),
                  label: Text(t.contactUs),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15, height: 1.6, color: Color(0xFF4B5563)),
        ),
        if (!isLast) const SizedBox(height: 24),
      ],
    );
  }
}
