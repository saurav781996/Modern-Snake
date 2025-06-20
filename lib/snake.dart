import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with SingleTickerProviderStateMixin {
  static List<int> snakePosition = [45, 65, 85, 105, 125];
  late int numberOfSquares;
  late int columns;
  late int rows;
  static var randomNumber = Random();
  List<int> foods = [];
  List<Color> foodColors = [];
  Color snakeColor = Colors.green;
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
    Colors.teal,
    Colors.lime,
    Colors.amber,
    Colors.deepOrange,
    Colors.indigo,
    Colors.lightGreen,
    Colors.deepPurple,
  ];
  List<int> obstacles = [];
  bool hardMode = false;
  int wallSegments = 5;
  int wallLength = 4;
  var direction = 'down';
  var score = 0;
  var highScore = 0;
  bool isPlaying = false;
  bool isPaused = false;
  Timer? timer;
  late AnimationController _controller;
  late Animation<double> _animation;
  String difficulty = 'Normal';
  double gameSpeed = 300;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    loadHighScore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateNewFoods();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: snakeColor,
        statusBarIconBrightness: Brightness.light,
      ));
    });
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void startGame() {
    Duration duration = Duration(milliseconds: gameSpeed.toInt());
    timer = Timer.periodic(duration, (Timer timer) {
      if (!isPaused) {
        moveSnake();
        if (checkGameOver()) {
          timer.cancel();
          endGame();
        }
      }
    });
  }

  void generateNewFoods() {
    foods.clear();
    foodColors.clear();
    while (foods.length < 5) {
      int newFood = randomNumber.nextInt(numberOfSquares);
      if (!snakePosition.contains(newFood) && !foods.contains(newFood)) {
        foods.add(newFood);
        foodColors.add(availableColors[randomNumber.nextInt(availableColors.length)]);
      }
    }
  }

  void generateObstacles() {
    obstacles.clear();
    int attempts = 0;
    while (obstacles.length < wallSegments * wallLength && attempts < 1000) {
      attempts++;
      // Randomly choose horizontal or vertical
      bool horizontal = randomNumber.nextBool();
      int start;
      List<int> segment = [];
      if (horizontal) {
        int row = randomNumber.nextInt(rows);
        int col = randomNumber.nextInt(columns - wallLength);
        start = row * columns + col;
        segment = List.generate(wallLength, (i) => start + i);
      } else {
        int row = randomNumber.nextInt(rows - wallLength);
        int col = randomNumber.nextInt(columns);
        start = row * columns + col;
        segment = List.generate(wallLength, (i) => start + i * columns);
      }
      // Check for overlap
      if (segment.any((cell) => snakePosition.contains(cell) || foods.contains(cell) || obstacles.contains(cell))) {
        continue;
      }
      obstacles.addAll(segment);
    }
  }

  void moveSnake() {
    setState(() {
      switch (direction) {
        case 'down':
          if (difficulty == 'Low') {
            if (snakePosition.last > (numberOfSquares - columns)) {
              snakePosition.add(snakePosition.last % columns);
            } else {
              snakePosition.add(snakePosition.last + columns);
            }
          } else {
            if (snakePosition.last > (numberOfSquares - columns)) {
              endGame('boundary');
              return;
            }
            snakePosition.add(snakePosition.last + columns);
          }
          break;
        case 'up':
          if (difficulty == 'Low') {
            if (snakePosition.last < columns) {
              snakePosition.add(snakePosition.last + numberOfSquares - columns);
            } else {
              snakePosition.add(snakePosition.last - columns);
            }
          } else {
            if (snakePosition.last < columns) {
              endGame('boundary');
              return;
            }
            snakePosition.add(snakePosition.last - columns);
          }
          break;
        case 'left':
          if (difficulty == 'Low') {
            if (snakePosition.last % columns == 0) {
              snakePosition.add(snakePosition.last + columns - 1);
            } else {
              snakePosition.add(snakePosition.last - 1);
            }
          } else {
            if (snakePosition.last % columns == 0) {
              endGame('boundary');
              return;
            }
            snakePosition.add(snakePosition.last - 1);
          }
          break;
        case 'right':
          if (difficulty == 'Low') {
            if ((snakePosition.last + 1) % columns == 0) {
              snakePosition.add(snakePosition.last - columns + 1);
            } else {
              snakePosition.add(snakePosition.last + 1);
            }
          } else {
            if ((snakePosition.last + 1) % columns == 0) {
              endGame('boundary');
              return;
            }
            snakePosition.add(snakePosition.last + 1);
          }
          break;
      }
      if (foods.contains(snakePosition.last)) {
        score++;
        _controller.forward(from: 0.0);
        int foodIndex = foods.indexOf(snakePosition.last);
        foods.removeAt(foodIndex);
        foodColors.removeAt(foodIndex);
        snakeColor = availableColors[randomNumber.nextInt(availableColors.length)];
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: snakeColor,
          statusBarIconBrightness: Brightness.light,
        ));
        while (foods.length < 5) {
          int newFood = randomNumber.nextInt(numberOfSquares);
          if (!snakePosition.contains(newFood) && !foods.contains(newFood)) {
            foods.add(newFood);
            foodColors.add(availableColors[randomNumber.nextInt(availableColors.length)]);
          }
        }
        saveHighScore();
      } else {
        snakePosition.removeAt(0);
      }
      if (hardMode && obstacles.contains(snakePosition.last)) {
        endGame('obstacle');
        return;
      }
    });
  }

  bool checkGameOver() {
    for (int i = 0; i < snakePosition.length - 1; i++) {
      if (snakePosition.last == snakePosition[i]) {
        return true;
      }
    }
    return false;
  }

  void setDifficulty(String newDifficulty) {
    setState(() {
      difficulty = newDifficulty;
      switch (newDifficulty) {
        case 'Easy':
          gameSpeed = 500;
          break;
        case 'Normal':
          gameSpeed = 300;
          break;
        case 'Hard':
          gameSpeed = 150;
          break;
      }
      // Restart timer with new speed
      timer?.cancel();
      startGame();
    });
  }

  void endGame([String reason = 'self']) {
    timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.92),
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Game Over',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                color: Colors.deepOrange,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'High Score: $highScore',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Snake collided with ${reason == 'boundary' ? 'the boundary' : reason == 'obstacle' ? 'a brick' : 'itself'}!',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepOrange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Colors.white.withOpacity(0.92),
              ),
              child: const Text(
                'Play Again',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      snakePosition = [45, 65, 85, 105, 125];
      direction = 'down';
      score = 0;
      isPaused = false;
      generateNewFoods();
      if (hardMode) generateObstacles();
    });
    startGame();
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    columns = 20;
    double cellSize = screenWidth / columns;
    rows = (screenHeight / cellSize).floor();
    numberOfSquares = columns * rows;

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.deepOrange, size: 28),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score: $score',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Difficulty: ',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    difficulty,
                                    style: TextStyle(
                                      color: difficulty == 'Hard'
                                          ? Colors.red
                                          : (difficulty == 'Normal'
                                              ? Colors.orange
                                              : Colors.green),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'High: $highScore',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (isPlaying) {
                                  togglePause();
                                } else {
                                  setState(() {
                                    isPlaying = true;
                                  });
                                  startGame();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPlaying
                                      ? (isPaused ? Icons.play_arrow : Icons.pause)
                                      : Icons.play_arrow,
                                  color: Colors.deepOrange,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white.withOpacity(0.92),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: const Text(
                                        'Select Difficulty',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: const Text('Low', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                            onTap: () {
                                              setState(() { gameSpeed = 500; hardMode = false; difficulty = 'Low'; });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Normal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                            onTap: () {
                                              setState(() { gameSpeed = 300; hardMode = false; difficulty = 'Normal'; });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Hard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                            onTap: () {
                                              setState(() { gameSpeed = 150; hardMode = true; difficulty = 'Hard'; generateObstacles(); });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.deepOrange,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (direction != 'up' && details.delta.dy > 0) {
                      direction = 'down';
                    } else if (direction != 'down' && details.delta.dy < 0) {
                      direction = 'up';
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (direction != 'left' && details.delta.dx > 0) {
                      direction = 'right';
                    } else if (direction != 'right' && details.delta.dx < 0) {
                      direction = 'left';
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                      ),
                      itemCount: numberOfSquares,
                      itemBuilder: (BuildContext context, int index) {
                        // Check if the position is a boundary
                        bool isBoundary = 
                          index < columns || // top boundary
                          index >= numberOfSquares - columns || // bottom boundary
                          index % columns == 0 || // left boundary
                          (index + 1) % columns == 0; // right boundary

                        if (isBoundary) {
                          Color boundaryColor = (difficulty == 'Low') ? Colors.green : Colors.red;
                          return Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: boundaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: boundaryColor.withOpacity(0.5),
                                width: 4,
                              ),
                            ),
                          );
                        }
                        if (hardMode && obstacles.contains(index)) {
                          return Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.brown[700],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.brown, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        }
                        if (snakePosition.contains(index)) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: snakeColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: snakeColor.withOpacity(0.3),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        if (foods.contains(index)) {
                          int foodIdx = foods.indexOf(index);
                          Color foodColor = foodColors[foodIdx];
                          return ScaleTransition(
                            scale: _animation,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: foodColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: foodColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: foodColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              color: Colors.grey[900],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isPlaying)
                      ElevatedButton.icon(
                        onPressed: () {
                          isPlaying = true;
                          startGame();
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.black87),
                        label: const Text('Start Game',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}