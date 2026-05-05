import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late Future<Map<String, dynamic>> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _fetchWeather();
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS mati');

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    final pos = await _getPosition();
    final token = await SecureStorageService().getToken();

    final dio = ApiService().dio;

    final res = await dio.get(
      '/proxy/weather',
      queryParameters: {'lat': pos.latitude, 'lon': pos.longitude},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return res.data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text("Gagal load cuaca");
        }

        final data = snapshot.data!;
        final city = data['data']['name'];
        final temp = data['data']['main']['temp'];
        final weather = data['data']['weather'][0]['description'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                    Text("$temp°C",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(weather,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}