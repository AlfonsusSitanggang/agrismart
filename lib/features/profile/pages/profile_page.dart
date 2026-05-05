import 'dart:io';
import 'package:agrismart/core/constants/api_constants.dart';
import 'package:agrismart/core/services/profile_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _service = ProfileService();

  String name = "";
  String email = "";
  String? photo;
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _service.getProfile();

      if (!mounted) return;

      setState(() {
        name = data['data']['name']?.toString() ?? '';
        email = data['data']['email']?.toString() ?? '';
        photo = data['data']['profile_picture']?.toString();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal ambil data profile")));
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    try {
      if (mounted) {
        setState(() {
          isUploading = true;
        });
      }

      await _service.uploadPhoto(File(picked.path));
      await fetchProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diperbarui")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload gagal: $e")));
    } finally {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SecureStorageService().deleteToken();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imageUrl = (photo != null && photo!.isNotEmpty)
        ? "${ApiConstants.baseUrl.replaceAll('/api', '')}/uploads/$photo"
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================
          // PROFILE CARD
          // =========================
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: isUploading ? null : pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: imageUrl != null
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.green,
                                )
                              : null,
                        ),
                      ),

                      if (isUploading)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: isUploading ? null : pickAndUploadImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Ubah Foto"),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    name.isEmpty ? "Nama User" : name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email.isEmpty ? "Email tidak tersedia" : email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // KESAN & PESAN
          // =========================
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Kesan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Mata kuliah TPM memberikan kesan yang mendalam bagi kami, terutama kesan pressure yang tinggi dan banyaknya surprise yang diberikan, sehingga membuat kami harus beradaptasi secara cepat dan tidak mengeluh.",
                    style: TextStyle(height: 1.5),
                  ),

                  SizedBox(height: 16),

                  Text(
                    "Pesan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Karena kesempurnaan itu hanya milik Tuhan semata, jadi kami mempunyai pesan untuk mata kuliah TPM ini, yaitu alangkah baiknya jika tugas dan project menjadi terstruktur baik waktu maupun syarat yang diperlukan sehingga mahasiswa tidak kaget dan bisa lebih prepare.",
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // LOGOUT BUTTON
          // =========================
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
