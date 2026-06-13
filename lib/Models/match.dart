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
  final bool redAwp;
  final bool blueAwp;
  final String autonomousBonus;

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
    this.redAwp = false,
    this.blueAwp = false,
    this.autonomousBonus = 'None',
    this.redTeamName,
    this.blueTeamName,
  });

  bool get isCompleted => status == 'Completed';
  bool get isPending => status == 'Pending' || status == 'Scheduled';
  bool get isOngoing => status == 'Ongoing' || status == 'Live';

  bool get redWins => isCompleted && redScore > blueScore;
  bool get blueWins => isCompleted && blueScore > redScore;
  bool get isTie => isCompleted && redScore == blueScore;

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
      redAwp: json['red_awp'] ?? false,
      blueAwp: json['blue_awp'] ?? false,
      autonomousBonus: json['autonomous_bonus'] ?? 'None',
      redTeamName: json['red_team']?['team_name'],
      blueTeamName: json['blue_team']?['team_name'],
    );
  }
}
