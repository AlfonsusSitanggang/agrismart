import 'package:agrismart/core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Halo, saya Pakar Botani. Ada yang ingin Anda tanyakan?',
      'isUser': false,
    },
  ];

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final token = await SecureStorageService().getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak ditemukan');
      }

      final dio = ApiService().dio;

      final response = await dio.post(
        '/proxy/ask-ai',
        data: {'question': text},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Request gagal: ${response.statusCode}');
      }

      final data = response.data;
      final reply =
          data['data']?['answer']?.toString() ??
          'Bot tidak memberikan jawaban.';

      setState(() {
        _messages.add({'text': reply, 'isUser': false});
      });
    } catch (e) {
      setState(() {
        _messages.add({'text': 'Terjadi kesalahan: $e', 'isUser': false});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.green.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pakar Botani'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message['text'], message['isUser']);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pakar Botani sedang mengetik...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu tentang tanaman...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
