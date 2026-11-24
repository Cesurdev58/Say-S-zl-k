import 'dart:math';

class UserProfile {
  final String uid;
  String username;
  String avatar;
  int gems;
  int totalScore;
  int highestSingleMatchScore;
  int gamesPlayed;
  bool hasUsedFreeNameChange;
  bool isStatsHidden;
  List<String> claimedQuests;

  List<String> purchasedAvatars;
  List<String> purchasedBorders;
  String selectedBorder;

  String lastResetDate;
  int dailyGamesPlayed;
  int dailyScore;
  int dailyExactMathMatches;
  int dailyWordQuestionsSeen;

  String longestWord;
  int exactMathMatches;
  int totalWordScore;
  int totalMathScore;

  int wordQuestionsSeen;
  int wordPasses;
  int wordCorrectAnswers;

  int mathQuestionsSeen;
  int mathPasses;
  int mathCorrectAnswers;

  int totalAnswerTimeSeconds;
  int xp;

  UserProfile({
    required this.uid,
    required this.username,
    this.avatar = 'boy',
    this.gems = 0,
    this.totalScore = 0,
    this.highestSingleMatchScore = 0,
    this.gamesPlayed = 0,
    this.hasUsedFreeNameChange = false,
    this.isStatsHidden = false,
    List<String>? claimedQuests,
    List<String>? purchasedAvatars,
    List<String>? purchasedBorders,
    this.selectedBorder = 'none',
    this.lastResetDate = '',
    this.dailyGamesPlayed = 0,
    this.dailyScore = 0,
    this.dailyExactMathMatches = 0,
    this.dailyWordQuestionsSeen = 0,
    this.longestWord = '',
    this.exactMathMatches = 0,
    this.totalWordScore = 0,
    this.totalMathScore = 0,
    this.wordQuestionsSeen = 0,
    this.wordPasses = 0,
    this.wordCorrectAnswers = 0,
    this.mathQuestionsSeen = 0,
    this.mathPasses = 0,
    this.mathCorrectAnswers = 0,
    this.totalAnswerTimeSeconds = 0,
    this.xp = 0,
  })  : claimedQuests = List<String>.from(claimedQuests ?? const []),
        purchasedAvatars = List<String>.from(purchasedAvatars ?? const ['boy', 'girl']),
        purchasedBorders = List<String>.from(purchasedBorders ?? const []);

  // --- SEVİYE VE XP MATEMATİĞİ ---
  int get level {
    int calcLevel = 1;
    int xpRemaining = xp;
    while (calcLevel < 9999) {
      int needed = (calcLevel < 50) ? (calcLevel * 100) + (calcLevel * calcLevel * 5) : 20000;
      if (xpRemaining >= needed) {
        xpRemaining -= needed;
        calcLevel++;
      } else {
        break;
      }
    }
    return calcLevel;
  }

  int get currentLevelXp {
    int calcLevel = 1;
    int xpRemaining = xp;
    while (calcLevel < 9999) {
      int needed = (calcLevel < 50) ? (calcLevel * 100) + (calcLevel * calcLevel * 5) : 20000;
      if (xpRemaining >= needed) {
        xpRemaining -= needed;
        calcLevel++;
      } else {
        break;
      }
    }
    return xpRemaining;
  }

  int get nextLevelXp {
    int lvl = level;
    if (lvl >= 9999) return 1;
    return (lvl < 50) ? (lvl * 100) + (lvl * lvl * 5) : 20000;
  }

  double get levelProgress {
    if (level >= 9999) return 1.0;
    return currentLevelXp / nextLevelXp;
  }

  // BASİT İSTATİSTİKLER
  int get totalQuestionsSeen => wordQuestionsSeen + mathQuestionsSeen;
  int get totalPasses => wordPasses + mathPasses;
  int get totalCorrectAnswers => wordCorrectAnswers + mathCorrectAnswers;

