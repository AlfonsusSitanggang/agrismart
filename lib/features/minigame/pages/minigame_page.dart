import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MinigamePage extends StatefulWidget {
  const MinigamePage({Key? key}) : super(key: key);

  @override
  State<MinigamePage> createState() => _MinigamePageState();
}

class _MinigamePageState extends State<MinigamePage> {
  int level = 1;
  int water = 0;

  // SENSOR
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  double lastX = 0, lastY = 0, lastZ = 0;
  final double shakeThreshold = 15.0;

  // ANIMASI
  double tilt = 0.0;
  List<Widget> leaves = [];

  @override
  void initState() {
    super.initState();
    loadData();
    startSensors();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  // ========================
  // LOCAL STORAGE
  // ========================
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      level = prefs.getInt('tree_level') ?? 1;
      water = prefs.getInt('tree_water') ?? 0;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tree_level', level);
    await prefs.setInt('tree_water', water);
  }

  // ========================
  // SENSOR LOGIC
  // ========================
  void startSensors() {
    // ACCELEROMETER (SHAKE)
    _accelSub = accelerometerEvents.listen((event) {
      double deltaX = (event.x - lastX).abs();
      double deltaY = (event.y - lastY).abs();
      double deltaZ = (event.z - lastZ).abs();

      if (deltaX + deltaY + deltaZ > shakeThreshold) {
        onShake();
      }

      lastX = event.x;
      lastY = event.y;
      lastZ = event.z;
    });

    // GYROSCOPE (GOYANG POHON)
    _gyroSub = gyroscopeEvents.listen((event) {
      setState(() {
        tilt = (tilt + event.y) / 2;
        tilt = tilt.clamp(-1.0, 1.0);
      });

      if (event.y.abs() > 2) {
        spawnLeaf();
      }
    });
  }

  // ========================
  // GAME LOGIC
  // ========================
  void onShake() {
    setState(() {
      water += 10;

      if (water >= 100) {
        level++;
        water = 0;
      }
    });

    saveData();
  }

  // ========================
  // LEAF ANIMATION
  // ========================
  void spawnLeaf() {
    final random = Random();
    final id = DateTime.now().millisecondsSinceEpoch;

    final leaf = _LeafWidget(
      key: ValueKey(id),
      startX: random.nextDouble() * 250,
      onEnd: () {
        setState(() {
          leaves.removeWhere((w) => (w.key as ValueKey).value == id);
        });
      },
    );

    setState(() {
      leaves.add(leaf);
    });
  }

  // ========================
  // UI
  // ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🌳 Pohon Virtual")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Level Tanaman", style: TextStyle(fontSize: 20)),
            Text(
              "$level",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            Text("Air: $water / 100"),

            const SizedBox(height: 30),

            // 🌳 POHON + DAUN
            SizedBox(
              height: 300,
              width: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...leaves,

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.rotationZ(tilt * 0.2),
                    child: Icon(
                      Icons.park,
                      size: 100 + (level * 5).toDouble(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Goyangkan HP untuk menyiram 💧"),
            const Text("Miringkan HP untuk menggoyang pohon 🌳"),
          ],
        ),
      ),
    );
  }
}

// ========================
// WIDGET DAUN JATUH
// ========================
class _LeafWidget extends StatefulWidget {
  final double startX;
  final VoidCallback onEnd;

  const _LeafWidget({Key? key, required this.startX, required this.onEnd})
    : super(key: key);

  @override
  State<_LeafWidget> createState() => _LeafWidgetState();
}

class _LeafWidgetState extends State<_LeafWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fall;
  late Animation<double> rotate;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    fall = Tween(begin: 0.0, end: 300.0).animate(controller);
    rotate = Tween(begin: 0.0, end: 2 * pi).animate(controller);

    controller.forward();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEnd();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          top: fall.value,
          left: widget.startX + sin(fall.value / 50) * 20,
          child: Transform.rotate(
            angle: rotate.value,
            child: const Icon(Icons.eco, color: Colors.green, size: 20),
          ),
        );
      },
    );
  }
}
