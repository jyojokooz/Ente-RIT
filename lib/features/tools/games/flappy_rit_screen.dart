import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlappyRitScreen extends StatefulWidget {
  const FlappyRitScreen({super.key});

  @override
  State<FlappyRitScreen> createState() => _FlappyRitScreenState();
}

class _FlappyRitScreenState extends State<FlappyRitScreen> {
  // Game states
  double birdY = 0;
  double initialPos = 0;
  double height = 0;
  double time = 0;
  double gravity = -4.9;
  double velocity = 2.5;
  
  bool gameHasStarted = false;
  bool gameIsOver = false;
  int score = 0;
  int highScore = 0;

  // Pipe variables
  double pipeXOne = 1;
  double pipeXTwo = 2.5; // Starts further away
  
  // Height gaps
  final double pipeWidth = 0.2;
  // Gap needs to be small enough to be challenging, but big enough to pass
  final double gapSize = 0.6;
  
  // Randomize pipe heights (simulated simply for now)
  double pipeOneY = 0.0; 
  double pipeTwoY = 0.3; // Offset

  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
        
    if (doc.exists && doc.data()!.containsKey('flappyScore')) {
      setState(() {
        highScore = doc.data()!['flappyScore'] ?? 0;
      });
    }
  }

  void _startGame() {
    gameHasStarted = true;
    score = 0;
    birdY = 0;
    time = 0;
    initialPos = birdY;
    pipeXOne = 1;
    pipeXTwo = 2.5;

    _gameTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (mounted) {
        setState(() {
          // Calculate height
          time += 0.02; // Update time
          height = gravity * time * time + velocity * time;
          birdY = initialPos - height;

          // Move pipes
          pipeXOne -= 0.015;
          pipeXTwo -= 0.015;

          // Pipe respawning & scoring
          if (pipeXOne < -1.5) {
            pipeXOne += 3;
            score++;
          }
          if (pipeXTwo < -1.5) {
            pipeXTwo += 3;
            score++;
          }

          // Check collisions
          _checkCollision();
        });
      }
    });
  }

  void _jump() {
    if (gameIsOver) return;
    
    setState(() {
      time = 0;
      initialPos = birdY;
    });
  }

  void _checkCollision() {
    // Check floor & ceiling
    if (birdY > 1 || birdY < -1) {
      _gameOver();
      return;
    }

    // Bird width/height roughly 0.1
    // Pipe collision check
    bool hitPipeOne = (pipeXOne < 0.1 && pipeXOne > -0.1) &&
        (birdY < pipeOneY - gapSize / 2 || birdY > pipeOneY + gapSize / 2);
        
    bool hitPipeTwo = (pipeXTwo < 0.1 && pipeXTwo > -0.1) &&
        (birdY < pipeTwoY - gapSize / 2 || birdY > pipeTwoY + gapSize / 2);

    if (hitPipeOne || hitPipeTwo) {
      _gameOver();
    }
  }

  Future<void> _gameOver() async {
    _gameTimer?.cancel();
    setState(() {
      gameIsOver = true;
      gameHasStarted = false;
    });

    if (score > highScore) {
      highScore = score;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save local max
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'flappyScore': highScore,
        }, SetOptions(merge: true));

        // Get username
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final name = userDoc.data()?['name'] ?? 'Anonymous Student';

        // Submit to global game scores
        await FirebaseFirestore.instance.collection('game_scores').add({
          'userId': user.uid,
          'userName': name,
          'gameId': 'flappy_rit',
          'score': highScore,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _resetGame() {
    setState(() {
      gameHasStarted = false;
      gameIsOver = false;
      birdY = 0;
      score = 0;
      pipeXOne = 1;
      pipeXTwo = 2.5;
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: GestureDetector(
        onTap: () {
          if (gameIsOver) {
            _resetGame();
          } else if (!gameHasStarted) {
            _startGame();
          } else {
            _jump();
          }
        },
        child: Stack(
          children: [
            // BACKGROUND
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // BIRD
                      Container(
                        alignment: Alignment(0, birdY),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9F1C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      // PIPES
                      _buildPipe(pipeXOne, pipeOneY, true),
                      _buildPipe(pipeXOne, pipeOneY, false),
                      
                      _buildPipe(pipeXTwo, pipeTwoY, true),
                      _buildPipe(pipeXTwo, pipeTwoY, false),

                      // TAP TO PLAY
                      Container(
                        alignment: const Alignment(0, -0.3),
                        child: !gameHasStarted && !gameIsOver
                            ? Text(
                                'TAP TO PLAY',
                                style: GoogleFonts.pressStart2p(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
                // GROUND
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      border: Border(
                        top: BorderSide(color: Colors.brown, width: 10),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SCORE: $score',
                            style: GoogleFonts.pressStart2p(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'BEST: $highScore',
                            style: GoogleFonts.pressStart2p(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // GAME OVER OVERLAY
            if (gameIsOver)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GAME OVER',
                        style: GoogleFonts.pressStart2p(
                          color: Colors.redAccent,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SCORE: $score',
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'TAP TO RESTART',
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // BACK BUTTON
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipe(double x, double y, bool isBottom) {
    // Height calculation based on screen proportion
    return Container(
      alignment: Alignment(
        x,
        isBottom ? 1 : -1,
      ),
      child: FractionallySizedBox(
        heightFactor: isBottom ? (1 + y - gapSize/2) / 2 : (1 - y - gapSize/2) / 2,
        widthFactor: pipeWidth,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            border: Border.all(color: Colors.green.shade900, width: 4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
