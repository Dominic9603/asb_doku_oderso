import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/license_service.dart';
import '../../../shared/theme/app_theme.dart';

class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;

  const ActivationScreen({super.key, required this.onActivated});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }
  
  Future<void> _activateApp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final licenseService = context.read<LicenseService>();
      final success = await licenseService.activateLicense(_keyController.text);
      
      if (mounted) {
        if (success) {
          widget.onActivated();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Ungültiger Product Key. Bitte überprüfen Sie Ihre Eingabe.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  const Icon(
                    Icons.medical_services_rounded,
                    size: 100,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'RescueDoc',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Professionelle Einsatzdokumentation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Activation Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'App aktivieren',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bitte geben Sie Ihren Product Key ein, um die App zu aktivieren.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Product Key Input
                          TextFormField(
                            controller: _keyController,
                            decoration: const InputDecoration(
                              labelText: 'Product Key',
                              hintText: 'XXXX-XXXX-XXXX-XXXX',
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte geben Sie einen Product Key ein';
                              }
                              if (!RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')
                                  .hasMatch(value.toUpperCase())) {
                                return 'Ungültiges Format (XXXX-XXXX-XXXX-XXXX)';
                              }
                              return null;
                            },
                          ),
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.critical.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.critical.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.critical,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.critical,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Activate Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _activateApp,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Aktivieren'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Text
                  Text(
                    'Sie haben noch keinen Product Key?\nKontaktieren Sie Ihren Administrator.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
