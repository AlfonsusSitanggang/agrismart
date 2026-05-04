import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimeHelper {
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    tz.initializeTimeZones();
    _initialized = true;
  }

  static final Map<String, String> _zoneMap = {
    'WIB': 'Asia/Jakarta',
    'WITA': 'Asia/Makassar',
    'WIT': 'Asia/Jayapura',
    'London': 'Europe/London',
  };

  static List<String> get supportedZones => _zoneMap.keys.toList();

  static tz.TZDateTime nowInZone(String zoneName) {
    init();
    final locationName = _zoneMap[zoneName];
    if (locationName == null) {
      throw Exception('Zona waktu tidak didukung: $zoneName');
    }

    final location = tz.getLocation(locationName);
    return tz.TZDateTime.now(location);
  }

  static String formatTime(String zoneName) {
    final now = nowInZone(zoneName);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  static String formatDate(String zoneName) {
    final now = nowInZone(zoneName);
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day/$month/$year';
  }

  static String getUtcLabel(String zoneName) {
    switch (zoneName) {
      case 'WIB':
        return 'UTC+7';
      case 'WITA':
        return 'UTC+8';
      case 'WIT':
        return 'UTC+9';
      case 'London':
        final londonNow = nowInZone('London');
        final offsetHours = londonNow.timeZoneOffset.inHours;
        return offsetHours >= 0 ? 'UTC+$offsetHours' : 'UTC$offsetHours';
      default:
        return '';
    }
  }
}