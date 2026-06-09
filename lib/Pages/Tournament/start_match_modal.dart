import 'package:flutter/material.dart';
import '../../Widgets/design_system.dart';
import '../../Services/tournament_service.dart';
import '../../Models/match.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StartMatchModal extends StatefulWidget {
  final TournamentMatch matchData;
  final VoidCallback onMatchSubmitted;

  const StartMatchModal({
    super.key,
    required this.matchData,
    required this.onMatchSubmitted,
  });

  @override
  State<StartMatchModal> createState() => _StartMatchModalState();
}

class _StartMatchModalState extends State<StartMatchModal> {
  final _redScoreController = TextEditingController();
  final _blueScoreController = TextEditingController();
  final TournamentService _service = TournamentService();
  bool _isSubmitting = false;

  Future<void> _submitScore() async {
    final redScore = int.tryParse(_redScoreController.text.trim());
    final blueScore = int.tryParse(_blueScoreController.text.trim());

    if (redScore == null || blueScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid numeric scores for both teams')));
      return;
    }
    
    if (redScore < 0 || blueScore < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scores cannot be negative')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.submitMatchScore(widget.matchData.id, redScore, blueScore);
      await _service.completeTournamentIfFinished(widget.matchData.tournamentId);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onMatchSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match score submitted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit score: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATCH #${widget.matchData.matchNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              if (widget.matchData.status == 'Completed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kMuted.withValues(alpha: 0.5)),
                  ),
                  child: const Text('COMPLETED', style: TextStyle(color: kMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _ScoreInputCard(
                  teamName: widget.matchData.redTeamName ?? 'Red Team',
                  color: Colors.redAccent,
                  controller: _redScoreController,
                  enabled: widget.matchData.status != 'Completed',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Expanded(
                child: _ScoreInputCard(
                  teamName: widget.matchData.blueTeamName ?? 'Blue Team',
                  color: Colors.blueAccent,
                  controller: _blueScoreController,
                  enabled: widget.matchData.status != 'Completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (widget.matchData.status != 'Completed')
            TechnicalButton(
              label: 'Submit Score',
              isLoading: _isSubmitting,
              onTap: _submitScore,
            )
          else
            TechnicalButton(
              label: 'Close',
              color: kMuted,
              onTap: () => Navigator.pop(context),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ScoreInputCard extends StatelessWidget {
  final String teamName;
  final Color color;
  final TextEditingController controller;
  final bool enabled;

  const _ScoreInputCard({
    required this.teamName,
    required this.color,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TechnicalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              teamName,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              filled: true,
              fillColor: kBackground.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
