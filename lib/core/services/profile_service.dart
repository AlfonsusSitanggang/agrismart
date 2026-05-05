import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:agrismart/core/constants/api_constants.dart';

class ProfileService {
  final String baseUrl = "${ApiConstants.baseUrl}/auth";

  Future<Map<String, dynamic>> getProfile() async {
    final token = await SecureStorageService().getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    print("PROFILE STATUS: ${res.statusCode}");
    print("PROFILE BODY: ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Gagal ambil profile");
    }
  }

  Future<void> uploadPhoto(File imageFile) async {
    final token = await SecureStorageService().getToken();

    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    print("UPLOAD STATUS: ${streamedResponse.statusCode}");
    print("UPLOAD BODY: $responseBody");

    Map<String, dynamic> data = {};

    try {
      if (responseBody.isNotEmpty) {
        data = jsonDecode(responseBody);
      }
    } catch (e) {
      throw Exception(
        "Response backend bukan JSON. Status: ${streamedResponse.statusCode}, Body: $responseBody",
      );
    }

    if (streamedResponse.statusCode != 200) {
      throw Exception(data['message'] ?? "Upload gagal");
    }
  }
}
