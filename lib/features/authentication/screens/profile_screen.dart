import 'package:flutter/material.dart';
import 'package:rescue_doc/core/services/license_service.dart';
import 'package:rescue_doc/features/authentication/models/user_info.dart';
import '../../../core/utils/top_notification.dart';

/// Screen zum Anzeigen und Bearbeiten der Benutzerdaten (Profil-Seite).
/// Zugänglich über den Profil-Button in der MissionListScreen-AppBar.
class ProfileScreen extends StatefulWidget {
  final LicenseService licenseService;

  const ProfileScreen({
    super.key,
    required this.licenseService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _shortSignController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _shortSignController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await widget.licenseService.getUserInfo();
      if (userInfo != null && mounted) {
        setState(() {
          _firstNameController.text = userInfo.firstName;
          _lastNameController.text = userInfo.lastName;
          _shortSignController.text = userInfo.shortSign;
          _emailController.text = userInfo.recipientEmail;
        });
      }
    } catch (e) {
      // Felder bleiben leer – Benutzer kann neu eingeben
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userInfo = UserInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        shortSign: _shortSignController.text.trim().toUpperCase(),
        recipientEmail: _emailController.text.trim(),
      );
      await widget.licenseService.saveUserInfo(userInfo);

      if (!mounted) return;
      TopNotification.show(
        '✅ Benutzerdaten gespeichert',
        backgroundColor: Colors.green,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        'Fehler beim Speichern: $e',
        duration: const Duration(milliseconds: 2400),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzerdaten'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Persönliche Daten',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Diese Daten erscheinen auf exportierten PDFs.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

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
                        helperText:
                            'An diese Adresse werden Einsatzberichte gesendet',
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
                        '💡 Die Daten werden lokal im Browser gespeichert und '
                        'bleiben auch nach dem Neuladen erhalten.\n'
                        '📄 Vorname, Nachname und Kurzzeichen erscheinen auf '
                        'allen exportierten Einsatzberichten.',
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Speichern-Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                            _isSaving ? 'Wird gespeichert...' : 'Speichern'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
