import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PongGame());
}

class PongGame extends StatelessWidget {
  const PongGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Pong',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const PongScreen(),
    );
  }
}

class PongScreen extends StatefulWidget {
  const PongScreen({Key? key}) : super(key: key);

  @override
  _PongScreenState createState() => _PongScreenState();
}

class _PongScreenState extends State<PongScreen> {
  // Game state
  bool gameStarted = false;
  int playerScore = 0;
  int aiScore = 0;

  // Game dimensions
  late double screenWidth;
  late double screenHeight;
  double gameAreaHeight = 0;

  // Paddle properties
  double paddleWidth = 15;
  double paddleHeight = 80;
  double playerPaddleY = 0;
  double aiPaddleY = 0;
  double paddleSpeed = 10;

  // Ball properties
  double ballSize = 15;
  double ballX = 0;
  double ballY = 0;
  double ballSpeedX = 4;
  double ballSpeedY = 4;

  // Controller for game loop
  Timer? gameTimer;

  // Focus node for keyboard inputs
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard inputs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void resetGame() {
    setState(() {
      gameStarted = false;
      ballX = screenWidth / 2;
      ballY = gameAreaHeight / 2;
      playerPaddleY = (gameAreaHeight - paddleHeight) / 2;
      aiPaddleY = (gameAreaHeight - paddleHeight) / 2;

      // Randomize initial ball direction
      final random = math.Random();
      ballSpeedX = (random.nextBool() ? 4 : -4) * (1 + random.nextDouble());
      ballSpeedY = (random.nextBool() ? 4 : -4) * (random.nextDouble() + 0.5);
    });
  }

  void startGame() {
    if (gameStarted) return;

    resetGame();
    setState(() {
      gameStarted = true;
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (!gameStarted) return;

    setState(() {
      // Move ball
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      // Ball collision with top and bottom
      if (ballY <= 0 || ballY >= gameAreaHeight - ballSize) {
        ballSpeedY = -ballSpeedY;
      }

      // Ball collision with paddles
      if (ballX <= paddleWidth &&
          ballY + ballSize >= playerPaddleY &&
          ballY <= playerPaddleY + paddleHeight) {
        // Calculate bounce angle based on where ball hits paddle
        double relativeIntersectY = (playerPaddleY + (paddleHeight / 2)) - (ballY + (ballSize / 2));
        double normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight / 2);
        double bounceAngle = normalizedRelativeIntersectionY * (math.pi / 4); // Max 45 degrees

        ballSpeedX = 5 * math.cos(bounceAngle);
        ballSpeedY = 5 * -math.sin(bounceAngle);

        // Ensure ball moves right after player paddle hit
        if (ballSpeedX < 0) ballSpeedX = -ballSpeedX;
      }

      if (ballX >= screenWidth - paddleWidth - ballSize &&
          ballY + ballSize >= aiPaddleY &&
          ballY <= aiPaddleY + paddleHeight) {
        // Calculate bounce angle based on where ball hits paddle
        double relativeIntersectY = (aiPaddleY + (paddleHeight / 2)) - (ballY + (ballSize / 2));
        double normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight / 2);
        double bounceAngle = normalizedRelativeIntersectionY * (math.pi / 4); // Max 45 degrees

        ballSpeedX = 5 * math.cos(bounceAngle);
        ballSpeedY = 5 * -math.sin(bounceAngle);

        // Ensure ball moves left after AI paddle hit
        if (ballSpeedX > 0) ballSpeedX = -ballSpeedX;
      }

      // Scoring
      if (ballX < 0) {
        aiScore++;
        resetGame();
      } else if (ballX > screenWidth) {
        playerScore++;
        resetGame();
      }

      // Simple AI movement
      double aiPaddleCenter = aiPaddleY + paddleHeight / 2;
      double ballCenter = ballY + ballSize / 2;

      // AI only moves if ball is moving toward it
      if (ballSpeedX > 0) {
        if (aiPaddleCenter < ballCenter - 10) {
          aiPaddleY += paddleSpeed * 0.7; // AI is a bit slower than player
        } else if (aiPaddleCenter > ballCenter + 10) {
          aiPaddleY -= paddleSpeed * 0.7;
        }
      }

      // Keep paddles within bounds
      aiPaddleY = aiPaddleY.clamp(0, gameAreaHeight - paddleHeight);
      playerPaddleY = playerPaddleY.clamp(0, gameAreaHeight - paddleHeight);
    });
  }

  void movePlayerPaddle(double dy) {
    setState(() {
      playerPaddleY += dy;
      playerPaddleY = playerPaddleY.clamp(0, gameAreaHeight - paddleHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    gameAreaHeight = screenHeight * 0.8;

    // Initialize positions if not already set
    if (ballX == 0 && ballY == 0) {
      ballX = screenWidth / 2;
      ballY = gameAreaHeight / 2;
      playerPaddleY = (gameAreaHeight - paddleHeight) / 2;
      aiPaddleY = (gameAreaHeight - paddleHeight) / 2;
    }

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              movePlayerPaddle(-paddleSpeed);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              movePlayerPaddle(paddleSpeed);
            } else if (event.logicalKey == LogicalKeyboardKey.space && !gameStarted) {
              startGame();
            }
          }
        },
        child: GestureDetector(
          onTap: () {
            if (!gameStarted) {
              startGame();
            }
            // Re-request focus for keyboard
            FocusScope.of(context).requestFocus(_focusNode);
          },
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                // Score display
                Container(
                  height: screenHeight * 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$playerScore : $aiScore',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Game area
                Container(
                  height: gameAreaHeight,
                  width: screenWidth,
                  child: Stack(
                    children: [
                      // Center line
                      Center(
                        child: VerticalDivider(
                          color: Colors.white.withOpacity(0.5),
                          thickness: 2,
                          width: 2,
                        ),
                      ),
                      // Ball
                      Positioned(
                        left: ballX,
                        top: ballY,
                        child: Container(
                          width: ballSize,
                          height: ballSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(ballSize / 2),
                          ),
                        ),
                      ),
                      // Player paddle
                      Positioned(
                        left: 0,
                        top: playerPaddleY,
                        child: Container(
                          width: paddleWidth,
                          height: paddleHeight,
                          color: Colors.white,
                        ),
                      ),
                      // AI paddle
                      Positioned(
                        right: 0,
                        top: aiPaddleY,
                        child: Container(
                          width: paddleWidth,
                          height: paddleHeight,
                          color: Colors.white,
                        ),
                      ),
                      // Game state overlay
                      if (!gameStarted)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'TAP TO START',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Controls for mobile
                Container(
                  height: screenHeight * 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => movePlayerPaddle(-paddleSpeed * 1.5),
                        child: Icon(Icons.arrow_upward, size: 36),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => movePlayerPaddle(paddleSpeed * 1.5),
                        child: Icon(Icons.arrow_downward, size: 36),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}