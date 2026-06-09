class Ranking {
  final String tournamentId;
  final int teamId;
  final int wins;
  final int losses;
  final int ties;
  final int matchesPlayed;
  final int totalPointsScored;
  final int totalPointsConceded;
  final int rankingPoints;

  // Optional relations
  String? teamName;

  Ranking({
    required this.tournamentId,
    required this.teamId,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.matchesPlayed,
    required this.totalPointsScored,
    required this.totalPointsConceded,
    required this.rankingPoints,
    this.teamName,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      tournamentId: json['tournament_id'],
      teamId: json['team_id'],
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      ties: json['ties'] ?? 0,
      matchesPlayed: json['matches_played'] ?? 0,
      totalPointsScored: json['total_points_scored'] ?? 0,
      totalPointsConceded: json['total_points_conceded'] ?? 0,
      rankingPoints: json['ranking_points'] ?? 0,
      teamName: json['teams']?['team_name'],
    );
  }
}
