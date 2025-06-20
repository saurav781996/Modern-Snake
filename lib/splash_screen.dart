import 'package:flutter/material.dart';
import 'snake.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _snakeTimer;
  List<Offset> snake = [Offset(5, 8), Offset(5, 9), Offset(5, 10), Offset(5, 11)];
  Offset direction = const Offset(1, 0);
  int gridSize = 12;
  Color snakeColor = Colors.greenAccent;
  // Falling bricks
  final int brickCount = 10;
  final double brickWidth = 48;
  final double brickHeight = 24;
  final double brickSpeed = 4;
  late List<double> brickX;
  late List<double> brickY;

  @override
  void initState() {
    super.initState();
    // Hide system UI for full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Initialize falling bricks
    final random = Random();
    brickX = List.generate(brickCount, (_) => random.nextDouble() * 312); // 360 - brickWidth
    brickY = List.generate(brickCount, (_) => random.nextDouble() * -400);

    // Animate snake
    _snakeTimer = Timer.periodic(const Duration(milliseconds: 120), (_) => _moveSnake());
    // Animate bricks
    Timer.periodic(const Duration(milliseconds: 30), (_) => _moveBricks());

    // Navigate to login screen after animation
    Future.delayed(const Duration(seconds: 3), () {
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _snakeTimer.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SnakeGame(),
        ),
      );
    });
  }

  void _moveSnake() {
    setState(() {
      final head = snake.last;
      Offset newHead = head + direction;
      if (newHead.dx >= gridSize) newHead = Offset(0, newHead.dy);
      if (newHead.dx < 0) newHead = Offset(gridSize - 1, newHead.dy);
      if (newHead.dy >= gridSize) newHead = Offset(newHead.dx, 0);
      if (newHead.dy < 0) newHead = Offset(newHead.dx, gridSize - 1);
      snake.add(newHead);
      snake.removeAt(0);
      // Change direction randomly for dynamic effect
      if (Random().nextDouble() > 0.8) {
        direction = [
          const Offset(1, 0),
          const Offset(-1, 0),
          const Offset(0, 1),
          const Offset(0, -1)
        ][Random().nextInt(4)];
      }
    });
  }

  void _moveBricks() {
    setState(() {
      for (int i = 0; i < brickCount; i++) {
        brickY[i] += brickSpeed;
        if (brickY[i] > 400) { // 360 + brickHeight
          brickY[i] = -brickHeight;
          brickX[i] = Random().nextDouble() * 312;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _snakeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Falling bricks
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BricksPainter(brickX, brickY, brickWidth, brickHeight),
              ),
            ),
          ),
          // Playful glowing background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Colors.black, Colors.deepPurple, Colors.black],
                ),
              ),
            ),
          ),
          // Animated snake grid
          Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: CustomPaint(
                painter: _SnakePainter(snake, gridSize, snakeColor),
              ),
            ),
          ),
          // Glowing game title
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 320),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Colors.orange, Colors.yellow, Colors.deepOrange],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'SNAKE GAME',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 18, color: Colors.orange, offset: Offset(0, 0)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _animation,
                  child: const Text(
                    'Get Ready...',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final int gridSize;
  final Color snakeColor;
  _SnakePainter(this.snake, this.gridSize, this.snakeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;
    final paint = Paint()
      ..color = snakeColor
      ..style = PaintingStyle.fill;
    for (final pos in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx * cellSize, pos.dy * cellSize, cellSize, cellSize),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BricksPainter extends CustomPainter {
  final List<double> brickX;
  final List<double> brickY;
  final double brickWidth;
  final double brickHeight;
  _BricksPainter(this.brickX, this.brickY, this.brickWidth, this.brickHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[700]!
      ..style = PaintingStyle.fill;
    for (int i = 0; i < brickX.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(brickX[i], brickY[i], brickWidth, brickHeight),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 