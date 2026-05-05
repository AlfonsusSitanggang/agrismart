import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import 'package:agrismart/core/services/secure_storage_service.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  
  String _baseCurrency = 'USD';
  String _targetCurrency = 'IDR';
  bool _isLoading = false;
  
  // Variabel untuk menyimpan hasil balasan API
  double? _convertedAmount;
  double? _exchangeRate;
  String? _errorMessage;

  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY', 'GBP', 'SGD', 'MYR'];

  Future<void> _convertCurrency() async {
    final token = await SecureStorageService().getToken();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _convertedAmount = null;
    });

    try {
      final apiService = ApiService();
      
      // Mengambil inputan user
      final amount = double.tryParse(_amountController.text) ?? 1.0;

      // GET request ke backend node.js
      final response = await apiService.dio.get(
        '/proxy/exchange-rate',
        queryParameters: {
          'base': _baseCurrency,
          'target': _targetCurrency,
          'amount': amount,
        },
        options: Options(
          headers: {
            // TODO: Ganti dengan token yang didapat saat login dari Secure Storage
            'Authorization': 'Bearer $token', 
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _convertedAmount = (response.data['data']['converted_amount'] as num).toDouble();
          _exchangeRate = (response.data['data']['exchange_rate'] as num).toDouble();
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Gagal mengkonversi mata uang.';
        });
      }
    } on DioException catch (e) {
      setState(() {
        if (e.response != null) {
          _errorMessage = e.response?.data['message'] ?? 'Terjadi kesalahan dari server.';
        } else {
          _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internetmu.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Kurs AgriSmart'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Jumlah Uang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _baseCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Dari',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies.map((String currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _baseCurrency = newValue;
                        });
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.swap_horiz, size: 32),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Ke',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies.map((String currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _targetCurrency = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _convertCurrency,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Konversi', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_convertedAmount != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hasil Konversi',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_convertedAmount $_targetCurrency',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rate: 1 $_baseCurrency = $_exchangeRate $_targetCurrency',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}