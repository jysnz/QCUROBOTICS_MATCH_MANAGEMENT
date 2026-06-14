import 'package:flutter/material.dart';
import '../../Widgets/design_system.dart';
import '../../Services/tournament_service.dart';
import '../../Models/match.dart';

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
  static const int _longGoalBlockPoints = 3;
  static const int _longGoalOwnershipBonus = 10;
  static const int _autonomousBonusPoints = 10;
  static const int _centerGoalBlockPoints = 3;
  static const int _centerGoalTopFirstBlockPoints = 11;
  static const int _centerGoalBottomFirstBlockPoints = 9;
  static const int _parkingLowPoints = 8;
  static const int _parkingHighPoints = 30;

  final _redScoreController = TextEditingController();
  final _blueScoreController = TextEditingController();
  final TournamentService _service = TournamentService();
  bool _isSubmitting = false;

  bool _redAwp = false;
  bool _blueAwp = false;
  String _autonomousBonus = 'None';

  // Match Breakdown State
  int _longGoal1Red = 0;
  int _longGoal1Blue = 0;
  int _longGoal2Red = 0;
  int _longGoal2Blue = 0;
  _LongGoalSelection _longGoal1Selection = _LongGoalSelection.none;
  _LongGoalSelection _longGoal2Selection = _LongGoalSelection.none;

  // Middle Goal - Two counters per side
  int _midGoal1Red = 0;
  int _midGoal2Red = 0;
  int _midGoal1Blue = 0;
  int _midGoal2Blue = 0;
  _LongGoalSelection _centerTopFirstScorer = _LongGoalSelection.none;
  _LongGoalSelection _centerBottomFirstScorer = _LongGoalSelection.none;

  // Parking
  int _parkRed = 0;
  int _parkBlue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.matchData.status == 'Completed') {
      _redScoreController.text = widget.matchData.redScore.toString();
      _blueScoreController.text = widget.matchData.blueScore.toString();
      _redAwp = widget.matchData.redAwp;
      _blueAwp = widget.matchData.blueAwp;
      _autonomousBonus = widget.matchData.autonomousBonus;
    } else {
      _recalculateScores();
    }
  }

  Future<void> _submitScore() async {
    if (widget.matchData.status != 'Completed') {
      _recalculateScores();
    }

    final redScore = int.tryParse(_redScoreController.text.trim());
    final blueScore = int.tryParse(_blueScoreController.text.trim());

    if (redScore == null || blueScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric scores for both teams'),
        ),
      );
      return;
    }

    if (redScore < 0 || blueScore < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores cannot be negative')),
      );
      return;
    }

    // --- Calculate Breakdown Stats ---
    
    // Red Stats
    final int redBlocksScored = _longGoal1Red + _longGoal2Red + _midGoal1Red + _midGoal2Red;
    final int redLongGoalsControlled = 
        (_longGoal1Selection == _LongGoalSelection.left ? 1 : 0) + 
        (_longGoal2Selection == _LongGoalSelection.left ? 1 : 0);
    final int redUpperGoalsControlled = (_midGoal1Red > _midGoal1Blue ? 1 : 0);
    final int redLowerGoalsControlled = (_midGoal2Red > _midGoal2Blue ? 1 : 0);
    final int redParkedRobots = _parkRed;

    // Blue Stats
    final int blueBlocksScored = _longGoal1Blue + _longGoal2Blue + _midGoal1Blue + _midGoal2Blue;
    final int blueLongGoalsControlled = 
        (_longGoal1Selection == _LongGoalSelection.right ? 1 : 0) + 
        (_longGoal2Selection == _LongGoalSelection.right ? 1 : 0);
    final int blueUpperGoalsControlled = (_midGoal1Blue > _midGoal1Red ? 1 : 0);
    final int blueLowerGoalsControlled = (_midGoal2Blue > _midGoal2Red ? 1 : 0);
    final int blueParkedRobots = _parkBlue;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitMatchScore(
        widget.matchData.id,
        redScore,
        blueScore,
        redAwp: _redAwp,
        blueAwp: _blueAwp,
        autonomousBonus: _autonomousBonus,
        redBlocksScored: redBlocksScored,
        blueBlocksScored: blueBlocksScored,
        redLongGoalsControlled: redLongGoalsControlled,
        blueLongGoalsControlled: blueLongGoalsControlled,
        redUpperGoalsControlled: redUpperGoalsControlled,
        blueUpperGoalsControlled: blueUpperGoalsControlled,
        redLowerGoalsControlled: redLowerGoalsControlled,
        blueLowerGoalsControlled: blueLowerGoalsControlled,
        redParkedRobots: redParkedRobots,
        blueParkedRobots: blueParkedRobots,
      );
      await _service.completeTournamentIfFinished(
        widget.matchData.tournamentId,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onMatchSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match score submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit score: $e')));
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
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white38),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.matchData.matchType.toUpperCase()} MATCH #${widget.matchData.matchNumber}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 1.0,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (widget.matchData.status == 'Completed')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kMuted.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: kMuted,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _ScoreInputCard(
                        teamName: widget.matchData.redTeamName ?? 'Red Team',
                        color: Colors.redAccent,
                        controller: _redScoreController,
                        enabled: widget.matchData.status != 'Completed',
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _AwpCheckbox(
                        label: 'Earned AWP',
                        color: Colors.redAccent,
                        value: _redAwp,
                        onChanged: widget.matchData.status != 'Completed'
                            ? (val) => setState(() => _redAwp = val ?? false)
                            : null,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white12,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _ScoreInputCard(
                        teamName: widget.matchData.blueTeamName ?? 'Blue Team',
                        color: Colors.blueAccent,
                        controller: _blueScoreController,
                        enabled: widget.matchData.status != 'Completed',
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _AwpCheckbox(
                        label: 'Earned AWP',
                        color: Colors.blueAccent,
                        value: _blueAwp,
                        onChanged: widget.matchData.status != 'Completed'
                            ? (val) => setState(() => _blueAwp = val ?? false)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const TechnicalSectionHeader(
              label: 'AUTONOMOUS BONUS',
              color: kAccent,
              topPadding: 0,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BonusButton(
                  label: 'RED',
                  isSelected: _autonomousBonus == 'Red',
                  color: Colors.redAccent,
                  onTap: widget.matchData.status != 'Completed'
                      ? () => _updateScoreBreakdown(() {
                          _autonomousBonus = 'Red';
                        })
                      : null,
                ),
                const SizedBox(width: 8),
                _BonusButton(
                  label: 'NONE',
                  isSelected: _autonomousBonus == 'None',
                  color: Colors.white10,
                  onTap: widget.matchData.status != 'Completed'
                      ? () => _updateScoreBreakdown(() {
                          _autonomousBonus = 'None';
                        })
                      : null,
                ),
                const SizedBox(width: 8),
                _BonusButton(
                  label: 'BLUE',
                  isSelected: _autonomousBonus == 'Blue',
                  color: Colors.blueAccent,
                  onTap: widget.matchData.status != 'Completed'
                      ? () => _updateScoreBreakdown(() {
                          _autonomousBonus = 'Blue';
                        })
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const TechnicalSectionHeader(
              label: 'MATCH BREAKDOWN',
              color: Colors.white24,
              topPadding: 0,
            ),
            TechnicalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Long Goal 1
                  _BreakdownRow(
                    image: Stack(
                      alignment: Alignment.center,
                      children: [
                        const BreakdownImage(
                          path: 'Images/long_goal_updated.png',
                          height: 80,
                        ),
                        Positioned(
                          bottom: 0,
                          child: _TripleButtonControl(
                            gap: -8,
                            selection: _longGoal1Selection,
                            onLeft: () => _updateScoreBreakdown(() {
                              _longGoal1Selection = _LongGoalSelection.left;
                            }),
                            onCenter: () => _updateScoreBreakdown(() {
                              _longGoal1Selection = _LongGoalSelection.center;
                            }),
                            onRight: () => _updateScoreBreakdown(() {
                              _longGoal1Selection = _LongGoalSelection.right;
                            }),
                            enabled: widget.matchData.status != 'Completed',
                          ),
                        ),
                      ],
                    ),
                    leftContent: _ValueDisplay(
                      value: _longGoal1Red,
                      color: Colors.redAccent,
                      onChanged: (v) => _updateScoreBreakdown(() {
                        _longGoal1Red = v;
                      }),
                      enabled: widget.matchData.status != 'Completed',
                    ),
                    rightContent: _ValueDisplay(
                      value: _longGoal1Blue,
                      color: Colors.blueAccent,
                      onChanged: (v) => _updateScoreBreakdown(() {
                        _longGoal1Blue = v;
                      }),
                      enabled: widget.matchData.status != 'Completed',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Long Goal 2
                  _BreakdownRow(
                    image: Stack(
                      alignment: Alignment.center,
                      children: [
                        const BreakdownImage(
                          path: 'Images/long_goal_updated.png',
                          height: 80,
                        ),
                        Positioned(
                          bottom: 0,
                          child: _TripleButtonControl(
                            gap: -8,
                            selection: _longGoal2Selection,
                            onLeft: () => _updateScoreBreakdown(() {
                              _longGoal2Selection = _LongGoalSelection.left;
                            }),
                            onCenter: () => _updateScoreBreakdown(() {
                              _longGoal2Selection = _LongGoalSelection.center;
                            }),
                            onRight: () => _updateScoreBreakdown(() {
                              _longGoal2Selection = _LongGoalSelection.right;
                            }),
                            enabled: widget.matchData.status != 'Completed',
                          ),
                        ),
                      ],
                    ),
                    leftContent: _ValueDisplay(
                      value: _longGoal2Red,
                      color: Colors.redAccent,
                      onChanged: (v) => _updateScoreBreakdown(() {
                        _longGoal2Red = v;
                      }),
                      enabled: widget.matchData.status != 'Completed',
                    ),
                    rightContent: _ValueDisplay(
                      value: _longGoal2Blue,
                      color: Colors.blueAccent,
                      onChanged: (v) => _updateScoreBreakdown(() {
                        _longGoal2Blue = v;
                      }),
                      enabled: widget.matchData.status != 'Completed',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Middle Goal
                  _BreakdownRow(
                    image: const BreakdownImage(
                      path: 'Images/middle_goal.png',
                      height: 140,
                    ),
                    leftContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BreakdownCounter(
                          value: _midGoal1Red,
                          onChanged: (v) => _updateCenterGoalSection(
                            section: _CenterGoalSection.top,
                            alliance: _LongGoalSelection.left,
                            value: v,
                          ),
                          color: Colors.redAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                        const SizedBox(height: 12),
                        _BreakdownCounter(
                          value: _midGoal2Red,
                          onChanged: (v) => _updateCenterGoalSection(
                            section: _CenterGoalSection.bottom,
                            alliance: _LongGoalSelection.left,
                            value: v,
                          ),
                          color: Colors.redAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                      ],
                    ),
                    rightContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BreakdownCounter(
                          value: _midGoal1Blue,
                          onChanged: (v) => _updateCenterGoalSection(
                            section: _CenterGoalSection.top,
                            alliance: _LongGoalSelection.right,
                            value: v,
                          ),
                          color: Colors.blueAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                        const SizedBox(height: 12),
                        _BreakdownCounter(
                          value: _midGoal2Blue,
                          onChanged: (v) => _updateCenterGoalSection(
                            section: _CenterGoalSection.bottom,
                            alliance: _LongGoalSelection.right,
                            value: v,
                          ),
                          color: Colors.blueAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                      ],
                    ),
                  ),

                  // Parking Zone
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: BreakdownImage(
                              path: 'Images/parking_red.png',
                              height: 80,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: BreakdownImage(
                              path: 'Images/parking_blue.png',
                              height: 80,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: _BreakdownCounter(
                                value: _parkRed,
                                onChanged: (v) => _updateScoreBreakdown(() {
                                  _parkRed = v.clamp(0, 2);
                                }),
                                color: Colors.redAccent,
                                enabled: widget.matchData.status != 'Completed',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: _BreakdownCounter(
                                value: _parkBlue,
                                onChanged: (v) => _updateScoreBreakdown(() {
                                  _parkBlue = v.clamp(0, 2);
                                }),
                                color: Colors.blueAccent,
                                enabled: widget.matchData.status != 'Completed',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (widget.matchData.status != 'Completed')
              TechnicalButton(
                label: 'Submit Score',
                isLoading: _isSubmitting,
                onTap: _submitScore,
                icon: Icons.check_circle_outline,
              )
            else
              TechnicalButton(
                label: 'Close',
                color: kMuted,
                onTap: () => Navigator.pop(context),
                icon: Icons.close_rounded,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _updateScoreBreakdown(VoidCallback update) {
    setState(() {
      update();
      _recalculateScores();
    });
  }

  void _updateCenterGoalSection({
    required _CenterGoalSection section,
    required _LongGoalSelection alliance,
    required int value,
  }) {
    _updateScoreBreakdown(() {
      final oldRed = section == _CenterGoalSection.top
          ? _midGoal1Red
          : _midGoal2Red;
      final oldBlue = section == _CenterGoalSection.top
          ? _midGoal1Blue
          : _midGoal2Blue;
      final newRed = alliance == _LongGoalSelection.left ? value : oldRed;
      final newBlue = alliance == _LongGoalSelection.right ? value : oldBlue;
      var firstScorer = section == _CenterGoalSection.top
          ? _centerTopFirstScorer
          : _centerBottomFirstScorer;

      if (oldRed == 0 && oldBlue == 0 && value > 0) {
        firstScorer = alliance;
      }
      if (newRed == 0 && newBlue == 0) {
        firstScorer = _LongGoalSelection.none;
      } else if (firstScorer == _LongGoalSelection.none) {
        if (newRed > 0 && newBlue == 0) {
          firstScorer = _LongGoalSelection.left;
        } else if (newBlue > 0 && newRed == 0) {
          firstScorer = _LongGoalSelection.right;
        }
      }

      if (section == _CenterGoalSection.top) {
        _midGoal1Red = newRed;
        _midGoal1Blue = newBlue;
        _centerTopFirstScorer = firstScorer;
      } else {
        _midGoal2Red = newRed;
        _midGoal2Blue = newBlue;
        _centerBottomFirstScorer = firstScorer;
      }
    });
  }

  void _recalculateScores() {
    final redScore =
        _longGoalScore(
          alliance: _LongGoalSelection.left,
          redBlocks: _longGoal1Red,
          blueBlocks: _longGoal1Blue,
          ownership: _longGoal1Selection,
        ) +
        _longGoalScore(
          alliance: _LongGoalSelection.left,
          redBlocks: _longGoal2Red,
          blueBlocks: _longGoal2Blue,
          ownership: _longGoal2Selection,
        ) +
        _centerGoalSectionScore(
          alliance: _LongGoalSelection.left,
          redBlocks: _midGoal1Red,
          blueBlocks: _midGoal1Blue,
          firstBlockPoints: _centerGoalTopFirstBlockPoints,
        ) +
        _centerGoalSectionScore(
          alliance: _LongGoalSelection.left,
          redBlocks: _midGoal2Red,
          blueBlocks: _midGoal2Blue,
          firstBlockPoints: _centerGoalBottomFirstBlockPoints,
        ) +
        _autonomousScore('Red') +
        _parkingScore(_parkRed);
    final blueScore =
        _longGoalScore(
          alliance: _LongGoalSelection.right,
          redBlocks: _longGoal1Red,
          blueBlocks: _longGoal1Blue,
          ownership: _longGoal1Selection,
        ) +
        _longGoalScore(
          alliance: _LongGoalSelection.right,
          redBlocks: _longGoal2Red,
          blueBlocks: _longGoal2Blue,
          ownership: _longGoal2Selection,
        ) +
        _centerGoalSectionScore(
          alliance: _LongGoalSelection.right,
          redBlocks: _midGoal1Red,
          blueBlocks: _midGoal1Blue,
          firstBlockPoints: _centerGoalTopFirstBlockPoints,
        ) +
        _centerGoalSectionScore(
          alliance: _LongGoalSelection.right,
          redBlocks: _midGoal2Red,
          blueBlocks: _midGoal2Blue,
          firstBlockPoints: _centerGoalBottomFirstBlockPoints,
        ) +
        _autonomousScore('Blue') +
        _parkingScore(_parkBlue);

    _setScoreText(_redScoreController, redScore);
    _setScoreText(_blueScoreController, blueScore);
  }

  int _longGoalScore({
    required _LongGoalSelection alliance,
    required int redBlocks,
    required int blueBlocks,
    required _LongGoalSelection ownership,
  }) {
    final allianceBlocks = alliance == _LongGoalSelection.left
        ? redBlocks
        : blueBlocks;
    final ownershipBonus = ownership == alliance && allianceBlocks > 0
        ? _longGoalOwnershipBonus
        : 0;

    return (allianceBlocks * _longGoalBlockPoints) + ownershipBonus;
  }

  int _autonomousScore(String alliance) {
    return _autonomousBonus == alliance ? _autonomousBonusPoints : 0;
  }

  int _centerGoalSectionScore({
    required _LongGoalSelection alliance,
    required int redBlocks,
    required int blueBlocks,
    required int firstBlockPoints,
  }) {
    final allianceBlocks = alliance == _LongGoalSelection.left ? redBlocks : blueBlocks;
    final opponentBlocks = alliance == _LongGoalSelection.left ? blueBlocks : redBlocks;

    if (allianceBlocks <= 0) return 0;

    // Bonus points (11 for top, 9 for bottom) if this team has MORE blocks
    if (allianceBlocks > opponentBlocks) {
      return firstBlockPoints + ((allianceBlocks - 1) * _centerGoalBlockPoints);
    }

    // Standard points (3 each) if tied or having fewer blocks
    return allianceBlocks * _centerGoalBlockPoints;
  }

  int _parkingScore(int parkedRobots) {
    return switch (parkedRobots) {
      1 => _parkingLowPoints,
      2 => _parkingHighPoints,
      _ => 0,
    };
  }

  void _setScoreText(TextEditingController controller, int score) {
    final text = score.toString();
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class BreakdownImage extends StatelessWidget {
  final String path;
  final double height;

  const BreakdownImage({super.key, required this.path, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(path, height: height, fit: BoxFit.contain);
  }
}

class _AwpCheckbox extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _AwpCheckbox({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: color,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: value ? Colors.white : kForegroundMuted,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const _BonusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : kSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.white10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected ? color : kForegroundMuted,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreInputCard extends StatelessWidget {
  final String teamName;
  final Color color;
  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;

  const _ScoreInputCard({
    required this.teamName,
    required this.color,
    required this.controller,
    required this.enabled,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TechnicalCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              teamName.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color, fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 32),
            decoration: InputDecoration(
              hintText: '00',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.05)),
              filled: true,
              fillColor: kBackground.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Widget image;
  final Widget leftContent;
  final Widget rightContent;

  const _BreakdownRow({
    required this.image,
    required this.leftContent,
    required this.rightContent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leftContent,
        const SizedBox(width: 8),
        Expanded(child: image),
        const SizedBox(width: 8),
        rightContent,
      ],
    );
  }
}

class _BreakdownCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Color color;
  final bool enabled;

  const _BreakdownCounter({
    required this.value,
    required this.onChanged,
    required this.color,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = value > 0;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.05)
            : kBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterBtn(
            icon: Icons.remove_rounded,
            onTap: enabled && value > 0 ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.1),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          _CounterBtn(
            icon: Icons.add_rounded,
            onTap: enabled ? () => onChanged(value + 1) : null,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  const _CounterBtn({
    required this.icon,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(8.0),
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: padding,
        child: Icon(
          icon,
          size: iconSize,
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.03)
              : (color?.withValues(alpha: 0.8) ?? Colors.white38),
        ),
      ),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  final int value;
  final Color color;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const _ValueDisplay({
    required this.value,
    required this.color,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = value > 0;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.05)
            : kBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterBtn(
            icon: Icons.remove_rounded,
            onTap: enabled && value > 0 && onChanged != null
                ? () => onChanged!(value - 1)
                : null,
            padding: const EdgeInsets.all(4),
            iconSize: 14,
          ),
          Container(
            width: 42,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.1),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          _CounterBtn(
            icon: Icons.add_rounded,
            onTap: enabled && onChanged != null
                ? () => onChanged!(value + 1)
                : null,
            color: color,
            padding: const EdgeInsets.all(4),
            iconSize: 14,
          ),
        ],
      ),
    );
  }
}

enum _LongGoalSelection { none, left, center, right }

enum _CenterGoalSection { top, bottom }

class _TripleButtonControl extends StatelessWidget {
  final VoidCallback? onLeft;
  final VoidCallback? onCenter;
  final VoidCallback? onRight;
  final bool enabled;
  final _LongGoalSelection selection;
  final double gap;

  const _TripleButtonControl({
    this.onLeft,
    this.onCenter,
    this.onRight,
    this.enabled = true,
    this.selection = _LongGoalSelection.none,
    this.gap = 0,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 40;
    const double buttonSize = 44;
    final double totalWidth = (buttonSize * 3) + (gap * 2);

    return SizedBox(
      width: totalWidth,
      height: buttonSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _ControlBtn(
              shape: _LongGoalButtonShape.triangle,
              isLeft: true,
              isSelected: selection == _LongGoalSelection.left,
              onTap: onLeft,
              enabled: enabled,
              outlineColor: Colors.white,
              activeColor: Colors.redAccent,
              iconSize: iconSize,
              size: buttonSize,
            ),
          ),
          Positioned(
            left: buttonSize + gap,
            top: 0,
            child: _ControlBtn(
              shape: _LongGoalButtonShape.x,
              isSelected: selection == _LongGoalSelection.center,
              onTap: onCenter,
              enabled: enabled,
              outlineColor: Colors.white,
              activeColor: Colors.black,
              iconSize: iconSize,
              size: buttonSize,
            ),
          ),
          Positioned(
            left: (buttonSize * 2) + (gap * 2),
            top: 0,
            child: _ControlBtn(
              shape: _LongGoalButtonShape.triangle,
              isSelected: selection == _LongGoalSelection.right,
              onTap: onRight,
              enabled: enabled,
              outlineColor: Colors.white,
              activeColor: Colors.blueAccent,
              iconSize: iconSize,
              size: buttonSize,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LongGoalButtonShape { triangle, x }

class _ControlBtn extends StatefulWidget {
  final _LongGoalButtonShape shape;
  final bool isLeft;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;
  final Color outlineColor;
  final Color activeColor;
  final double iconSize;
  final double size;

  const _ControlBtn({
    required this.shape,
    this.isLeft = false,
    this.isSelected = false,
    this.onTap,
    this.enabled = true,
    required this.outlineColor,
    required this.activeColor,
    this.iconSize = 32,
    this.size = 44,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.enabled
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -(widget.iconSize / 2) + (widget.size / 2),
              top: -(widget.iconSize / 2) + (widget.size / 2),
              child: IgnorePointer(
                child: Opacity(
                  opacity: _isPressed ? 0.82 : 1,
                  child: CustomPaint(
                    size: Size.square(widget.iconSize),
                    painter: _LongGoalButtonPainter(
                      shape: widget.shape,
                      isLeft: widget.isLeft,
                      isSelected: widget.isSelected,
                      fillColor: widget.activeColor,
                      glowColor: widget.shape == _LongGoalButtonShape.x
                          ? Colors.white
                          : widget.activeColor,
                      outlineColor: widget.enabled
                          ? widget.outlineColor
                          : widget.outlineColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LongGoalButtonPainter extends CustomPainter {
  final _LongGoalButtonShape shape;
  final bool isLeft;
  final bool isSelected;
  final Color fillColor;
  final Color glowColor;
  final Color outlineColor;

  const _LongGoalButtonPainter({
    required this.shape,
    required this.isLeft,
    required this.isSelected,
    required this.fillColor,
    required this.glowColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case _LongGoalButtonShape.triangle:
        _paintTriangle(canvas, size);
        break;
      case _LongGoalButtonShape.x:
        _paintX(canvas, size);
        break;
    }
  }

  void _paintTriangle(Canvas canvas, Size size) {
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(size.width * 0.16, size.height * 0.5)
        ..lineTo(size.width * 0.82, size.height * 0.12)
        ..lineTo(size.width * 0.82, size.height * 0.88);
    } else {
      path
        ..moveTo(size.width * 0.84, size.height * 0.5)
        ..lineTo(size.width * 0.18, size.height * 0.12)
        ..lineTo(size.width * 0.18, size.height * 0.88);
    }
    path.close();

    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = glowColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintX(Canvas canvas, Size size) {
    final startInset = size.width * 0.24;
    final endInset = size.width * 0.76;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 8 : 3
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    if (isSelected) {
      canvas.drawLine(
        Offset(startInset, startInset),
        Offset(endInset, endInset),
        glowPaint,
      );
      canvas.drawLine(
        Offset(endInset, startInset),
        Offset(startInset, endInset),
        glowPaint,
      );
    }

    canvas.drawLine(
      Offset(startInset, startInset),
      Offset(endInset, endInset),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(endInset, startInset),
      Offset(startInset, endInset),
      outlinePaint,
    );

    if (!isSelected) return;

    canvas.drawLine(
      Offset(startInset, startInset),
      Offset(endInset, endInset),
      fillPaint,
    );
    canvas.drawLine(
      Offset(endInset, startInset),
      Offset(startInset, endInset),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LongGoalButtonPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        isLeft != oldDelegate.isLeft ||
        isSelected != oldDelegate.isSelected ||
        fillColor != oldDelegate.fillColor ||
        glowColor != oldDelegate.glowColor ||
        outlineColor != oldDelegate.outlineColor;
  }
}
