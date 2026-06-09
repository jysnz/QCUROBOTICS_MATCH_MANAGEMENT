import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/tournament.dart';
import '../Models/team.dart';
import '../Models/match.dart';
import '../Models/ranking.dart';

class TournamentService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Tournaments ---

  Future<List<Tournament>> getRecentTournaments() async {
    final response = await _client
        .from('tournaments')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => Tournament.fromJson(json)).toList();
  }

  Future<Tournament> getTournament(String id) async {
    final response = await _client
        .from('tournaments')
        .select()
        .eq('id', id)
        .single();
    return Tournament.fromJson(response);
  }

  Future<int> getTournamentTeamCount(String tournamentId) async {
    final response = await _client
        .from('tournament_teams')
        .select('team_id')
        .eq('tournament_id', tournamentId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<Tournament> createTournament(String name, DateTime date, List<int> teamIds) async {
    // 1. Create Tournament
    final tResponse = await _client.from('tournaments').insert({
      'name': name,
      'tournament_date': date.toIso8601String().split('T')[0],
      'status': 'Ongoing'
    }).select().single();
    
    final tournament = Tournament.fromJson(tResponse);

    // 2. Add Teams
    if (teamIds.isNotEmpty) {
      final teamMappings = teamIds.map((tId) => {
        'tournament_id': tournament.id,
        'team_id': tId
      }).toList();
      await _client.from('tournament_teams').insert(teamMappings);
    }

    // 3. Generate Matches via RPC
    await _client.rpc('generate_qualification_matches', params: {
      'target_tournament_id': tournament.id
    });

    return tournament;
  }

  // --- Teams ---

  Future<List<Team>> getAllTeams() async {
    final response = await _client
        .from('teams')
        .select('id, team_name')
        .order('team_name');
    return (response as List).map((json) => Team.fromJson(json)).toList();
  }

  Future<List<Team>> getTournamentTeams(String tournamentId) async {
    final response = await _client
        .from('tournament_teams')
        .select('teams(id, team_name)')
        .eq('tournament_id', tournamentId);
    
    return (response as List).map((item) => Team.fromJson(item['teams'])).toList();
  }

  // --- Matches ---

  Future<List<TournamentMatch>> getTournamentMatches(String tournamentId) async {
    final response = await _client
        .from('matches')
        .select('*, red_team:teams!matches_red_team_id_fkey(team_name), blue_team:teams!matches_blue_team_id_fkey(team_name)')
        .eq('tournament_id', tournamentId)
        .order('match_number');
    return (response as List).map((json) => TournamentMatch.fromJson(json)).toList();
  }

  Future<void> submitMatchScore(String matchId, int redScore, int blueScore) async {
    await _client.from('matches').update({
      'red_score': redScore,
      'blue_score': blueScore,
      'status': 'Completed'
    }).eq('id', matchId);
  }

  // --- Rankings ---

  Future<List<Ranking>> getTournamentRankings(String tournamentId) async {
    final response = await _client
        .from('rankings')
        .select('*, teams(team_name)')
        .eq('tournament_id', tournamentId)
        .order('ranking_points', ascending: false)
        .order('total_points_scored', ascending: false)
        .order('total_points_conceded', ascending: true);
    
    return (response as List).map((json) => Ranking.fromJson(json)).toList();
  }

  // --- Completion ---
  Future<void> completeTournamentIfFinished(String tournamentId) async {
    final pendingCount = await _client
      .from('matches')
      .select('id')
      .eq('tournament_id', tournamentId)
      .neq('status', 'Completed')
      .count(CountOption.exact);
      
    if (pendingCount.count == 0) {
      await _client.from('tournaments').update({'status': 'Completed'}).eq('id', tournamentId);
    }
  }
}
