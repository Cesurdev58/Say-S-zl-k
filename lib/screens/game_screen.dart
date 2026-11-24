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
import '../services/haptics.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/joker_picker_dialog.dart';
import '../widgets/solution_dialog.dart';
import '../widgets/timer_chip.dart';
import '../widgets/word_game_board.dart';
import '../widgets/math_game_board.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/game_button.dart';
import '../widgets/ui/game_card.dart';
import '../widgets/ui/game_control_bar.dart';
import '../widgets/ui/game_dialog.dart';
import '../widgets/ui/count_up_text.dart';
import '../widgets/ui/game_hud.dart';
import '../widgets/ui/motion.dart';
import '../widgets/game_background.dart';
import '../widgets/ui/game_confetti.dart';
import '../widgets/ui/praise_overlay.dart';

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
  // Kalan süre ValueNotifier'da tutulur; saniyelik tikler tüm ekranı rebuild etmez.
  final ValueNotifier<int> _remainingNotifier = ValueNotifier<int>(0);
  int get remainingSeconds => _remainingNotifier.value;
  set remainingSeconds(int v) => _remainingNotifier.value = v;
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


  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Övgü yazısı bu sinyal arttığında bir kez oynar.
  final ValueNotifier<int> _praiseSignal = ValueNotifier<int>(0);

  bool _isPausedForAnimation = false;
  bool _isPausedForDialog = false;
  bool _isJokerDialogOpen = false;
  bool _isGameOver = false;
  bool _isSubmittingAnswer = false;
  bool _isResolvingSolution = false;
  // Yanlış kelime / geçersiz işlemde cevap alanını sallamak için artırılır.
  final ValueNotifier<int> _errorSignal = ValueNotifier<int>(0);

  void _signalError() {
    Haptics.error();
    _errorSignal.value++;
  }

  void _playConfetti() {
    if (!Motion.reduced(context)) _confettiController.play();
  }
  Future<List<String>>? _mathStepsFuture;

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

    _confettiController = GameConfetti.newController();

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
    _remainingNotifier.dispose();
    _errorSignal.dispose();
    _praiseSignal.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isGameOver) return false;
    setState(() => _isPausedForDialog = true);
    AudioService.instance.playClick();

    bool? exit = await showGameConfirmDialog(
      context,
      title: 'Çıkmak Üzeresin!',
      message: 'Şu ana kadarki tüm ilerlemen silinecek. Oyundan çıkmak istediğine emin misin?',
      cancelLabel: 'İptal',
      confirmLabel: 'Evet, Çık',
      barrierDismissible: false,
      onCancel: AudioService.instance.playClick,
      onConfirm: AudioService.instance.playClick,
    );

    if (mounted) {
      setState(() => _isPausedForDialog = false);
    }
    return exit ?? false;
  }

  /// Doğru cevap efektleri (ses, titreşim, konfeti, övgü) tahta güncellemesiyle aynı
  /// karede değil, bir sonraki karede tetiklenir; böylece tek karede darboğaz oluşmaz.
  /// Övgü süresince (1 sn) tahta kilitli kalır.
  void _celebrate({bool exact = false}) {
    setState(() => _isPausedForAnimation = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isGameOver) {
        setState(() => _isPausedForAnimation = false);
      }
    });
    Motion.afterFrame(() {
      if (!mounted) return;
      AudioService.instance.playSuccess(haptic: false);
      Haptics.success(exact: exact);
      _playConfetti();
      _praiseSignal.value++;
    });
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Animasyon sırasında timer gizlice durmaz; yalnızca diyalog açıkken veya oyun bittiğinde durur
      if (_isPausedForDialog || _isGameOver) return;

      if (remainingSeconds > 1) {
        // Yalnızca ValueNotifier güncellenir; setState yok (tüm ekran yeniden çizilmez).
        remainingSeconds--;
        if (remainingSeconds <= 5) Haptics.tick();
        if (remainingSeconds <= 5 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (remainingSeconds > 5 && _pulseController.isAnimating) {
          _pulseController.reset();
        }
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
        // Çözüm adımları arka planda (isolate) önceden hesaplanır.
        _mathStepsFuture = NumberSolverService.instance.solveStepsAsync(originalNumbers, targetNumber);
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
      AudioService.instance.playError(haptic: false);
      _signalError();
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
      _celebrate();

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
      AudioService.instance.playError(haptic: false);
      _signalError();
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
    AudioService.instance.playClick(haptic: false);
    Haptics.selection();

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
          _signalError();
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
          _signalError();
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
      _celebrate(exact: minDiff == 0);

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
      AudioService.instance.playError(haptic: false);
      _signalError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hedefe en fazla 10 yaklaşmalısınız!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<List<String>> _calculateRealMathSteps() {
    return _mathStepsFuture ??=
        NumberSolverService.instance.solveStepsAsync(originalNumbers, targetNumber);
  }

  Future<String> _calculateRealLongestWord() async {
    String best = await WordService.instance.findLongestWordAsync(availableLetters);
    return best.isEmpty ? "SÖZLÜKTE KELİME BULUNAMADI" : best;
  }

  Future<void> _recordCurrentSolution() async {
    if (currentRoundType == 'word') {
      final letters = availableLetters.where((l) => l != 'JOKER').join(', ');
      missedSolutions.add({
        'type': 'word',
        'letters': letters,
        'bestWord': await _calculateRealLongestWord(),
      });
    } else {
      final target = targetNumber;
      missedSolutions.add({
        'type': 'math',
        'target': target,
        'mathSteps': await _calculateRealMathSteps(),
      });
    }
  }

  Future<void> _passQuestion() async {
    if (_isSubmittingAnswer || _isResolvingSolution || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    if (widget.isTimed && remainingSeconds <= 0) return;

    AudioService.instance.playClick();

    int penalty = widget.subMode == 'mix' ? 10 : 5;
    _isResolvingSolution = true;
    try {
      await _recordCurrentSolution();
    } finally {
      _isResolvingSolution = false;
    }
    if (!mounted || _isGameOver) return;

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

  Future<void> _showTimelessSolution() async {
    if (_isSubmittingAnswer || _isResolvingSolution || _isPausedForAnimation || _isPausedForDialog || _isGameOver) return;
    AudioService.instance.playClick();

    bool isWord = currentRoundType == 'word';
    _isResolvingSolution = true;
    final String bestWord;
    final List<String> mathSteps;
    try {
      bestWord = isWord ? await _calculateRealLongestWord() : '';
      mathSteps = isWord ? const [] : await _calculateRealMathSteps();
    } finally {
      _isResolvingSolution = false;
    }
    if (!mounted || _isGameOver) return;

    showDialog(
      context: context,
      builder: (dialogContext) => SolutionDialog(
        isWord: isWord,
        bestWord: bestWord,
        mathSteps: mathSteps,
        onNext: () {
          AudioService.instance.playClick();
          Navigator.pop(dialogContext);
          _nextTurn();
        },
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
      await _recordCurrentSolution();
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

    JokerPickerDialog.show(context).then((char) {
      _isJokerDialogOpen = false;
      if (char == null || !mounted) return;
      if (!_isGameOver && (!widget.isTimed || remainingSeconds > 0)) {
        Haptics.selection();
        setState(() {
          selectedIndices.add(index);
          selectedLetters.add(char);
        });
      }
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
      child: GameBackground(child: Scaffold(
        backgroundColor: Colors.transparent,
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
                              errorSignal: _errorSignal,
                              onLetterTap: (index, char) {
                                if (isBoardPaused) return;
                                AudioService.instance.playClick(haptic: false);
                                Haptics.selection();
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
                              errorSignal: _errorSignal,
                              onOperatorTap: (op) {
                                if (isBoardPaused) return;
                                AudioService.instance.playClick(haptic: false);
                                Haptics.selection();
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
            PraiseOverlay(trigger: _praiseSignal),
            GameConfetti(controller: _confettiController, alignment: Alignment.centerLeft, blastDirection: -pi / 6, numberOfParticles: 10),
            GameConfetti(controller: _confettiController, alignment: Alignment.centerRight, blastDirection: -5 * pi / 6, numberOfParticles: 10),
          ],
        ),
      )),
    );
  }

  Widget _buildAppBar() {
    return GameHud(
      centerTitle: true,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      titleFontSize: 16,
      backIconSize: 24,
      title: widget.subMode == 'mix'
          ? 'Karışık Mod'
          : (currentRoundType == 'word' ? 'Aşama: Kelime' : 'Aşama: İşlem'),
      onBack: () async {
        if (await _onWillPop()) {
          if (mounted) Navigator.pop(context);
        }
      },
      trailing: [
        if (widget.isTimed)
          InkWell(
            onTap: (_isGameOver || remainingSeconds <= 0) ? null : _passQuestion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Text(
                'Pas (${widget.subMode == 'mix' ? '-10s' : '-5s'})',
                style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        if (widget.isTimed)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TimerChip(seconds: _remainingNotifier, warnAt: 5),
          ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return SizedBox(
      width: double.infinity,
      child: GameCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentRoundType == 'word' ? 'Kelime Puanı' : 'Toplanan Puan',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                CountUpText(value: score, style: AppText.counter(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            if (showDelta && scoreDeltaText != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(scoreDeltaText!, style: AppText.counter(color: AppColors.rose, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final bool isLocked = _isSubmittingAnswer ||
        _isPausedForAnimation ||
        _isPausedForDialog ||
        _isGameOver ||
        (widget.isTimed && remainingSeconds <= 0);

    return GameControlBar(
      items: [
        GameBarItem(
          flex: 2,
          child: GameButton(
            label: 'Sil',
            icon: Icons.backspace_rounded,
            stacked: true,
            variant: GameButtonVariant.secondary,
            fontSize: 11,
            onPressed: isLocked
                  ? null
                  : () {
                      AudioService.instance.playClick(haptic: false);
                      Haptics.selection();
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
          ),
        ),
        GameBarItem(
          flex: 2,
          child: GameButton(
            label: currentRoundType == 'word' ? 'Temizle' : 'Sıfırla',
            icon: currentRoundType == 'word' ? Icons.delete_sweep_rounded : Icons.restart_alt_rounded,
            stacked: true,
            variant: GameButtonVariant.secondary,
            fontSize: 11,
            onPressed: isLocked
                  ? null
                  : () {
                      AudioService.instance.playClick(haptic: false);
                      Haptics.selection();
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
          ),
        ),
        if (!widget.isTimed)
          GameBarItem(
            flex: 3,
            child: GameButton(
              label: 'Cevabı Göster',
              icon: Icons.lightbulb_rounded,
              stacked: true,
              variant: GameButtonVariant.accent,
              fontSize: 11,
              onPressed: isLocked ? null : _showTimelessSolution,
            ),
          ),
        GameBarItem(
          flex: 4,
          child: GameButton(
            label: currentRoundType == 'word' ? 'Onayla' : 'Tamamla',
            icon: Icons.check_rounded,
            emphasized: true,
            fontSize: 14,
            onPressed: isLocked
                ? null
                : () {
                    currentRoundType == 'word' ? _submitWord() : _submitMath();
                  },
          ),
        ),
      ],
    );
  }
}
