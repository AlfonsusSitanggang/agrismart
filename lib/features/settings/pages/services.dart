import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = true;
  bool _showWorldClock = true;
  bool _biometricEnabled = false;
  bool _notificationEnabled = true;
  String _primaryTimeZone = 'WIB';
  bool _deviceSupportsBiometric = false;
  bool _biometricAvailable = false;

  final List<String> _timeZones = ['WIB', 'WITA', 'WIT', 'London'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricSupport();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _showWorldClock = prefs.getBool('show_world_clock') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _primaryTimeZone = prefs.getString('primary_time_zone') ?? 'WIB';
      _isLoading = false;
    });
  }

  Future<void> _checkBiometricSupport() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!mounted) return;

    setState(() {
      _biometricAvailable = canCheckBiometrics;
      _deviceSupportsBiometric = isDeviceSupported;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      if (!_deviceSupportsBiometric || !_biometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perangkat ini tidak mendukung biometrik'),
          ),
        );
        return;
      }

      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Aktifkan login biometrik untuk AgriSmart',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (!mounted) return;

        if (authenticated) {
          setState(() {
            _biometricEnabled = true;
          });
          await _saveBool('biometric_enabled', true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrik berhasil diaktifkan'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengaktifkan biometrik: $e'),
          ),
        );
      }
    } else {
      setState(() {
        _biometricEnabled = false;
      });
      await _saveBool('biometric_enabled', false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik dinonaktifkan'),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('Display & Time'),
          _buildCard(
            children: [
              SwitchListTile(
                title: const Text('Tampilkan World Clock di Home'),
                subtitle: const Text(
                  'Menampilkan WIB, WITA, WIT, dan London di halaman utama',
                ),
                value: _showWorldClock,
                onChanged: (value) async {
                  setState(() {
                    _showWorldClock = value;
                  });
                  await _saveBool('show_world_clock', value);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Zona Waktu Utama'),
                subtitle: Text(_primaryTimeZone),
                trailing: DropdownButton<String>(
                  value: _primaryTimeZone,
                  underline: const SizedBox(),
                  items: _timeZones.map((zone) {
                    return DropdownMenuItem<String>(
                      value: zone,
                      child: Text(zone),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _primaryTimeZone = value;
                    });
                    await _saveString('primary_time_zone', value);
                  },
                ),
              ),
            ],
          ),
          _buildSectionTitle('Security'),
          _buildCard(
            children: [
              SwitchListTile(
                title: const Text('Enable Biometric Login'),
                subtitle: Text(
                  _deviceSupportsBiometric && _biometricAvailable
                      ? 'Gunakan sidik jari / face unlock untuk login'
                      : 'Biometrik tidak tersedia di perangkat ini',
                ),
                value: _biometricEnabled,
                onChanged:
                    (_deviceSupportsBiometric && _biometricAvailable)
                        ? _toggleBiometric
                        : null,
              ),
            ],
          ),
          _buildSectionTitle('Notifications'),
          _buildCard(
            children: [
              SwitchListTile(
                title: const Text('Enable Reminder Notifications'),
                subtitle: const Text(
                  'Aktifkan pengingat jadwal penyiraman',
                ),
                value: _notificationEnabled,
                onChanged: (value) async {
                  setState(() {
                    _notificationEnabled = value;
                  });
                  await _saveBool('notification_enabled', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}