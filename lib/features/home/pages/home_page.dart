import 'package:agrismart/core/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:agrismart/features/auth/pages/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SecureStorageService().deleteToken();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final biometricService = BiometricService();

            final available = await biometricService.isBiometricAvailable();

            if (!available) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometrik tidak tersedia di perangkat ini'),
                ),
              );
              return;
            }

            final success = await biometricService.authenticate();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Autentikasi biometrik berhasil'
                      : 'Autentikasi biometrik gagal',
                ),
              ),
            );
          },
          child: const Text('Tes Biometrik'),
        ),
      ),
    );
  }
}
