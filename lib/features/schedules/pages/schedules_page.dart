import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  late Future<List<dynamic>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _fetchSchedules();
  }

  Future<List<dynamic>> _fetchSchedules() async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.get(
      '/schedules',
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

    final result = Map<String, dynamic>.from(response.data);
    return result['data'] as List<dynamic>;
  }

  Future<void> _reload() async {
    setState(() {
      _schedulesFuture = _fetchSchedules();
    });
  }

  Future<void> _addDummySchedule() async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final plantsResponse = await dio.get(
      '/plants',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (plantsResponse.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil tanaman: ${plantsResponse.data}'),
        ),
      );
      return;
    }

    final plantsResult = Map<String, dynamic>.from(plantsResponse.data);
    final plants = plantsResult['data'] as List<dynamic>;

    if (plants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan tanaman dulu sebelum membuat jadwal'),
        ),
      );
      return;
    }

    final firstPlant = plants.first as Map<String, dynamic>;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final wateringDate =
        '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';

    final response = await dio.post(
      '/schedules',
      data: {'plant_id': firstPlant['id'], 'watering_date': wateringDate},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
      );
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal tambah jadwal: ${response.data}')),
      );
    }
  }

  Future<void> _markScheduleCompleted(Map<String, dynamic> schedule) async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.put(
      '/schedules/${schedule['id']}',
      data: {'watering_date': schedule['watering_date'], 'status': 'completed'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status jadwal diperbarui')));
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update jadwal: ${response.data}')),
      );
    }
  }

  
  Future<void> _deleteSchedule(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.delete(
      '/schedules/$id',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jadwal berhasil dihapus')));
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus jadwal: ${response.data}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Penyiraman'),
        actions: [
          IconButton(onPressed: _addDummySchedule, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _schedulesFuture,
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
                    const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final schedules = snapshot.data!;

          if (schedules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 72,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada jadwal penyiraman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan jadwal agar penyiraman tanaman lebih teratur.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addDummySchedule,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Dummy'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index] as Map<String, dynamic>;
                final isCompleted = schedule['status'] == 'completed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isCompleted
                              ? Colors.green.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.access_time,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule['plant_name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Tanggal: ${schedule['watering_date']}'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isCompleted ? 'Completed' : 'Pending',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: () => _markScheduleCompleted(schedule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSchedule(schedule['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
