import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimezonePage extends StatefulWidget {
  const TimezonePage({super.key});

  @override
  State<TimezonePage> createState() => _TimezonePageState();
}

class _TimezonePageState extends State<TimezonePage> {
  final DateTime now = DateTime.now();

  String formatTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final wib = now.toUtc().add(const Duration(hours: 7));
    final wita = now.toUtc().add(const Duration(hours: 8));
    final wit = now.toUtc().add(const Duration(hours: 9));
    final london = now.toUtc().add(const Duration(hours: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Zona Waktu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WIB  : ${formatTime(wib)}'),
            const SizedBox(height: 12),
            Text('WITA : ${formatTime(wita)}'),
            const SizedBox(height: 12),
            Text('WIT  : ${formatTime(wit)}'),
            const SizedBox(height: 12),
            Text('London : ${formatTime(london)}'),
          ],
        ),
      ),
    );
  }
}