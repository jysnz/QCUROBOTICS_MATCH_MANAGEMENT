class Tournament {
  final String id;
  final String name;
  final DateTime tournamentDate;
  final String status;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.name,
    required this.tournamentDate,
    required this.status,
    required this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      tournamentDate: DateTime.parse(json['tournament_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tournament_date': tournamentDate.toIso8601String().split('T')[0],
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
