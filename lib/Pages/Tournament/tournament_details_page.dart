import 'package:flutter/material.dart';
import '../../Widgets/design_system.dart';
import '../../Services/tournament_service.dart';
import '../../Models/tournament.dart';
import '../../Models/match.dart';
import 'start_match_modal.dart';
import 'ranking_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  final TournamentService _service = TournamentService();
  Tournament? _tournament;
  List<TournamentMatch> _matches = [];
  int _teamCount = 0;
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }
  
  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:matches')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: widget.tournamentId,
          ),
          callback: (payload) {
            _loadMatches();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final t = await _service.getTournament(widget.tournamentId);
      final count = await _service.getTournamentTeamCount(widget.tournamentId);
      await _loadMatches();
      if (mounted) {
        setState(() {
          _tournament = t;
          _teamCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMatches() async {
    final matches = await _service.getTournamentMatches(widget.tournamentId);
    if (mounted) {
      setState(() {
        _matches = matches;
      });
    }
  }

  void _showStartMatchModal(TournamentMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StartMatchModal(
        matchData: match,
        onMatchSubmitted: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tournament == null) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    final completedMatches = _matches.where((m) => m.status == 'Completed').length;
    final totalMatches = _matches.length;
    final progress = totalMatches > 0 ? completedMatches / totalMatches : 0.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          backgroundColor: kSurface,
          title: Text(_tournament!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: kAccent,
            labelColor: kAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'SCHEDULE & INFO'),
              Tab(text: 'LIVE RANKINGS'),
            ],
          ),
        ),
        body: Stack(
          children: [
            const TechnicalGridBackground(),
            TabBarView(
              children: [
                _buildScheduleTab(completedMatches, totalMatches, progress),
                Padding(
                  padding: const EdgeInsets.all(kPadding),
                  child: RankingTable(tournamentId: widget.tournamentId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(int completed, int total, double progress) {
    final qualMatches = _matches.where((m) => m.matchType == 'Qualification').toList();
    final sfMatches = _matches.where((m) => m.matchType == 'Semi-Final').toList();
    final finalMatches = _matches.where((m) => m.matchType == 'Final').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechnicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${_tournament!.status}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Teams: $_teamCount', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress: ${(progress * 100).toInt()}%', style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('$completed / $total Matches', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: kAccent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          if (finalMatches.isNotEmpty) ...[
            const TechnicalSectionHeader(
              label: '🏆 THE GRAND FINALS', 
              color: Color(0xFFFFD700), 
              topPadding: 0
            ),
            const SizedBox(height: 12),
            ...finalMatches.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MatchRow(match: m, onTap: () => _showStartMatchModal(m)),
            )),
            const SizedBox(height: 32),
          ],

          if (sfMatches.isNotEmpty) ...[
            const TechnicalSectionHeader(label: 'SEMI-FINALS', color: kAccent, topPadding: 0),
            const SizedBox(height: 12),
            ...sfMatches.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MatchRow(match: m, onTap: () => _showStartMatchModal(m)),
            )),
            const SizedBox(height: 24),
          ],

          const TechnicalSectionHeader(label: 'QUALIFICATION MATCHES', color: Colors.white, topPadding: 0),
          const SizedBox(height: 12),
          if (qualMatches.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('No matches generated yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: qualMatches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final match = qualMatches[index];
                return _MatchRow(
                  match: match,
                  onTap: () => _showStartMatchModal(match),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback onTap;

  const _MatchRow({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == 'Completed';
    final redWins = isCompleted && match.redScore > match.blueScore;
    final blueWins = isCompleted && match.blueScore > match.redScore;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: isCompleted ? Colors.white.withValues(alpha: 0.1) : kAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text('#${match.matchNumber}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          match.redTeamName ?? 'Red',
                          style: TextStyle(color: Colors.redAccent, fontWeight: redWins ? FontWeight.w900 : FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        Text('${match.redScore}', style: TextStyle(color: Colors.white, fontWeight: redWins ? FontWeight.w900 : FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          match.blueTeamName ?? 'Blue',
                          style: TextStyle(color: Colors.blueAccent, fontWeight: blueWins ? FontWeight.w900 : FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        Text('${match.blueScore}', style: TextStyle(color: Colors.white, fontWeight: blueWins ? FontWeight.w900 : FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.play_circle_outline,
              color: isCompleted ? kMuted : kAccent,
            )
          ],
        ),
      ),
    );
  }
}