  int get averageScorePerGame => gamesPlayed == 0 ? 0 : totalScore ~/ gamesPlayed;
  double get averageAnswerTime => totalCorrectAnswers == 0 ? 0.0 : totalAnswerTimeSeconds / totalCorrectAnswers;

  double get wordSuccessRate => wordQuestionsSeen == 0 ? 0.0 : (wordCorrectAnswers / wordQuestionsSeen) * 100;
  double get wordPassRate => wordQuestionsSeen == 0 ? 0.0 : (wordPasses / wordQuestionsSeen) * 100;

  double get mathSuccessRate => mathQuestionsSeen == 0 ? 0.0 : (mathCorrectAnswers / mathQuestionsSeen) * 100;
  double get mathPassRate => mathQuestionsSeen == 0 ? 0.0 : (mathPasses / mathQuestionsSeen) * 100;

  // ZEKA PARADİGMASI
  double get wordIntelligencePower {
    if (wordQuestionsSeen == 0) return 0.0;
    double b = (wordCorrectAnswers / wordQuestionsSeen) * 100;
    double p = (wordPasses / wordQuestionsSeen) * 100;
    double h = averageAnswerTime;
    double speedBonus = max(0.0, (25.0 - h) / 25.0) * 20.0;
    double rawScore = (b * 0.65) - (p * 0.35) + speedBonus;
    double reliability = min(1.0, wordQuestionsSeen / 25.0);
    return max(0.0, rawScore * reliability);
  }

  double get mathIntelligencePower {
    if (mathQuestionsSeen == 0) return 0.0;
    double b = (mathCorrectAnswers / mathQuestionsSeen) * 100;
    double p = (mathPasses / mathQuestionsSeen) * 100;
    double h = averageAnswerTime;
    double speedBonus = max(0.0, (25.0 - h) / 25.0) * 20.0;
    double rawScore = (b * 0.65) - (p * 0.35) + speedBonus;
    double reliability = min(1.0, mathQuestionsSeen / 25.0);
    return max(0.0, rawScore * reliability);
  }

  int get wordPercentage {
    double w = wordIntelligencePower;
    double m = mathIntelligencePower;
    if (w == 0 && m == 0) return 50;
    return ((w / (w + m)) * 100).round();
  }

  int get mathPercentage {
    double w = wordIntelligencePower;
    double m = mathIntelligencePower;
    if (w == 0 && m == 0) return 50;
    return ((m / (w + m)) * 100).round();
  }

  String get dominantIntelligence {
    double w = wordIntelligencePower;
    double m = mathIntelligencePower;

    if (wordQuestionsSeen < 10 && mathQuestionsSeen < 10) return 'Analiz Ediliyor...';
    if (w >= 80 && m >= 80) return 'Üstün Zeka';

    double diff = (w - m).abs();
    if (diff <= 12 && w > 30) return 'Eşit Ağırlık';
    if (w > m) return 'Sözel Ağırlıklı';
    return 'Sayısal Ağırlıklı';
  }

  int get rankLevel {
    if (totalScore < 500) return 0;
    if (totalScore < 1500) return 1;
    if (totalScore < 3000) return 2;
    if (totalScore < 6000) return 3;
    if (totalScore < 12000) return 4;
    return 5;
  }

  String get rankName {
    if (totalScore < 500) return 'Çaylak';
    if (totalScore < 1500) return 'Amatör';
    if (totalScore < 3000) return 'Yetenekli';
    if (totalScore < 6000) return 'Uzman';
    if (totalScore < 12000) return 'Usta';
    return 'Deha';
  }

  double get rankProgress {
    if (totalScore < 500) return totalScore / 500;
    if (totalScore < 1500) return (totalScore - 500) / (1500 - 500);
    if (totalScore < 3000) return (totalScore - 1500) / (3000 - 1500);
    if (totalScore < 6000) return (totalScore - 3000) / (6000 - 3000);
    if (totalScore < 12000) return (totalScore - 6000) / (12000 - 6000);
    return 1.0;
  }
}