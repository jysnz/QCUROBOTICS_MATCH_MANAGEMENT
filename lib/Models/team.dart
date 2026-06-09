class Team {
  final int id;
  final String teamName;

  Team({
    required this.id,
    required this.teamName,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      teamName: json['team_name'] ?? json['name'] ?? 'Unknown Team',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_name': teamName,
    };
  }
}
