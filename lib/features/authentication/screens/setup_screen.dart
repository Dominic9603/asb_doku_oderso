import 'package:flutter/material.dart';
import 'package:rescue_doc/core/services/license_service.dart';
import 'package:rescue_doc/features/authentication/models/user_info.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class SetupScreen extends StatefulWidget {
  final LicenseService licenseService;
  final VoidCallback onSetupComplete;

  const SetupScreen({
    super.key,
    required this.licenseService,
    required this.onSetupComplete,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _shortSignController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _shortSignController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userInfo = UserInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        shortSign: _shortSignController.text.trim().toUpperCase(),
        recipientEmail: _emailController.text.trim(),
      );

      await widget.licenseService.saveUserInfo(userInfo);

      if (!mounted) return;
      widget.onSetupComplete();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RescueDoc - Personalisierung'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Willkommen bei RescueDoc',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bitte personalisieren Sie Ihre Nutzung:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Vorname
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname',
                  hintText: 'z.B. Max',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vorname erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nachname
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname',
                  hintText: 'z.B. Müller',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nachname erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kurzzeichen
              TextFormField(
                controller: _shortSignController,
                decoration: const InputDecoration(
                  labelText: 'Kurzzeichen',
                  hintText: 'z.B. MM oder MAX',
                  prefixIcon: Icon(Icons.badge),
                  helperText: 'Wird auf PDFs angezeigt (max. 4 Zeichen)',
                ),
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kurzzeichen erforderlich';
                  }
                  if (value.trim().length > 4) {
                    return 'Max. 4 Zeichen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Empfänger-Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Empfänger-Email',
                  hintText: 'ASB-Email-Adresse',
                  prefixIcon: Icon(Icons.email),
                  helperText: 'An diese Adresse werden Einsatzberichte gesendet',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Bitte eine gültige Email-Adresse eingeben';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Diese Daten werden für PDF-Exporte verwendet und lokal gespeichert.\n'
                  '📧 Die Email-Adresse wird als Empfänger für Einsatzberichte verwendet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveSetup,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Wird gespeichert...' : 'Personalisierung abschließen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
