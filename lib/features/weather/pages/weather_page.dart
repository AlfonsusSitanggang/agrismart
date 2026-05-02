import 'package:agrismart/core/constants/api_constants.dart';
import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late Future<Map<String, dynamic>> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _fetchWeather();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi nonaktif');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    final position = await _determinePosition();
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;


    final response = await dio.get(
      '/proxy/weather',
      queryParameters: {'lat': position.latitude, 'lon': position.longitude},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Request gagal: ${response.statusCode} - ${response.data}',
      );
    }

    return Map<String, dynamic>.from(response.data);
  }

  

  Future<void> _retry() async {
    setState(() {
      _weatherFuture = _fetchWeather();
    });
  }
  
  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca'),
        actions: [
          IconButton(onPressed: _retry, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final result = snapshot.data!;
          final data = result['data'];
          final city = data['name']?.toString() ?? '-';
          final temp = data['main']?['temp']?.toString() ?? '-';
          final weather =
              (data['weather'] != null &&
                  data['weather'] is List &&
                  data['weather'].isNotEmpty)
              ? data['weather'][0]['description']?.toString() ?? '-'
              : '-';
          final humidity = data['main']?['humidity']?.toString() ?? '-';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlue.shade300, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cuaca Saat Ini',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$temp °C',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weather,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detail Cuaca',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.water_drop_outlined,
                title: 'Kelembapan',
                value: '$humidity %',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.thermostat_outlined,
                title: 'Suhu',
                value: '$temp °C',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                value: city,
                color: Colors.redAccent,
              ),
            ],
          );
        },
      ),
    );
  }
}
