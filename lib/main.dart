import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ONLY initialize window_manager if running on Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(500, 600),
      center: true,
      title: "NekoClock",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF67504A),
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Neko Clock!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedValue = 'No. 1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // 1. Pass the selectedValue down to the PulsingCanvas
          Positioned.fill(child: PulsingCanvas(functionName: selectedValue)),

          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ClockWidget()],
            ),
          ),
          Positioned(
            top: 20.0,
            right: 20.0,
            child: DropdownMenu<String>(
              requestFocusOnTap: false,
              initialSelection: 'No. 1',
              label: const Text('Change Background'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'No. 1', label: 'No. 1'),
                DropdownMenuEntry(value: 'No. 2', label: 'No. 2'),
              ],
              onSelected: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedValue = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: CustomPaint(painter: ClockPainter(_now)),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime dateTime;

  ClockPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.black.withAlpha(200)
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, paintCircle);

    final hourAngle =
        (dateTime.hour % 12 + dateTime.minute / 60) * 30 * (math.pi / 180);
    _drawHand(canvas, center, radius * 0.5, hourAngle, 8, Colors.white);

    final minuteAngle = (dateTime.minute) * 6 * (math.pi / 180);
    _drawHand(canvas, center, radius * 0.7, minuteAngle, 4, Colors.grey);

    final secondAngle = (dateTime.second) * 6 * (math.pi / 180);
    _drawHand(canvas, center, radius * 0.9, secondAngle, 2, Colors.red);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    double width,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = width;

    final endPointOffset = Offset(
      center.dx + length * math.sin(angle),
      center.dy - length * math.cos(angle),
    );

    canvas.drawLine(center, endPointOffset, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class PulsingCanvas extends StatefulWidget {
  final String functionName;

  const PulsingCanvas({super.key, required this.functionName});

  @override
  State<PulsingCanvas> createState() => _PulsingCanvasState();
}

class _PulsingCanvasState extends State<PulsingCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: BackgroundPainter(_controller.value, widget.functionName),
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double progress;
  final String functionName;

  BackgroundPainter(this.progress, this.functionName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    double scale = 216;

    // Draw different shapes based on the selected option
    if (functionName == 'No. 1') {
      double k = (progress - 0.5).abs() * 20;

      for (double theta = 0; theta <= 12 * math.pi; theta += 0.001) {
        double r = scale / math.sqrt(1 + math.pow(math.cos(k * theta), 2));

        double x = center.dx + r * math.cos(theta);
        double y = center.dy + r * math.sin(theta);

        if (theta == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    } else if (functionName == 'No. 2') {
      double n =
          3 + math.sin(progress * 2 * math.pi) * 5; // varies from -2 to 8

      for (double theta = math.pi; theta <= 12 * math.pi; theta += 0.01) {
        double r = scale * math.cos(n * theta);

        double x = center.dx + r * math.cos(theta);
        double y = center.dy + r * math.sin(theta);

        if (theta == math.pi) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    // Check if progress or function changed to trigger a repaint
    return oldDelegate.progress != progress ||
        oldDelegate.functionName != functionName;
  }
}
