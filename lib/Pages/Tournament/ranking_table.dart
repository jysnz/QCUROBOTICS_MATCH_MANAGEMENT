import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Widgets/design_system.dart';
import '../../Models/ranking.dart';
import '../../Services/tournament_service.dart';

class RankingTable extends StatefulWidget {
  final String tournamentId;

  const RankingTable({super.key, required this.tournamentId});

  @override
  State<RankingTable> createState() => _RankingTableState();
}

class _RankingTableState extends State<RankingTable> {
  final TournamentService _service = TournamentService();
  List<Ranking> _rankings = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:rankings')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rankings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: widget.tournamentId,
          ),
          callback: (payload) {
            _fetchRankings();
          },
        )
        .subscribe();
  }

  Future<void> _fetchRankings() async {
    try {
      final rankings = await _service.getTournamentRankings(widget.tournamentId);
      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kAccent));
    }

    if (_rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, color: Colors.white.withValues(alpha: 0.1), size: 48),
            const SizedBox(height: 16),
            Text('RANKING SYSTEM OFFLINE', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('No data recorded for this tournament yet.', style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _rankings.length,
            itemBuilder: (context, index) {
              final r = _rankings[index];
              return _RankingRow(ranking: r, rank: index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 40, child: Text('RK', style: _headerStyle)),
          Expanded(child: Text('TEAM IDENTITY', style: _headerStyle)),
          SizedBox(width: 55, child: Text('WP', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 55, child: Text('AP', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 55, child: Text('SP', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 70, child: Text('W-L-T', style: _headerStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: kAccent, 
    fontSize: 9, 
    fontWeight: FontWeight.w900, 
    letterSpacing: 1.0
  );
}

class _RankingRow extends StatelessWidget {
  final Ranking ranking;
  final int rank;

  const _RankingRow({required this.ranking, required this.rank});

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = rank <= 3;
    Color rankColor = Colors.white38;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3 ? rankColor.withValues(alpha: 0.05) : kSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isTop3 ? rankColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40, 
            child: Text(
              '#$rank', 
              style: TextStyle(
                color: isTop3 ? rankColor : Colors.white24, 
                fontWeight: FontWeight.w900, 
                fontSize: 12
              )
            )
          ),
          Expanded(
            child: Text(
              (ranking.teamName ?? 'UNKNOWN').toUpperCase(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ),
          SizedBox(
            width: 55, 
            child: Text(
              ranking.wp.toStringAsFixed(2), 
              style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 12),
              textAlign: TextAlign.center,
            )
          ),
          SizedBox(
            width: 55, 
            child: Text(
              ranking.ap.toStringAsFixed(2), 
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
              textAlign: TextAlign.center,
            )
          ),
          SizedBox(
            width: 55, 
            child: Text(
              ranking.sp.toStringAsFixed(2), 
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
              textAlign: TextAlign.center,
            )
          ),
          SizedBox(
            width: 70, 
            child: Text(
              '${ranking.wins}-${ranking.losses}-${ranking.ties}', 
              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w500, fontSize: 11),
              textAlign: TextAlign.center,
            )
          ),
        ],
      ),
    );
  }
}
