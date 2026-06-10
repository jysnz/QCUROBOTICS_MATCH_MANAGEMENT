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
        child: Text('No rankings available.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: TechnicalCard(
        padding: EdgeInsets.zero,
        child: DataTable(
          headingTextStyle: const TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          dividerThickness: 0.5,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('RANK')),
            DataColumn(label: Text('TEAM')),
            DataColumn(label: Text('WP')),
            DataColumn(label: Text('AP')),
            DataColumn(label: Text('SP')),
            DataColumn(label: Text('W-L-T')),
            DataColumn(label: Text('PLAYED')),
          ],
          rows: List.generate(_rankings.length, (index) {
            final r = _rankings[index];
            final rank = index + 1;
            final isTop3 = rank <= 3;
            
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (rank == 1) return const Color(0xFFFFD700).withValues(alpha: 0.1); // Gold
                if (rank == 2) return const Color(0xFFC0C0C0).withValues(alpha: 0.1); // Silver
                if (rank == 3) return const Color(0xFFCD7F32).withValues(alpha: 0.1); // Bronze
                return null;
              }),
              cells: [
                DataCell(
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isTop3 ? kAccent : Colors.white70,
                    )
                  )
                ),
                DataCell(Text(r.teamName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.wp.toStringAsFixed(0)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold))),
                DataCell(Text('${r.ap.toStringAsFixed(1)}')),
                DataCell(Text('${r.sp.toStringAsFixed(1)}')),
                DataCell(Text('${r.wins}-${r.losses}-${r.ties}', style: const TextStyle(color: Colors.white54))),
                DataCell(Text('${r.matchesPlayed}', style: const TextStyle(color: Colors.white54))),
              ],
            );
          }),
        ),
      ),
    );
  }
}
