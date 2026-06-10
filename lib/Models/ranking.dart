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
  final double wp;
  final double ap;
  final double sp;

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
    required this.wp,
    required this.ap,
    required this.sp,
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
      wp: (json['wp'] ?? 0).toDouble(),
      ap: (json['ap'] ?? 0).toDouble(),
      sp: (json['sp'] ?? 0).toDouble(),
      teamName: json['teams']?['team_name'],
    );
  }
}
