class TournamentMatch {
  final String id;
  final String tournamentId;
  final int matchNumber;
  final String matchType;
  final int redTeamId;
  final int blueTeamId;
  final int redScore;
  final int blueScore;
  final String status;

  // Optional relations
  String? redTeamName;
  String? blueTeamName;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.matchNumber,
    required this.matchType,
    required this.redTeamId,
    required this.blueTeamId,
    required this.redScore,
    required this.blueScore,
    required this.status,
    this.redTeamName,
    this.blueTeamName,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      tournamentId: json['tournament_id'],
      matchNumber: json['match_number'],
      matchType: json['match_type'] ?? 'Qualification',
      redTeamId: json['red_team_id'],
      blueTeamId: json['blue_team_id'],
      redScore: json['red_score'] ?? 0,
      blueScore: json['blue_score'] ?? 0,
      status: json['status'],
      redTeamName: json['red_team']?['team_name'],
      blueTeamName: json['blue_team']?['team_name'],
    );
  }
}
