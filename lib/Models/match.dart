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

  // Breakdown Stats
  final int redBlocksScored;
  final int blueBlocksScored;
  final int redLongGoalsControlled;
  final int blueLongGoalsControlled;
  final int redUpperGoalsControlled;
  final int blueUpperGoalsControlled;
  final int redLowerGoalsControlled;
  final int blueLowerGoalsControlled;
  final int redParkedRobots;
  final int blueParkedRobots;
  final bool redDisqualified;
  final bool blueDisqualified;

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
    this.redBlocksScored = 0,
    this.blueBlocksScored = 0,
    this.redLongGoalsControlled = 0,
    this.blueLongGoalsControlled = 0,
    this.redUpperGoalsControlled = 0,
    this.blueUpperGoalsControlled = 0,
    this.redLowerGoalsControlled = 0,
    this.blueLowerGoalsControlled = 0,
    this.redParkedRobots = 0,
    this.blueParkedRobots = 0,
    this.redDisqualified = false,
    this.blueDisqualified = false,
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
      redBlocksScored: json['red_blocks_scored'] ?? 0,
      blueBlocksScored: json['blue_blocks_scored'] ?? 0,
      redLongGoalsControlled: json['red_long_goals_controlled'] ?? 0,
      blueLongGoalsControlled: json['blue_long_goals_controlled'] ?? 0,
      redUpperGoalsControlled: json['red_upper_goals_controlled'] ?? 0,
      blueUpperGoalsControlled: json['blue_upper_goals_controlled'] ?? 0,
      redLowerGoalsControlled: json['red_lower_goals_controlled'] ?? 0,
      blueLowerGoalsControlled: json['blue_lower_goals_controlled'] ?? 0,
      redParkedRobots: json['red_parked_robots'] ?? 0,
      blueParkedRobots: json['blue_parked_robots'] ?? 0,
      redDisqualified: json['red_disqualified'] ?? false,
      blueDisqualified: json['blue_disqualified'] ?? false,
      redTeamName: json['red_team']?['team_name'],
      blueTeamName: json['blue_team']?['team_name'],
    );
  }
}
