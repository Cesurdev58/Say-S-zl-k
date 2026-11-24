import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../services/score_calculator.dart';
import '../services/word_service.dart';
import '../services/math_service.dart';
import '../services/number_solver_service.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/word_game_board.dart';
import '../widgets/math_game_board.dart';

class GameScreen extends StatefulWidget {
  final bool isTimed;
  final String subMode;

  const GameScreen({
    super.key,
    required this.isTimed,
    required this.subMode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late String currentRoundType;
  int score = 0;
  int wordScore = 0;
  int mathScore = 0;
  late int remainingSeconds;
  Timer? gameTimer;

  String? scoreDeltaText;
  String? timeDeltaText;
  bool showDelta = false;

  String currentLongestUserWord = '';
  int exactMathCount = 0;

  int wordQuestionsSeen = 0;
  int wordPasses = 0;
  int wordCorrectAnswers = 0;

  int mathQuestionsSeen = 0;
  int mathPasses = 0;
  int mathCorrectAnswers = 0;

  int totalAnswerTime = 0;
  DateTime? questionStartTime;

  List<String> availableLetters = [];
  List<int> selectedIndices = [];
  List<String> selectedLetters = [];

  List<int> originalNumbers = [];
  List<int> currentNumbers = [];
  int targetNumber = 0;
  List<String> historySteps = [];
  List<List<int>> previousNumbersHistory = [];

  int? firstNumIndex;
  int? firstNumValue;
  String? selectedOp;

  List<Map<String, dynamic>> missedSolutions = [];
  final Set<String> _usedMathSignatures = {};

  final Random _random = Random();
  final List<String> _alphabet = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
  ];

  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _praiseText = "";
  double _praiseBottom = 0;
  double _praiseOpacity = 0.0;

  bool _isPausedForAnimation = false;
  bool _isPausedForDialog = false;
  bool _isJokerDialogOpen = false;
  bool _isGameOver = false;
  bool _isSubmittingAnswer = false;

  @override
  void initState() {
    super.initState();
    currentRoundType = widget.subMode == 'mix' ? 'word' : widget.subMode;

    if (widget.subMode == 'word') {
      remainingSeconds = 30;
    } else if (widget.subMode == 'math') {
      remainingSeconds = 40;
    } else {
      remainingSeconds = 40;
    }

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _praiseBottom = 250;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupNewRound();

    if (widget.isTimed) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isGameOver) return false;
    setState(() => _isPausedForDialog = true);
    AudioService.instance.playClick();

    bool? exit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkmak Üzeresin!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Şu ana kadarki tüm ilerlemen silinecek. Oyundan çıkmak istediğine emin misin?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.of(context).pop(false);
            },
            child: const Text('İptal', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.of(context).pop(true);
            },
            child: const Text('Evet, Çık', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _isPausedForDialog = false);
    }
    return exit ?? false;
  }

  void _showPraiseAnimation() {
    final words = ['MÜKEMMEL!', 'HARİKA!', 'ZEKİCE!', 'EFSANE!', 'ZAFER!'];

    setState(() {
      _praiseText = words[_random.nextInt(words.length)];
      _praiseBottom = MediaQuery.of(context).size.height * 0.4;
      _praiseOpacity = 0.0;
      _isPausedForAnimation = true;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && !_isGameOver) {
        setState(() {
          _praiseBottom = MediaQuery.of(context).size.height * 0.6;
          _praiseOpacity = 1.0;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isGameOver) {
        setState(() {
          _praiseOpacity = 0.0;
          _praiseBottom = MediaQuery.of(context).size.height * 0.65;
          _isPausedForAnimation = false;
        });
      }
    });
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Animasyon sırasında timer gizlice durmaz; yalnızca diyalog açıkken veya oyun bittiğinde durur
      if (_isPausedForDialog || _isGameOver) return;

      if (remainingSeconds > 1) {
        setState(() {
          remainingSeconds--;
          if (remainingSeconds <= 5 && !_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          } else if (remainingSeconds > 5 && _pulseController.isAnimating) {
            _pulseController.reset();
          }
        });
      } else {
        setState(() {
          remainingSeconds = 0;
        });
        timer.cancel();
        _pulseController.reset();
        _finishGame();
      }
    });
  }

  void _setupNewRound() {
    if (_isGameOver) return;
    setState(() {
      _isSubmittingAnswer = false;
      selectedIndices.clear();
      selectedLetters.clear();
      historySteps.clear();
      previousNumbersHistory.clear();
      firstNumIndex = null;
      firstNumValue = null;
      selectedOp = null;

      questionStartTime = DateTime.now();

      if (currentRoundType == 'word') {
        wordQuestionsSeen++;
        availableLetters = WordService.instance.generateLetters();
      } else {
        mathQuestionsSeen++;
        final puzzle = MathService.instance.generatePuzzle(usedSignatures: _usedMathSignatures);
        originalNumbers = List<int>.from(puzzle.numbers);
        currentNumbers = List<int>.from(puzzle.numbers);
        targetNumber = puzzle.target;
      }
    });
  }

  void _triggerDeltas(int pScore, int pTime) {
    setState(() {
      scoreDeltaText = pScore > 0 ? '+$pScore Puan' : null;
      timeDeltaText = pTime != 0 ? (pTime > 0 ? '+$pTime s' : '$pTime s') : null;
      showDelta = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => showDelta = false);
    });
  }

  void _submitWord() {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    if (widget.isTimed && remainingSeconds <= 0) return;

    String word = selectedLetters.join('');
    if (word.isEmpty) return;

    if (word.length == 1) {
      AudioService.instance.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az 2 harfli bir kelime girmelisiniz!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    _isSubmittingAnswer = true;
    WordValidationResult result = WordService.instance.validateWord(word, availableLetters);

    if (result == WordValidationResult.valid) {
      AudioService.instance.playSuccess();
      _confettiController.play();
      _showPraiseAnimation();

      if (word.length > currentLongestUserWord.length) {
        currentLongestUserWord = word;
      }

      if (questionStartTime != null) {
        totalAnswerTime += DateTime.now().difference(questionStartTime!).inSeconds;
      }
      wordCorrectAnswers++;

      int len = word.length;
      int earned = ScoreCalculator.soloWordScore(len);
      int bonusSeconds = ScoreCalculator.soloWordBonusSeconds(len);

      _triggerDeltas(earned, bonusSeconds);
      setState(() {
        wordScore += earned;
        score += earned;
        if (widget.isTimed) {
          remainingSeconds += bonusSeconds;
          if (remainingSeconds > 5) _pulseController.reset();
        }
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_isGameOver) _nextTurn();
      });
    } else {
      _isSubmittingAnswer = false;
      AudioService.instance.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onNumberTap(int index, int num) {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    if (widget.isTimed && remainingSeconds <= 0) return;
    AudioService.instance.playClick();

    if (firstNumIndex == null) {
      setState(() {
        firstNumIndex = index;
        firstNumValue = num;
      });
    } else if (selectedOp != null && firstNumIndex != index) {
      int secondNum = num;
      int? result;

      if (selectedOp == '+') result = firstNumValue! + secondNum;
      // Standart Kural: Ara sonuçlar pozitif tam sayı olmalıdır (0 veya negatif olamaz)
      if (selectedOp == '-') {
        if (firstNumValue! - secondNum > 0) {
          result = firstNumValue! - secondNum;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çıkarma sonucu pozitif bir tam sayı olmalıdır!'),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 900),
            ),
          );
        }
      }
      if (selectedOp == '*') result = firstNumValue! * secondNum;
      if (selectedOp == '/') {
        if (secondNum > 0 && firstNumValue! % secondNum == 0) {
          result = firstNumValue! ~/ secondNum;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bölme işlemi kalansız olmalıdır!'),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 900),
            ),
          );
        }
      }

      if (result != null) {
        String displayOp = selectedOp == '*' ? '×' : (selectedOp == '/' ? '÷' : selectedOp!);
        setState(() {
          previousNumbersHistory.add(List<int>.from(currentNumbers));
          historySteps.add('$firstNumValue $displayOp $secondNum = $result');

          if (firstNumIndex! > index) {
            currentNumbers.removeAt(firstNumIndex!);
            currentNumbers.removeAt(index);
          } else {
            currentNumbers.removeAt(index);
            currentNumbers.removeAt(firstNumIndex!);
          }
          currentNumbers.add(result!);

          firstNumIndex = null;
          firstNumValue = null;
          selectedOp = null;
        });

        if (result == targetNumber) {
          Future.delayed(Duration.zero, () {
            if (mounted && !_isGameOver) _submitMath();
          });
        }
      }
    }
  }

  void _submitMath() {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    if (widget.isTimed && remainingSeconds <= 0) return;
    if (currentNumbers.isEmpty) return;

    int closest = currentNumbers.first;
    int minDiff = (targetNumber - closest).abs();

    for (int n in currentNumbers) {
      int diff = (targetNumber - n).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = n;
      }
    }

    if (minDiff <= 10) {
      _isSubmittingAnswer = true;
      AudioService.instance.playSuccess();
      _confettiController.play();
      _showPraiseAnimation();

      if (minDiff == 0) exactMathCount++;

      if (questionStartTime != null) {
        totalAnswerTime += DateTime.now().difference(questionStartTime!).inSeconds;
      }
      mathCorrectAnswers++;

      int remainingNumberCount = currentNumbers.length;
      int earned = ScoreCalculator.mathScore(minDiff, remainingNumberCount);
      int bonusSeconds = ScoreCalculator.soloMathBonusSeconds(minDiff, remainingNumberCount);

      _triggerDeltas(earned, bonusSeconds);
      setState(() {
        mathScore += earned;
        score += earned;
        if (widget.isTimed) {
          remainingSeconds += bonusSeconds;
          if (remainingSeconds > 5) _pulseController.reset();
        }
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_isGameOver) _nextTurn();
      });
    } else {
      AudioService.instance.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hedefe en fazla 10 yaklaşmalısınız!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<String> _calculateRealMathSteps() {
    return NumberSolverService.instance.solveSteps(originalNumbers, targetNumber);
  }

  String _calculateRealLongestWord() {
    String best = WordService.instance.findLongestWord(availableLetters);
    return best.isEmpty ? "SÖZLÜKTE KELİME BULUNAMADI" : best;
  }

  void _recordCurrentSolution() {
    if (currentRoundType == 'word') {
      missedSolutions.add({
        'type': 'word',
        'letters': availableLetters.where((l) => l != 'JOKER').join(', '),
        'bestWord': _calculateRealLongestWord(),
      });
    } else {
      missedSolutions.add({
        'type': 'math',
        'target': targetNumber,
        'mathSteps': _calculateRealMathSteps(),
      });
    }
  }

  void _passQuestion() {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    if (widget.isTimed && remainingSeconds <= 0) return;

    AudioService.instance.playClick();

    int penalty = widget.subMode == 'mix' ? 10 : 5;
    _recordCurrentSolution();

    if (currentRoundType == 'word') {
      wordPasses++;
    } else {
      mathPasses++;
    }

    if (widget.isTimed) {
      _triggerDeltas(0, -penalty);
      int newRem = max(0, remainingSeconds - penalty);
      setState(() {
        remainingSeconds = newRem;
      });
      if (newRem <= 0) {
        gameTimer?.cancel();
        _pulseController.reset();
        _finishGame(alreadyRecordedCurrentSolution: true);
        return;
      }
    }
    _nextTurn();
  }

  void _showTimelessSolution() {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    AudioService.instance.playClick();

    bool isWord = currentRoundType == 'word';
    String title = isWord ? 'Olası En Uzun Kelime' : 'Adım Adım Tam Çözüm';
    final String bestWord = isWord ? _calculateRealLongestWord() : '';
    final List<String> mathSteps = isWord ? const [] : _calculateRealMathSteps();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF131127).withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (isWord) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    bestWord == "SÖZLÜKTE KELİME BULUNAMADI"
                        ? "Bu harflerle sözlükte eşleşen kelime bulunamadı."
                        : "$bestWord (${bestWord.length} Harf)",
                    style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mathSteps.map((step) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00CEC9), size: 16),
                            const SizedBox(width: 8),
                            Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    AudioService.instance.playClick();
                    Navigator.pop(context);
                    _nextTurn();
                  },
                  child: const Text('Sonraki Soruya Geç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextTurn() {
    if (_isGameOver || (widget.isTimed && remainingSeconds <= 0)) return;
    if (widget.subMode == 'mix') {
      currentRoundType = currentRoundType == 'word' ? 'math' : 'word';
    }
    _setupNewRound();
  }

  Future<void> _finishGame({bool alreadyRecordedCurrentSolution = false}) async {
    if (_isGameOver) return;
    _isGameOver = true;
    gameTimer?.cancel();
    _pulseController.reset();

    if (!alreadyRecordedCurrentSolution) {
      _recordCurrentSolution();
    }

    if (_isJokerDialogOpen && mounted) {
      Navigator.of(context).pop();
      _isJokerDialogOpen = false;
    }

    try {
      await UserService.instance.addGameResult(
        totalEarned: score,
        wordEarned: wordScore,
        mathEarned: mathScore,
        currentLongestWord: currentLongestUserWord,
        exactMathCount: exactMathCount,
        wordSeen: wordQuestionsSeen,
        wordPassed: wordPasses,
        wordCorrect: wordCorrectAnswers,
        mathSeen: mathQuestionsSeen,
        mathPassed: mathPasses,
        mathCorrect: mathCorrectAnswers,
        answerTime: totalAnswerTime,
      );
    } catch (e) {
      debugPrint("Oyun sonucu kaydedilirken hata: $e");
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        totalScore: score,
        wordScore: wordScore,
        mathScore: mathScore,
        missedSolutions: missedSolutions,
        onReplay: () {
          AudioService.instance.playClick();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(isTimed: widget.isTimed, subMode: widget.subMode),
            ),
          );
        },
        onHome: () {
          AudioService.instance.playClick();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openJokerPicker(int index) {
    if (_isSubmittingAnswer || _isPausedForAnimation || _isPausedForDialog || _isGameOver || _isJokerDialogOpen) return;
    if (widget.isTimed && remainingSeconds <= 0) return;

    _isJokerDialogOpen = true;
    AudioService.instance.playClick();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1D1B36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Joker Harf Seçin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _alphabet.map((char) {
                        return InkWell(
                          onTap: () {
                            AudioService.instance.playClick();
                            if (_isJokerDialogOpen) {
                              _isJokerDialogOpen = false;
                              Navigator.of(dialogContext).pop();
                            }
                            if (!_isGameOver && (!widget.isTimed || remainingSeconds > 0)) {
                              setState(() {
                                selectedIndices.add(index);
                                selectedLetters.add(char);
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: const Color(0xFFFF9F43), borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(char, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isJokerDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isBoardPaused = _isSubmittingAnswer ||
        _isPausedForAnimation ||
        _isPausedForDialog ||
        _isGameOver ||
        (widget.isTimed && remainingSeconds <= 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _onWillPop()) {
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          _buildScoreCard(),
                          const Spacer(),
                          if (currentRoundType == 'word')
                            WordGameBoard(
                              availableLetters: availableLetters,
                              selectedIndices: selectedIndices,
                              selectedLetters: selectedLetters,
                              isPaused: isBoardPaused,
                              onLetterTap: (index, char) {
                                if (isBoardPaused) return;
                                AudioService.instance.playClick();
                                setState(() {
                                  selectedIndices.add(index);
                                  selectedLetters.add(char);
                                });
                              },
                              onJokerTap: _openJokerPicker,
                            )
                          else
                            MathGameBoard(
                              targetNumber: targetNumber,
                              historySteps: historySteps,
                              currentNumbers: currentNumbers,
                              firstNumIndex: firstNumIndex,
                              selectedOp: selectedOp,
                              isPaused: isBoardPaused,
                              onNumberTap: _onNumberTap,
                              onOperatorTap: (op) {
                                if (isBoardPaused) return;
                                AudioService.instance.playClick();
                                setState(() => selectedOp = op);
                              },
                            ),
                          const Spacer(),
                          _buildBottomControls(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: _pulseAnimation.value),
                        width: _pulseAnimation.value * 20,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              bottom: _praiseBottom,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _praiseOpacity,
                  child: Text(
                    _praiseText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Color(0xFF7C5CFC), blurRadius: 20, offset: Offset(0, 0)),
                        Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 6,
                maxBlastForce: 25,
                minBlastForce: 15,
                emissionFrequency: 0.02,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -5 * pi / 6,
                maxBlastForce: 25,
                minBlastForce: 15,
                emissionFrequency: 0.02,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          Text(
            widget.subMode == 'mix'
                ? 'Karışık Mod'
                : (currentRoundType == 'word' ? 'Aşama: Kelime' : 'Aşama: İşlem'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isTimed)
                InkWell(
                  onTap: (_isGameOver || remainingSeconds <= 0) ? null : _passQuestion,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Pas (${widget.subMode == 'mix' ? '-10s' : '-5s'})',
                      style: const TextStyle(color: Color(0xFFFD79A8), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              if (widget.isTimed)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: remainingSeconds <= 5 ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF232042),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: remainingSeconds <= 5 ? Colors.redAccent : const Color(0xFF7C5CFC)),
                    ),
                    child: Text(
                      '${remainingSeconds}s',
                      style: TextStyle(
                        color: remainingSeconds <= 5 ? Colors.redAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1B36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentRoundType == 'word' ? 'Kelime Puanı' : 'Toplanan Puan',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text('$score', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          if (showDelta && scoreDeltaText != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(scoreDeltaText!, style: const TextStyle(color: Color(0xFFFD79A8), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final bool isLocked = _isSubmittingAnswer ||
        _isPausedForAnimation ||
        _isPausedForDialog ||
        _isGameOver ||
        (widget.isTimed && remainingSeconds <= 0);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLocked
                  ? null
                  : () {
                      AudioService.instance.playClick();
                      setState(() {
                        if (currentRoundType == 'word') {
                          if (selectedLetters.isNotEmpty) {
                            selectedLetters.removeLast();
                            selectedIndices.removeLast();
                          }
                        } else {
                          if (selectedOp != null) {
                            selectedOp = null;
                          } else if (firstNumIndex != null) {
                            firstNumIndex = null;
                            firstNumValue = null;
                          } else if (historySteps.isNotEmpty && previousNumbersHistory.isNotEmpty) {
                            historySteps.removeLast();
                            currentNumbers = List<int>.from(previousNumbersHistory.last);
                            previousNumbersHistory.removeLast();
                          }
                        }
                      });
                    },
              child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLocked
                  ? null
                  : () {
                      AudioService.instance.playClick();
                      setState(() {
                        selectedLetters.clear();
                        selectedIndices.clear();
                        historySteps.clear();
                        currentNumbers = List<int>.from(originalNumbers);
                        previousNumbersHistory.clear();
                        firstNumIndex = null;
                        firstNumValue = null;
                        selectedOp = null;
                      });
                    },
              child: Text(
                currentRoundType == 'word' ? 'Temizle' : 'Sıfırla',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ),
        if (!widget.isTimed) ...[
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF00CEC9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isLocked ? null : _showTimelessSolution,
                child: const Text('Cevabı Göster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF5A4FCF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLocked
                  ? null
                  : () {
                      currentRoundType == 'word' ? _submitWord() : _submitMath();
                    },
              child: Text(
                currentRoundType == 'word' ? 'Onayla' : 'Tamamla',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}