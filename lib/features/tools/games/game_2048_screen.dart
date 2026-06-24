import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int size = 4;
  late List<List<int>> grid;
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initGrid();
  }

  Future<void> _loadHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
        
    if (doc.exists && doc.data()!.containsKey('game2048Score')) {
      setState(() {
        highScore = doc.data()!['game2048Score'] ?? 0;
      });
    }
  }

  void _initGrid() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    isGameOver = false;
    _addRandomTile();
    _addRandomTile();
    setState(() {});
  }

  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) {
          emptyCells.add(Point(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) return;

    final random = Random();
    final point = emptyCells[random.nextInt(emptyCells.length)];
    // 10% chance of 4, 90% chance of 2
    grid[point.x][point.y] = random.nextInt(10) == 0 ? 4 : 2;
  }

  bool _canMove() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) return true;
        if (c < size - 1 && grid[r][c] == grid[r][c + 1]) return true;
        if (r < size - 1 && grid[r][c] == grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  Future<void> _checkGameOver() async {
    if (!_canMove()) {
      setState(() {
        isGameOver = true;
      });
      if (score > highScore) {
        highScore = score;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'game2048Score': highScore,
          }, SetOptions(merge: true));

          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final name = userDoc.data()?['name'] ?? 'Anonymous Student';

          await FirebaseFirestore.instance.collection('game_scores').add({
            'userId': user.uid,
            'userName': name,
            'gameId': '2048',
            'score': highScore,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (isGameOver) return;

    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 0) {
        _moveRight();
      } else {
        _moveLeft();
      }
    } else {
      // Vertical swipe
      if (dy > 0) {
        _moveDown();
      } else {
        _moveUp();
      }
    }
  }

  bool _slideAndMerge(List<int> row) {
    bool moved = false;
    // Slide non-zeroes to the left
    int insertPos = 0;
    for (int i = 0; i < size; i++) {
      if (row[i] != 0) {
        if (i != insertPos) {
          row[insertPos] = row[i];
          row[i] = 0;
          moved = true;
        }
        insertPos++;
      }
    }

    // Merge
    for (int i = 0; i < size - 1; i++) {
      if (row[i] != 0 && row[i] == row[i + 1]) {
        row[i] *= 2;
        score += row[i];
        row[i + 1] = 0;
        moved = true;
      }
    }

    // Slide again after merge
    insertPos = 0;
    for (int i = 0; i < size; i++) {
      if (row[i] != 0) {
        if (i != insertPos) {
          row[insertPos] = row[i];
          row[i] = 0;
          moved = true;
        }
        insertPos++;
      }
    }
    return moved;
  }

  void _moveLeft() {
    bool moved = false;
    for (int r = 0; r < size; r++) {
      if (_slideAndMerge(grid[r])) moved = true;
    }
    if (moved) {
      _addRandomTile();
      _checkGameOver();
      setState(() {});
    }
  }

  void _moveRight() {
    bool moved = false;
    for (int r = 0; r < size; r++) {
      List<int> row = grid[r].reversed.toList();
      if (_slideAndMerge(row)) moved = true;
      grid[r] = row.reversed.toList();
    }
    if (moved) {
      _addRandomTile();
      _checkGameOver();
      setState(() {});
    }
  }

  void _moveUp() {
    bool moved = false;
    for (int c = 0; c < size; c++) {
      List<int> col = [for (int r = 0; r < size; r++) grid[r][c]];
      if (_slideAndMerge(col)) moved = true;
      for (int r = 0; r < size; r++) grid[r][c] = col[r];
    }
    if (moved) {
      _addRandomTile();
      _checkGameOver();
      setState(() {});
    }
  }

  void _moveDown() {
    bool moved = false;
    for (int c = 0; c < size; c++) {
      List<int> col = [for (int r = 0; r < size; r++) grid[r][c]].reversed.toList();
      if (_slideAndMerge(col)) moved = true;
      col = col.reversed.toList();
      for (int r = 0; r < size; r++) grid[r][c] = col[r];
    }
    if (moved) {
      _addRandomTile();
      _checkGameOver();
      setState(() {});
    }
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFFCDC1B4);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8EF);
    final boardColor = const Color(0xFFBBADA0);
    final textColor = isDark ? Colors.white : const Color(0xFF776E65);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2048',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      _ScoreBox(label: 'SCORE', score: score),
                      const SizedBox(width: 8),
                      _ScoreBox(label: 'BEST', score: highScore),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Game Board
              GestureDetector(
                onPanEnd: _handleSwipe,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: boardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, index) {
                          int r = index ~/ size;
                          int c = index % size;
                          int val = grid[r][c];

                          return Container(
                            decoration: BoxDecoration(
                              color: _getTileColor(val),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: val > 0
                                  ? Text(
                                      '$val',
                                      style: GoogleFonts.poppins(
                                        fontSize: val >= 1000 ? 20 : (val >= 100 ? 26 : 32),
                                        fontWeight: FontWeight.bold,
                                        color: _getTextColor(val),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),

                      // Game Over Overlay
                      if (isGameOver)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE4DA).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Game Over!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF776E65),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _initGrid,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8F7A66),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Try Again',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                'Swipe up, down, left, or right to move tiles. When two tiles with the same number touch, they merge into one!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              if (!isGameOver)
                ElevatedButton.icon(
                  onPressed: _initGrid,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text('Restart Game', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBox({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEEE4DA),
            ),
          ),
          Text(
            '$score',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
