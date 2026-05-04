import 'package:agrismart/core/services/biometric_service.dart';
import 'package:agrismart/core/services/notification_service.dart';
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
  bool showWorldClock = true;

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
  }

  Future<void> _loadHomeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      showWorldClock = prefs.getBool('show_world_clock') ?? true;
    });
  }

  Future<void> _testBiometric() async {
    final biometricService = BiometricService();
    final available = await biometricService.isBiometricAvailable();

    if (!mounted) return;

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik tidak tersedia di perangkat ini.'),
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
      const SnackBar(content: Text('Notifikasi percobaan dikirim')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      HomeActionItem(
        title: 'Tanaman',
        subtitle: 'Kelola data tanaman',
        icon: Icons.local_florist_outlined,
        color: Colors.green,
        onTap: () => context.push('/plants'),
      ),
      HomeActionItem(
        title: 'Jadwal',
        subtitle: 'Atur penyiraman',
        icon: Icons.calendar_month_outlined,
        color: Colors.orange,
        onTap: () => context.push('/schedules'),
      ),
      HomeActionItem(
        title: 'Cuaca',
        subtitle: 'Lihat cuaca saat ini',
        icon: Icons.cloud_outlined,
        color: Colors.blue,
        onTap: () => context.push('/weather'),
      ),
    ];

    final additionalFeatures = [
      HomeActionItem(
        title: 'Chatbot',
        subtitle: 'Tanya seputar tanaman',
        icon: Icons.smart_toy_outlined,
        color: Colors.indigo,
        onTap: () => context.push('/chatbot'),
      ),
      HomeActionItem(
        title: 'Minigame',
        subtitle: 'Panen virtual',
        icon: Icons.sports_esports_outlined,
        color: Colors.purple,
        onTap: () => context.push('/minigame'),
      ),
      HomeActionItem(
        title: 'Biometrik',
        subtitle: 'Tes autentikasi',
        icon: Icons.fingerprint,
        color: Colors.teal,
        onTap: _testBiometric,
      ),
      HomeActionItem(
        title: 'Notifikasi',
        subtitle: 'Tes pengingat',
        icon: Icons.notifications_active_outlined,
        color: Colors.redAccent,
        onTap: _testNotification,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AgriSmart'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.eco, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang di AgriSmart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Kelola tanaman, pantau cuaca, atur jadwal, dan jelajahi fitur pintar dalam satu aplikasi.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (showWorldClock) ...[
            const WorldClockCard(),
            const SizedBox(height: 16),
          ],

          const _SectionTitle(title: 'Ringkasan Cepat'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Tanaman',
                  value: 'Kelola',
                  icon: Icons.local_florist,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Jadwal',
                  value: 'Pantau',
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Cuaca',
                  value: 'Cek',
                  icon: Icons.cloud,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Fitur AI',
                  value: 'Aktif',
                  icon: Icons.smart_toy,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final item = quickActions[index];
              return _ActionCard(item: item);
            },
          ),
          const SizedBox(height: 20),

          const _SectionTitle(title: 'Fitur Tambahan'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: additionalFeatures.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = additionalFeatures[index];
              return _ActionCard(item: item);
            },
          ),
        ],
      ),
    );
  }
}

class HomeActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  HomeActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final HomeActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: item.color.withOpacity(0.12),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
