import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SecureStorageService().deleteToken();

    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFFC8E6C9),
                    child: Icon(
                      Icons.person,
                      size: 42,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Nama Mahasiswa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Petroleum Engineering • UPN Veteran Yogyakarta'),
                  SizedBox(height: 4),
                  Text(
                    'Aplikasi AgriSmart untuk membantu urban farming dengan fitur tanaman, cuaca, dan jadwal.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saran & Kesan TPM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kesan: Mata kuliah TPM memberi pemahaman yang lebih jelas tentang bagaimana aplikasi dirancang, dikembangkan, dan diuji secara terstruktur.',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Saran: Penyampaian materi dan praktik sudah baik. Akan lebih menarik jika porsi studi kasus proyek nyata dan evaluasi antarmuka aplikasi diperbanyak.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}