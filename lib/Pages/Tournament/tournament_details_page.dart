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
      // Sort matches:
      // 1. Live/Ongoing matches first
      // 2. Pending/Scheduled matches by match number
      // 3. Completed matches last by match number
      matches.sort((a, b) {
        if (a.status == b.status) {
          return a.matchNumber.compareTo(b.matchNumber);
        }
        
        // Custom priority
        int priority(String status) {
          if (status == 'Ongoing' || status == 'Live') return 0;
          if (status == 'Pending' || status == 'Scheduled') return 1;
          return 2;
        }
        
        return priority(a.status).compareTo(priority(b.status));
      });

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
        onMatchSubmitted: _loadMatches, // Updated to refresh matches
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
          elevation: 0,
          title: Text(_tournament!.name.toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1.0)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: kAccent,
            labelColor: kAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
            tabs: [
              Tab(text: 'MATCH SCHEDULE'),
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
    final upcomingMatches = _matches.where((m) => !m.isCompleted).toList();
    final completedMatchesList = _matches.where((m) => m.isCompleted).toList();
    
    TournamentMatch? nextMatch;
    if (upcomingMatches.isNotEmpty) {
      nextMatch = upcomingMatches.first;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTournamentStats(completed, total, progress),
          const SizedBox(height: 32),
          
          if (nextMatch != null) ...[
            const TechnicalSectionHeader(
              label: 'CURRENT / NEXT MATCH', 
              color: kAccent, 
              topPadding: 0
            ),
            const SizedBox(height: 12),
            MatchCard(
              match: nextMatch, 
              isHighlighted: true,
              onTap: () => _showStartMatchModal(nextMatch!),
            ),
            const SizedBox(height: 32),
          ],

          if (upcomingMatches.length > 1) ...[
            const TechnicalSectionHeader(label: 'UPCOMING QUEUE', color: Colors.white38, topPadding: 0),
            const SizedBox(height: 12),
            ...upcomingMatches.skip(1).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MatchCard(match: m, onTap: () => _showStartMatchModal(m)),
            )),
            const SizedBox(height: 32),
          ],

          if (completedMatchesList.isNotEmpty) ...[
            const TechnicalSectionHeader(label: 'COMPLETED MATCHES', color: kMuted, topPadding: 0),
            const SizedBox(height: 12),
            ...completedMatchesList.reversed.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MatchCard(match: m, onTap: () => _showStartMatchModal(m)),
            )),
          ],

          if (_matches.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('No matches generated yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            )),
        ],
      ),
    );
  }

  Widget _buildTournamentStats(int completed, int total, double progress) {
    return TechnicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOURNAMENT STATUS', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text(_tournament!.status.toUpperCase(), 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TEAMS', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text('$_teamCount', 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}% COMPLETE', 
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: kAccent, fontWeight: FontWeight.w900)),
              Text('$completed / $total MATCHES', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: 6,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccent.withValues(alpha: 0.5), kAccent],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: kAccent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback onTap;
  final bool isHighlighted;

  const MatchCard({
    super.key, 
    required this.match, 
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLive = match.status == 'Ongoing' || match.status == 'Live';
    final bool isCompleted = match.status == 'Completed';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: isHighlighted ? 0 : 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: TechnicalCard(
            padding: EdgeInsets.all(isHighlighted ? 20 : 16),
            child: Column(
              children: [
                _buildHeader(context, isLive, isCompleted),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _TeamInfo(
                      name: match.redTeamName ?? 'RED', 
                      color: Colors.redAccent, 
                      score: isCompleted ? match.redScore : null,
                      isWinner: match.redWins,
                      isLarge: isHighlighted,
                      isLeft: true,
                    )),
                    _buildVS(context, isCompleted),
                    Expanded(child: _TeamInfo(
                      name: match.blueTeamName ?? 'BLUE', 
                      color: Colors.blueAccent, 
                      score: isCompleted ? match.blueScore : null,
                      isWinner: match.blueWins,
                      isLarge: isHighlighted,
                      isLeft: false,
                    )),
                  ],
                ),
                if (isHighlighted && !isCompleted) ...[
                  const SizedBox(height: 20),
                  TechnicalButton(
                    label: isLive ? 'UPDATE SCORE' : 'START MATCH', 
                    onTap: onTap,
                    color: isLive ? Colors.orangeAccent : kAccent,
                    icon: isLive ? Icons.edit_note : Icons.play_arrow_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLive, bool isCompleted) {
    Color statusColor = Colors.white24;
    String statusText = 'UPCOMING';
    IconData statusIcon = Icons.schedule;

    if (isLive) {
      statusColor = Colors.orangeAccent;
      statusText = 'LIVE';
      statusIcon = Icons.sensors;
    } else if (isCompleted) {
      statusColor = kMuted;
      statusText = 'COMPLETED';
      statusIcon = Icons.check_circle_outline;
    } else if (isHighlighted) {
      statusColor = kAccent;
      statusText = 'NEXT MATCH';
      statusIcon = Icons.bolt;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  if (isLive) 
                    _PulseIndicator(color: statusColor)
                  else
                    Icon(statusIcon, color: statusColor, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 9,
                    ),
                  ),
                ],  
              ),
            ),
            const SizedBox(width: 10),
            Text(
              match.matchType.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: kForeground.withValues(alpha: 0.2)),
            ),
          ],
        ),
        Text(
          '#${match.matchNumber}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: kForeground.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildVS(BuildContext context, bool isCompleted) {
    return Container(
      width: 40,
      alignment: Alignment.center,
      child: Text(
        'VS',
        style: TextStyle(
          color: isCompleted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
          fontWeight: FontWeight.w900,
          fontSize: isHighlighted ? 18 : 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final String name;
  final Color color;
  final int? score;
  final bool isWinner;
  final bool isLarge;
  final bool isLeft;

  const _TeamInfo({
    required this.name,
    required this.color,
    this.score,
    this.isWinner = false,
    this.isLarge = false,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color.withValues(alpha: score != null && !isWinner ? 0.4 : 1.0),
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
              fontSize: isLarge ? 18 : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            Text(
              '$score',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: isWinner ? Colors.white : kForegroundMuted.withValues(alpha: 0.5),
                fontSize: isLarge ? 32 : 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
