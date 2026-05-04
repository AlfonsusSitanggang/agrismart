import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrismart/core/utils/time_helper.dart';

class WorldClockCard extends StatefulWidget {
  const WorldClockCard({super.key});

  @override
  State<WorldClockCard> createState() => _WorldClockCardState();
}

class _WorldClockCardState extends State<WorldClockCard> {
  Timer? _timer;
  String _selectedZone = 'WIB';

  final List<String> _zones = ['WIB', 'WITA', 'WIT', 'London'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final zone = prefs.getString('primary_time_zone') ?? 'WIB';

    if (!mounted) return;
    setState(() {
      _selectedZone = zone;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeHelper.formatTime(_selectedZone);
    final date = TimeHelper.formatDate(_selectedZone);
    final utc = TimeHelper.getUtcLabel(_selectedZone);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.public, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'World Clock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _zones.map((zone) {
                final isSelected = zone == _selectedZone;
                return ChoiceChip(
                  label: Text(zone),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedZone = zone;
                    });
                  },
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green.shade800 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedZone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    utc,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
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