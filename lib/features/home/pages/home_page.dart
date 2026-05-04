import 'package:agrismart/core/services/biometric_service.dart';
import 'package:agrismart/core/services/notification_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:agrismart/features/home/widgets/world_clock_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showWorldClock = true;

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
  }

  Future<void> _loadHomeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _showWorldClock = prefs.getBool('show_world_clock') ?? true;
    });
  }

  Future<void> _logout() async {
    await SecureStorageService().deleteToken();

    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _testBiometric() async {
    final biometricService = BiometricService();
    final available = await biometricService.isBiometricAvailable();

    if (!mounted) return;

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik tidak tersedia di perangkat ini'),
        ),
      );
      return;
    }

    final success = await biometricService.authenticate();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Autentikasi biometrik berhasil'
              : 'Autentikasi biometrik gagal',
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService.requestPermission();
    await NotificationService.showInstantNotification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi percobaan dikirim'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      _HomeFeature(
        title: 'Weather',
        icon: Icons.cloud_outlined,
        color: Colors.blue,
        onTap: () => context.push('/weather'),
      ),
      _HomeFeature(
        title: 'Tanaman',
        icon: Icons.local_florist_outlined,
        color: Colors.green,
        onTap: () => context.push('/plants'),
      ),
      _HomeFeature(
        title: 'Jadwal',
        icon: Icons.calendar_month_outlined,
        color: Colors.orange,
        onTap: () => context.push('/schedules'),
      ),
      _HomeFeature(
        title: 'Chatbot',
        icon: Icons.smart_toy_outlined,
        color: Colors.indigo,
        onTap: () => context.push('/chatbot'),
      ),
      _HomeFeature(
        title: 'Minigame',
        icon: Icons.sports_esports_outlined,
        color: Colors.purple,
        onTap: () => context.push('/minigame'),
      ),
      _HomeFeature(
        title: 'Biometrik',
        icon: Icons.fingerprint,
        color: Colors.teal,
        onTap: _testBiometric,
      ),
      _HomeFeature(
        title: 'Notifikasi',
        icon: Icons.notifications_active_outlined,
        color: Colors.redAccent,
        onTap: _testNotification,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSmart'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade200,
                    child: const Icon(Icons.eco, color: Colors.green, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang di AgriSmart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Kelola tanaman, cek cuaca, dan atur jadwal penyiraman dengan lebih mudah.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_showWorldClock) const WorldClockCard(),
          if (_showWorldClock) const SizedBox(height: 16),

          const Text(
            'Fitur Utama',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final feature = features[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: feature.onTap,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: feature.color.withOpacity(0.15),
                          child: Icon(feature.icon, color: feature.color),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          feature.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeFeature {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _HomeFeature({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}