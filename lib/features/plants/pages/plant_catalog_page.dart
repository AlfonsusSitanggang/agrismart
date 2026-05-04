import 'package:flutter/material.dart';
import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';

class PlantCatalogPage extends StatefulWidget {
  const PlantCatalogPage({super.key});

  @override
  State<PlantCatalogPage> createState() => _PlantCatalogPageState();
}

class _PlantCatalogPageState extends State<PlantCatalogPage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _plants = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlant() async {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama tanaman terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _plants = [];
    });

    try {
      final token = await SecureStorageService().getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak ditemukan');
      }

      final dio = ApiService().dio;

      final response = await dio.get(
        '/proxy/plants',
        queryParameters: {'q': keyword},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response data: ${response.data.toString()}');

      if (response.statusCode != 200) {
        throw Exception('Request gagal: ${response.statusCode}');
      }

      final result = Map<String, dynamic>.from(response.data);
      final data = result['data'];
      final plants = data['data'] as List<dynamic>;

      setState(() {
        _plants = plants;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencari tanaman: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addPlant(Map<String, dynamic> plant) {
    final commonName = plant['common_name']?.toString() ?? 'Tanaman';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$commonName berhasil ditambahkan'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Tanaman'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari tanaman, misalnya apple',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _searchPlant(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searchPlant,
                  child: const Text('Cari'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _plants.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada hasil pencarian tanaman',
                            ),
                          )
                        : ListView.builder(
                            itemCount: _plants.length,
                            itemBuilder: (context, index) {
                              final plant =
                                  _plants[index] as Map<String, dynamic>;

                              final commonName =
                                  plant['common_name']?.toString() ??
                                  'Tanaman';

                              final scientificName =
                                  plant['scientific_name'] is List &&
                                          plant['scientific_name'].isNotEmpty
                                      ? plant['scientific_name'][0].toString()
                                      : '-';

                              final imageUrl =
                                  plant['default_image']?['thumbnail']
                                      ?.toString() ??
                                  plant['default_image']?['regular_url']
                                      ?.toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    imageUrl != null && imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.local_florist,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.local_florist,
                                            ),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commonName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            scientificName,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () => _addPlant(plant),
                                            child: const Text('Tambah'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}