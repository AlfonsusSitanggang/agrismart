import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  late Future<List<dynamic>> _plantsFuture;

  @override
  void initState() {
    super.initState();
    _plantsFuture = _fetchPlants();
  }

  Future<void> _addDummyPlant() async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.post(
      '/plants',
      data: {
        'name': 'Cabai',
        'species': 'Capsicum annuum',
        'watering_frequency': 2,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanaman berhasil ditambahkan')),
      );
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal tambah tanaman: ${response.data}')),
      );
    }
  }

  Future<List<dynamic>> _fetchPlants() async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

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
        'Request gagal: ${response.statusCode} - ${response.data}',
      );
    }

    final result = Map<String, dynamic>.from(response.data);
    return result['data'] as List<dynamic>;
  }

  Future<void> _reload() async {
    setState(() {
      _plantsFuture = _fetchPlants();
    });
  }

  Future<void> _showEditPlantDialog(Map<String, dynamic> plant) async {
    final nameController = TextEditingController(
      text: plant['name']?.toString() ?? '',
    );
    final speciesController = TextEditingController(
      text: plant['species']?.toString() ?? '',
    );
    final frequencyController = TextEditingController(
      text: plant['watering_frequency']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Tanaman'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: speciesController,
                  decoration: const InputDecoration(labelText: 'Spesies'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frekuensi siram (hari)',
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
                final frequency = int.tryParse(frequencyController.text.trim());

                if (nameController.text.trim().isEmpty || frequency == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama dan frekuensi siram wajib valid'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                await _updatePlant(
                  id: plant['id'],
                  name: nameController.text.trim(),
                  species: speciesController.text.trim(),
                  wateringFrequency: frequency,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePlant({
    required dynamic id,
    required String name,
    required String species,
    required int wateringFrequency,
  }) async {
    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.put(
      '/plants/$id',
      data: {
        'name': name,
        'species': species.isEmpty ? null : species,
        'watering_frequency': wateringFrequency,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanaman berhasil diperbarui')),
      );
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update tanaman: ${response.data}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanaman Saya'),
        actions: [
          IconButton(onPressed: _addDummyPlant, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _plantsFuture,
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
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

          final plants = snapshot.data!;

          if (plants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_florist_outlined,
                      size: 72,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada tanaman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan tanaman pertama Anda untuk mulai mengelola penyiraman.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addDummyPlant,
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
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index] as Map<String, dynamic>;

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
                          backgroundColor: Colors.green.withOpacity(0.12),
                          child: const Icon(
                            Icons.local_florist,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant['name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Spesies: ${plant['species']?.toString() ?? '-'}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Siram tiap ${plant['watering_frequency']?.toString() ?? '-'} hari',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditPlantDialog(plant),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePlant(plant['id']),
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

  Future<bool> _showDeleteConfirmation({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(Icons.delete_outline, color: Colors.red),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Konfirmasi Hapus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            '$title\n\n$message',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete),
              label: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deletePlant(dynamic id) async {
    final confirm = await _showDeleteConfirmation(
      title: 'Hapus tanaman ini?',
      message: 'Data tanaman yang dihapus tidak bisa dikembalikan.',
    );

    if (!confirm) return;

    final token = await SecureStorageService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan');
    }

    final dio = ApiService().dio;

    final response = await dio.delete(
      '/plants/$id',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tanaman berhasil dihapus')));
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus tanaman: ${response.data}')),
      );
    }
  }
}
