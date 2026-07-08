class RelationshipStats {
  final int totalMemories;
  final int totalGoals;
  final int completedGoals;
  final int totalQuizzes;
  final int quizzesAnswered;
  final int totalNotes;
  final int totalTasksCompleted;
  final Map<String, double> userFunds;

  const RelationshipStats({
    required this.totalMemories,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalQuizzes,
    required this.quizzesAnswered,
    required this.totalNotes,
    required this.totalTasksCompleted,
    required this.userFunds,
  });

  factory RelationshipStats.empty() {
    return const RelationshipStats(
      totalMemories: 0,
      totalGoals: 0,
      completedGoals: 0,
      totalQuizzes: 0,
      quizzesAnswered: 0,
      totalNotes: 0,
      totalTasksCompleted: 0,
      userFunds: {},
    );
  }
}
