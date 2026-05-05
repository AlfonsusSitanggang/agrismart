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

  String _toBackendDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  DateTime? _parseServerDate(String rawDate) {
    try {
      return DateTime.tryParse(rawDate);
    } catch (_) {
      return null;
    }
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
    return List<dynamic>.from(result['data'] ?? []);
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
    return List<dynamic>.from(result['data'] ?? []);
  }

  Future<void> _reload() async {
    setState(() {
      _schedulesFuture = _fetchSchedules();
    });
    await _schedulesFuture;
  }

  Future<void> _addSchedule({
    required int plantId,
    required DateTime scheduledDateTime,
  }) async {
    final token = await _getToken();
    final dio = ApiService().dio;

    final response = await dio.post(
      '/schedules',
      data: {
        'plant_id': plantId,
        'watering_date': _toBackendDateTime(scheduledDateTime),
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseMap = Map<String, dynamic>.from(response.data);
      final newSchedule = Map<String, dynamic>.from(responseMap['data'] ?? {});

      final scheduleId =
          int.tryParse(newSchedule['id']?.toString() ?? '') ??
          (scheduledDateTime.millisecondsSinceEpoch ~/ 1000);

      await NotificationService.scheduleNotification(
        id: scheduleId,
        title: 'Pengingat Penyiraman',
        body:
            'Saatnya menyiram tanaman pada pukul ${DateFormat('HH:mm').format(scheduledDateTime)}',
        scheduledDateTime: scheduledDateTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal & notifikasi berhasil ditambahkan'),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil tanaman: $e')));
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
                      value: selectedPlantId,
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
                        setDialogState(() {
                          selectedPlantId = value;
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

                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (scheduledDateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(dialogBuilderContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Waktu jadwal tidak boleh di masa lalu',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    await _addSchedule(
                      plantId: selectedPlantId!,
                      scheduledDateTime: scheduledDateTime,
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
          )
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  DateTime _calculateNextWateringDate({
    required String currentWateringDate,
    required int frequencyDays,
  }) {
    final currentDate = _parseServerDate(currentWateringDate) ?? DateTime.now();
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

    final parsedRawDate = _parseServerDate(rawDate);
    if (parsedRawDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format tanggal jadwal tidak valid')),
      );
      return;
    }

    final response = await dio.put(
      '/schedules/${schedule['id']}',
      data: {
        'watering_date': _toBackendDateTime(parsedRawDate),
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
        await NotificationService.cancelNotification(schedule['id']);

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

        final createResponse = await dio.post(
          '/schedules',
          data: {
            'plant_id': plantId,
            'watering_date': _toBackendDateTime(nextDate),
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            validateStatus: (_) => true,
          ),
        );

        if (!mounted) return;

        if (createResponse.statusCode == 200 ||
            createResponse.statusCode == 201) {
          final createMap = Map<String, dynamic>.from(createResponse.data);
          final nextSchedule = Map<String, dynamic>.from(
            createMap['data'] ?? {},
          );
          final nextScheduleId =
              int.tryParse(nextSchedule['id']?.toString() ?? '') ??
              (nextDate.millisecondsSinceEpoch ~/ 1000);

          await NotificationService.scheduleNotification(
            id: nextScheduleId,
            title: 'Pengingat Penyiraman',
            body:
                'Saatnya menyiram tanaman lagi pada pukul ${DateFormat('HH:mm').format(nextDate)}',
            scheduledDateTime: nextDate,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Jadwal selesai. Jadwal berikutnya dibuat untuk ${DateFormat('dd MMM yyyy HH:mm').format(nextDate)}',
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
      await NotificationService.cancelNotification(id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jadwal berhasil dihapus')));
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
    final initialDate = _parseServerDate(rawDate) ?? DateTime.now();

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

    final response = await dio.put(
      '/schedules/${schedule['id']}',
      data: {
        'watering_date': _toBackendDateTime(updatedDateTime),
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

      await NotificationService.scheduleNotification(
        id: schedule['id'],
        title: 'Pengingat Penyiraman',
        body:
            'Saatnya menyiram tanaman ${schedule['plant_name'] ?? 'Tanaman'} pada pukul ${DateFormat('HH:mm').format(updatedDateTime)}',
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
    final parsed = _parseServerDate(rawDate);
    if (parsed == null) return rawDate;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _formatTimeDisplay(String rawDate) {
    final parsed = _parseServerDate(rawDate);
    if (parsed == null) return '-';
    return DateFormat('HH:mm').format(parsed);
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

          final schedules = snapshot.data ?? [];

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
                              Text(
                                'Tanggal: ${_formatDateDisplay(schedule['watering_date']?.toString() ?? '-')}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jam: ${_formatTimeDisplay(schedule['watering_date']?.toString() ?? '-')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
