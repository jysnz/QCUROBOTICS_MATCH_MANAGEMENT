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

  Future<List<int>> findOrCreateTeams(List<String> teamNames) async {
    List<int> ids = [];
    for (final name in teamNames) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) continue;

      // Try to find
      final existing = await _client
          .from('teams')
          .select('id')
          .eq('team_name', trimmedName)
          .maybeSingle();
      
      if (existing != null) {
        ids.add(existing['id']);
      } else {
        // Create
        final created = await _client.from('teams').insert({
          'team_name': trimmedName
        }).select('id').single();
        ids.add(created['id']);
      }
    }
    return ids;
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
        .eq('tournament_id', tournamentId);
    
    final matches = (response as List).map((json) => TournamentMatch.fromJson(json)).toList();
    
    // Sort by type priority: Qualification (1) -> Semi-Final (2) -> Final (3)
    // Then by match number
    matches.sort((a, b) {
      final typeOrder = {
        'Qualification': 1,
        'Semi-Final': 2,
        'Final': 3,
      };
      
      final orderA = typeOrder[a.matchType] ?? 99;
      final orderB = typeOrder[b.matchType] ?? 99;
      
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.matchNumber.compareTo(b.matchNumber);
    });
    
    return matches;
  }

  Future<void> submitMatchScore(String matchId, int redScore, int blueScore, {bool redAwp = false, bool blueAwp = false, String autonomousBonus = 'None'}) async {
    // 1. Submit the score
    final response = await _client.from('matches').update({
      'red_score': redScore,
      'blue_score': blueScore,
      'red_awp': redAwp,
      'blue_awp': blueAwp,
      'autonomous_bonus': autonomousBonus,
      'status': 'Completed'
    }).eq('id', matchId).select('tournament_id, match_type').single();

    final String tournamentId = response['tournament_id'];
    final String matchType = response['match_type'];

    // 2. Check for progression
    await _checkAndProgressTournament(tournamentId, matchType);
  }

  Future<void> _checkAndProgressTournament(String tournamentId, String completedMatchType) async {
    // Check if all matches of the current type are completed
    final matchesResponse = await _client
        .from('matches')
        .select('status')
        .eq('tournament_id', tournamentId)
        .eq('match_type', completedMatchType);
    
    final matches = matchesResponse as List;
    final allCompleted = matches.every((m) => m['status'] == 'Completed');

    if (allCompleted) {
      if (completedMatchType == 'Qualification') {
        await _generateSemiFinals(tournamentId);
      } else if (completedMatchType == 'Semi-Final') {
        await _generateFinal(tournamentId);
      } else if (completedMatchType == 'Final') {
        await completeTournamentIfFinished(tournamentId);
      }
    }
  }

  Future<void> _generateSemiFinals(String tournamentId) async {
    // Check if semi-finals already exist
    final existing = await _client
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('match_type', 'Semi-Final')
        .maybeSingle();
    
    if (existing != null) return;

    // Get top 4 teams
    final rankings = await getTournamentRankings(tournamentId);
    if (rankings.length < 4) return;

    final top4 = rankings.take(4).toList();

    // Match 1: 1st vs 4th
    await _client.from('matches').insert({
      'tournament_id': tournamentId,
      'match_number': 1,
      'match_type': 'Semi-Final',
      'red_team_id': top4[0].teamId,
      'blue_team_id': top4[3].teamId,
      'status': 'Pending'
    });

    // Match 2: 2nd vs 3rd
    await _client.from('matches').insert({
      'tournament_id': tournamentId,
      'match_number': 2,
      'match_type': 'Semi-Final',
      'red_team_id': top4[1].teamId,
      'blue_team_id': top4[2].teamId,
      'status': 'Pending'
    });
  }

  Future<void> _generateFinal(String tournamentId) async {
    // Check if final already exists
    final existing = await _client
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('match_type', 'Final')
        .maybeSingle();
    
    if (existing != null) return;

    // Get Semi-Final winners
    final sfMatchesResponse = await _client
        .from('matches')
        .select('red_team_id, blue_team_id, red_score, blue_score')
        .eq('tournament_id', tournamentId)
        .eq('match_type', 'Semi-Final')
        .order('match_number');
    
    final sfMatches = sfMatchesResponse as List;
    if (sfMatches.length < 2) return;

    List<int> winners = [];
    for (final match in sfMatches) {
      if (match['red_score'] > match['blue_score']) {
        winners.add(match['red_team_id']);
      } else {
        winners.add(match['blue_team_id']);
      }
    }

    if (winners.length == 2) {
      await _client.from('matches').insert({
        'tournament_id': tournamentId,
        'match_number': 1,
        'match_type': 'Final',
        'red_team_id': winners[0],
        'blue_team_id': winners[1],
        'status': 'Pending'
      });
    }
  }

  // --- Rankings ---

  Future<List<Ranking>> getTournamentRankings(String tournamentId) async {
    final response = await _client
        .from('rankings')
        .select('*, teams(team_name)')
        .eq('tournament_id', tournamentId)
        .order('wp', ascending: false)
        .order('ap', ascending: false)
        .order('sp', ascending: false)
        .order('team_id', ascending: true);
    
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
