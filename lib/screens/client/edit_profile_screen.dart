// lib/screens/auth/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCompagnie;
  bool _isLoading = false;

  final List<Map<String, String>> _compagnies = [
    {'name': 'TOTAL', 'icon': '🔴'},
    {'name': 'SHELL', 'icon': '🟡'},
    {'name': 'ORYX', 'icon': '🟢'},
    {'name': 'ELTON', 'icon': '🔵'},
    {'name': 'EDK', 'icon': '🟣'},
    {'name': 'PETROSEN', 'icon': '🟠'},
    {'name': 'OILIBYA', 'icon': '⚫'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final authService = context.read<AuthService>();
    final result = await authService.loadUserProfile();
    if (result['success'] == true && result['user'] != null) {
      final user = result['user'];
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _selectedCompagnie = user.selectedCompagnie;
      setState(() {});
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);

    if (_selectedCompagnie == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.mustSelectCompany),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    try {
      await authService.updateUserFullName(_fullNameController.text.trim());
      await authService.updateSelectedCompany(_selectedCompagnie!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.profileUpdated),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      final t2 = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t2.updateError}: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompanyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _compagnies.length,
          itemBuilder: (context, index) {
            final company = _compagnies[index];
            return ListTile(
              leading: Text(company['icon']!,
                  style: const TextStyle(fontSize: 32)),
              title: Text(company['name']!),
              onTap: () {
                setState(() => _selectedCompagnie = company['name']);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(title: Text(t.editProfile)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(labelText: t.fullName),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t.enterFullName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: t.readOnly),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _showCompanyPicker,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t.preferredCompany,
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedCompagnie ?? t.selectCompany,
                            style: TextStyle(
                              color: _selectedCompagnie != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          child: Text(t.saveChanges),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}