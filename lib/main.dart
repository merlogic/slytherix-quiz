import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SnakePage(),
    );
  }
}

class Question {
  final String text;
  final String correct;
  final List<String> wrongs;
  final String difficulty;
  Question(this.text, this.correct, this.wrongs, this.difficulty);
}

enum Direction { up, down, left, right }

class SnakePage extends StatefulWidget {
  const SnakePage({super.key});

  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage> {
  final int rows = 16;
  final int cols = 16;
  final FocusNode _focusNode = FocusNode();

  final List<Question> questionBank = [
    // EASY
    Question("Who was the 1st US President?", "Washington", ["Lincoln", "Jefferson"], "EASY"),
    Question("What is 5 + 7?", "12", ["10", "13"], "EASY"),
    Question("Color of an Emerald?", "Green", ["Red", "Blue"], "EASY"),
    Question("What planet is known as the Red Planet?", "Mars", ["Venus", "Jupiter"], "EASY"),
    Question("How many legs does a spider have?", "8", ["6", "10"], "EASY"),
    Question("Frozen form of water?", "Ice", ["Air", "Salt"], "EASY"),
    
    // MEDIUM
    Question("Year WWII ended?", "1945", ["1918", "1950"], "MEDIUM"),
    Question("Who painted the Mona Lisa?", "Da Vinci", ["Picasso", "Van Gogh"], "MEDIUM"),
    Question("Capital of Japan?", "Tokyo", ["Kyoto", "Osaka"], "MEDIUM"),
    Question("Chemical symbol for Gold?", "Au", ["Ag", "Gd"], "MEDIUM"),
    Question("Which ocean is the largest?", "Pacific", ["Atlantic", "Indian"], "MEDIUM"),
    Question("Square root of 144?", "12", ["14", "11"], "MEDIUM"),
    
    // HARD
    Question("First man on the moon?", "Armstrong", ["Aldrin", "Gagarin"], "HARD"),
    Question("Who wrote 'The Odyssey'?", "Homer", ["Virgil", "Socrates"], "HARD"),
    Question("Smallest bone in the human body?", "Stapes", ["Femur", "Ulna"], "HARD"),
    Question("Currency used in South Korea?", "Won", ["Yen", "Yuan"], "HARD"),
    Question("Atomic number 1?", "Hydrogen", ["Helium", "Oxygen"], "HARD"),
    Question("Largest desert in the world?", "Antarctica", ["Sahara", "Gobi"], "HARD"),
  ];

  late Question currentQuestion;
  Map<int, String> activeAnswers = {};
  List<int> snake = [45, 44, 43];
  Direction direction = Direction.right;
  bool isPlaying = false;
  bool isPausedForReading = false; 
  
  Timer? gameTimer;
  Timer? quizTimer;
  int score = 0;
  int timeLeft = 12;
  int readCountdown = 3;

  @override
  void dispose() {
    _focusNode.dispose();
    gameTimer?.cancel();
    quizTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      snake = [45, 44, 43];
      direction = Direction.right;
      score = 0;
      isPlaying = true;
      nextQuestion();
    });
  }

  void startHeadStart() {
    gameTimer?.cancel();
    quizTimer?.cancel();
    setState(() {
      isPausedForReading = true;
      readCountdown = 3;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (readCountdown > 1) {
          readCountdown--;
        } else {
          timer.cancel();
          isPausedForReading = false;
          _resumeGameLoop();
        }
      });
    });
  }

  void _resumeGameLoop() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 180), (_) => updateGame());
    _resetQuizTimer();
  }

  void _resetQuizTimer() {
    quizTimer?.cancel();
    setState(() => timeLeft = 12);
    quizTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          gameOver("TIME'S UP!");
        }
      });
    });
  }

  void nextQuestion() {
    List<Question> filtered;
    if (score < 40) {
      filtered = questionBank.where((q) => q.difficulty == "EASY").toList();
    } else if (score < 100) {
      filtered = questionBank.where((q) => q.difficulty == "MEDIUM").toList();
    } else {
      filtered = questionBank.where((q) => q.difficulty == "HARD").toList();
    }

    currentQuestion = filtered[Random().nextInt(filtered.length)];
    activeAnswers.clear();

    List<int> availableSpots = List.generate(rows * cols, (i) => i);
    availableSpots.removeWhere((i) => snake.contains(i));
    availableSpots.shuffle();

    // Shuffle options so "A" isn't always correct
    List<String> options = [currentQuestion.correct, ...currentQuestion.wrongs];
    options.shuffle();

    // Map A, B, C strings to random positions
    for (int i = 0; i < options.length; i++) {
      activeAnswers[availableSpots[i]] = options[i];
    }
    
    if (isPlaying) startHeadStart();
  }

  void updateGame() {
    if (!isPlaying || isPausedForReading) return;

    setState(() {
      int head = snake.first;
      switch (direction) {
        case Direction.up: head -= cols; break;
        case Direction.down: head += cols; break;
        case Direction.left: head -= 1; break;
        case Direction.right: head += 1; break;
      }

      bool hitWall = head < 0 || head >= rows * cols ||
          (direction == Direction.left && (head + 1) % cols == 0) ||
          (direction == Direction.right && head % cols == 0);

      if (snake.contains(head) || hitWall) {
        gameOver("YOU DIED!");
        return;
      }

      if (activeAnswers.containsKey(head)) {
        if (activeAnswers[head] == currentQuestion.correct) {
          score += 20;
          snake.insert(0, head); 
          nextQuestion();
          HapticFeedback.mediumImpact();
        } else {
          gameOver("WRONG! Correct: ${currentQuestion.correct}");
          return;
        }
      } else {
        snake.insert(0, head);
        snake.removeLast();
      }
    });
  }

  void gameOver(String msg) {
    setState(() => isPlaying = false);
    gameTimer?.cancel();
    quizTimer?.cancel();
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("GAME OVER", textAlign: TextAlign.center),
        content: Text("$msg\n\nFinal Score: $score", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: () { Navigator.pop(context); startGame(); },
              child: const Text("TRY AGAIN"),
            ),
          )
        ],
      ),
    );
  }

  void handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) changeDirection(Direction.up);
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) changeDirection(Direction.down);
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) changeDirection(Direction.left);
      if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) changeDirection(Direction.right);
    }
  }

  void changeDirection(Direction d) {
    if (isPausedForReading) return;
    if (d == Direction.up && direction == Direction.down) return;
    if (d == Direction.down && direction == Direction.up) return;
    if (d == Direction.left && direction == Direction.right) return;
    if (d == Direction.right && direction == Direction.left) return;
    setState(() => direction = d);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTriviaHeader(),
                _buildGameBoard(),
                _buildXboxController(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriviaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SCORE: $score", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (isPlaying) Text(currentQuestion.difficulty, style: TextStyle(color: _getDiffColor(), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildTimerBadge(),
            ],
          ),
          const Divider(color: Colors.white10, height: 15),
          Text(
            isPlaying ? currentQuestion.text : "SELECT START BUTTON TO PLAY",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          if (isPlaying) 
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(activeAnswers.length, (index) {
                String label = String.fromCharCode(65 + index); // A, B, C
                String answerText = activeAnswers.values.elementAt(index);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$label:", 
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(answerText, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Color _getDiffColor() {
    if (currentQuestion.difficulty == "EASY") return Colors.greenAccent;
    if (currentQuestion.difficulty == "MEDIUM") return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPausedForReading ? Colors.blueAccent : (timeLeft <= 3 ? Colors.red : Colors.orangeAccent.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPausedForReading ? "ARE YOU READY?" : "TIME: $timeLeft", 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
      ),
    );
  }

  Widget _buildGameBoard() {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                  itemCount: rows * cols,
                  itemBuilder: (context, index) {
                    bool isHead = snake.isNotEmpty && snake.first == index;
                    bool isBody = snake.contains(index);
                    bool isAnswer = activeAnswers.containsKey(index);
                    
                    String choiceLabel = "";
                    if (isAnswer) {
                      // Get index position in the map to assign A, B, or C
                      int pos = activeAnswers.keys.toList().indexOf(index);
                      choiceLabel = String.fromCharCode(65 + pos);
                    }

                    return Container(
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: isHead 
                            ? Colors.cyanAccent 
                            : isBody 
                                ? Colors.cyanAccent.withOpacity(0.3) 
                                : isAnswer 
                                    ? Colors.redAccent.withOpacity(0.25)
                                    : Colors.transparent,
                        borderRadius: BorderRadius.circular(isAnswer ? 8 : 2),
                      ),
                      child: isAnswer 
                        ? Center(
                            child: Text(
                              choiceLabel, 
                              style: const TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                              )
                            )
                          ) 
                        : null,
                    );
                  },
                ),
              ),
              if (isPausedForReading)
                Center(
                  child: Text(
                    "$readCountdown",
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXboxController() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 140, width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 0, child: _dPadBtn(Icons.arrow_drop_up, Direction.up)),
                  Positioned(bottom: 0, child: _dPadBtn(Icons.arrow_drop_down, Direction.down)),
                  Positioned(left: 0, child: _dPadBtn(Icons.arrow_left, Direction.left)),
                  Positioned(right: 0, child: _dPadBtn(Icons.arrow_right, Direction.right)),
                ],
              ),
            ),
            GestureDetector(
              onTap: isPlaying ? null : startGame,
              child: Container(
                height: 80, width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10)],
                ),
                child: Center(child: Text(isPlaying ? "LIVE" : "START", style: const TextStyle(fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dPadBtn(IconData icon, Direction d) {
    bool active = direction == d;
    return GestureDetector(
      onTapDown: (_) => changeDirection(d),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 30, color: active ? Colors.black : Colors.white),
      ),
    );
  }
}