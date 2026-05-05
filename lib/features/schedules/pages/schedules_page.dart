import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/notification_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  Future<String> _getToken() async {
    final token = await SecureStorageService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }
    return token;
  }

  Future<List<dynamic>> _fetchSchedules() async {
    final token = await _getToken();
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

  Future<List<dynamic>> _fetchPlants() async {
    final token = await _getToken();
    final dio = ApiService().dio;

    final response = await dio.get(
      '/plants',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil tanaman: ${response.statusCode} - ${response.data}',
      );
    }

    final result = Map<String, dynamic>.from(response.data);
    return result['data'] as List<dynamic>;
  }

  Future<void> _reload() async {
    setState(() {
      _schedulesFuture = _fetchSchedules();
    });
    await _schedulesFuture;
  }

  Future<void> _addSchedule({
    required int plantId,
    required String wateringDate,
  }) async {
    final token = await _getToken();
    final dio = ApiService().dio;

    final response = await dio.post(
      '/schedules',
      data: {
        'plant_id': plantId,
        'watering_date': wateringDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal tambah jadwal: ${response.data}')),
      );
    }
  }

  Future<void> _showAddScheduleDialog() async {
    List<dynamic> plants = [];

    try {
      plants = await _fetchPlants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil tanaman: $e')),
      );
      return;
    }

    if (plants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan tanaman dulu sebelum membuat jadwal'),
        ),
      );
      return;
    }

    int? selectedPlantId = (plants.first as Map<String, dynamic>)['id'] as int;
    String selectedPlantName =
        (plants.first as Map<String, dynamic>)['name']?.toString() ?? 'Tanaman';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
            final formattedTime = selectedTime.format(dialogBuilderContext);

            return AlertDialog(
              title: const Text('Tambah Jadwal Penyiraman'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedPlantId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Tanaman',
                        border: OutlineInputBorder(),
                      ),
                      items: plants.map((plant) {
                        final item = plant as Map<String, dynamic>;
                        return DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(item['name']?.toString() ?? '-'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedPlant = plants.firstWhere(
                              (plant) =>
                                  (plant as Map<String, dynamic>)['id'] == value,
                            )
                            as Map<String, dynamic>;

                        setDialogState(() {
                          selectedPlantId = value;
                          selectedPlantName =
                              selectedPlant['name']?.toString() ?? 'Tanaman';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogBuilderContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Siram',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(formattedDate),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogBuilderContext,
                          initialTime: selectedTime,
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Jam Notifikasi',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(formattedTime),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedPlantId == null) {
                      ScaffoldMessenger.of(dialogBuilderContext).showSnackBar(
                        const SnackBar(content: Text('Silakan pilih tanaman')),
                      );
                      return;
                    }

                    final wateringDate =
                        DateFormat('yyyy-MM-dd').format(selectedDate);

                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final notificationBody =
                        'Saatnya menyiram tanaman $selectedPlantName pada pukul '
                        '${selectedTime.format(dialogBuilderContext)}';

                    Navigator.pop(dialogContext);

                    await _addSchedule(
                      plantId: selectedPlantId!,
                      wateringDate: wateringDate,
                    );

                    await NotificationService.scheduleNotification(
                      id: selectedPlantId! +
                          selectedDate.millisecondsSinceEpoch,
                      title: 'Pengingat Penyiraman',
                      body: notificationBody,
                      scheduledDateTime: scheduledDateTime,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi berhasil dijadwalkan'),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _findPlantById(dynamic plantId) async {
    final plants = await _fetchPlants();

    try {
      return plants.firstWhere(
        (plant) => (plant as Map<String, dynamic>)['id'] == plantId,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  DateTime _calculateNextWateringDate({
    required String currentWateringDate,
    required int frequencyDays,
  }) {
    final currentDate = DateTime.parse(currentWateringDate);
    return currentDate.add(Duration(days: frequencyDays));
  }

  Future<void> _markScheduleCompleted(Map<String, dynamic> schedule) async {
    final token = await _getToken();
    final dio = ApiService().dio;

    final rawDate = schedule['watering_date']?.toString() ?? '';
    final plantId = schedule['plant_id'];

    if (rawDate.isEmpty || plantId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data jadwal tidak lengkap')),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));

    final response = await dio.put(
      '/schedules/${schedule['id']}',
      data: {
        'watering_date': formattedDate,
        'status': 'completed',
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      try {
        final plant = await _findPlantById(plantId);

        if (!mounted) return;

        if (plant == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Status jadwal diperbarui, tapi data tanaman tidak ditemukan',
              ),
            ),
          );
          await _reload();
          return;
        }

        final frequency =
            plant['watering_frequency'] ??
            plant['wateringfrequency'] ??
            plant['wateringFrequency'];

        if (frequency == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Status diperbarui, tetapi frekuensi penyiraman tanaman tidak ditemukan',
              ),
            ),
          );
          await _reload();
          return;
        }

        final nextDate = _calculateNextWateringDate(
          currentWateringDate: rawDate,
          frequencyDays: int.parse(frequency.toString()),
        );

        final nextWateringDate = DateFormat('yyyy-MM-dd').format(nextDate);

        final createResponse = await dio.post(
          '/schedules',
          data: {
            'plant_id': plantId,
            'watering_date': nextWateringDate,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            validateStatus: (_) => true,
          ),
        );

        if (!mounted) return;

        if (createResponse.statusCode == 200 ||
            createResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Jadwal selesai. Jadwal berikutnya dibuat untuk $nextWateringDate',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Status selesai berhasil, tapi gagal membuat jadwal berikutnya',
              ),
            ),
          );
        }

        await _reload();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status selesai berhasil, tetapi gagal membuat jadwal baru: $e',
            ),
          ),
        );
        await _reload();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update jadwal: ${response.data}')),
      );
    }
  }

  Future<void> _deleteSchedule(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await _getToken();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus jadwal: ${response.data}')),
      );
    }
  }

  Future<void> _editScheduleDateTime(Map<String, dynamic> schedule) async {
    final token = await _getToken();
    final dio = ApiService().dio;

    final rawDate = schedule['watering_date']?.toString() ?? '';
    final initialDate = DateTime.tryParse(rawDate) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    final updatedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final formattedDate = DateFormat('yyyy-MM-dd').format(updatedDateTime);

    final response = await dio.put(
      '/schedules/${schedule['id']}',
      data: {
        'watering_date': formattedDate,
        'status': schedule['status'],
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await NotificationService.cancelNotification(schedule['id']);

      if (!mounted) return;

      await NotificationService.scheduleNotification(
        id: schedule['id'],
        title: 'Pengingat Penyiraman',
        body:
            'Saatnya menyiram tanaman ${schedule['plant_name'] ?? 'Tanaman'} '
            'pada pukul ${pickedTime.format(context)}',
        scheduledDateTime: updatedDateTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal dan jam jadwal berhasil diperbarui'),
        ),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal edit jadwal: ${response.data}')),
      );
    }
  }

  String _formatDateDisplay(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Penyiraman'),
        actions: [
          IconButton(
            onPressed: _showAddScheduleDialog,
            icon: const Icon(Icons.add),
          ),
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
                      onPressed: _showAddScheduleDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Jadwal'),
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
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
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
                              Text(
                                'Tanggal: ${_formatDateDisplay(schedule['watering_date']?.toString() ?? '-')}',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.12),
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
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editScheduleDateTime(schedule),
                            ),
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