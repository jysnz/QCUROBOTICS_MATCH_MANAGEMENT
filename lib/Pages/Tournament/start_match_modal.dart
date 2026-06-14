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
  
  // Middle Goal - Two counters per side
  int _midGoal1Red = 0;
  int _midGoal2Red = 0;
  int _midGoal1Blue = 0;
  int _midGoal2Blue = 0;

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
    }
  }

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
      await _service.submitMatchScore(
        widget.matchData.id, 
        redScore, 
        blueScore,
        redAwp: _redAwp,
        blueAwp: _blueAwp,
        autonomousBonus: _autonomousBonus,
      );
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
                Text(
                  'MATCH #${widget.matchData.matchNumber}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 1.0, fontSize: 18),
                ),
                if (widget.matchData.status == 'Completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kMuted.withValues(alpha: 0.2)),
                    ),
                    child: Text('COMPLETED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: kMuted, fontSize: 8)),
                  )
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
                  child: Text('VS', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 18, fontStyle: FontStyle.italic)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _ScoreInputCard(
                        teamName: widget.matchData.blueTeamName ?? 'Blue Team',
                        color: Colors.blueAccent,
                        controller: _blueScoreController,
                        enabled: widget.matchData.status != 'Completed',
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
            const TechnicalSectionHeader(label: 'AUTONOMOUS BONUS', color: kAccent, topPadding: 0),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BonusButton(
                  label: 'RED',
                  isSelected: _autonomousBonus == 'Red',
                  color: Colors.redAccent,
                  onTap: widget.matchData.status != 'Completed' 
                    ? () => setState(() => _autonomousBonus = 'Red') 
                    : null,
                ),
                const SizedBox(width: 8),
                _BonusButton(
                  label: 'NONE',
                  isSelected: _autonomousBonus == 'None',
                  color: Colors.white10,
                  onTap: widget.matchData.status != 'Completed' 
                    ? () => setState(() => _autonomousBonus = 'None') 
                    : null,
                ),
                const SizedBox(width: 8),
                _BonusButton(
                  label: 'BLUE',
                  isSelected: _autonomousBonus == 'Blue',
                  color: Colors.blueAccent,
                  onTap: widget.matchData.status != 'Completed' 
                    ? () => setState(() => _autonomousBonus = 'Blue') 
                    : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const TechnicalSectionHeader(label: 'MATCH BREAKDOWN', color: Colors.white24, topPadding: 0),
            TechnicalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Long Goal 1
                  _BreakdownRow(
                    image: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BreakdownImage(path: 'Images/long_goal.png', height: 80),
                        const SizedBox(height: 12),
                        _TripleButtonControl(
                          onLeft: () => setState(() => _longGoal1Red++),
                          onCenter: () => setState(() {
                            _longGoal1Red = 0;
                            _longGoal1Blue = 0;
                          }),
                          onRight: () => setState(() => _longGoal1Blue++),
                          enabled: widget.matchData.status != 'Completed',
                        ),
                      ],
                    ),
                    leftContent: _ValueDisplay(value: _longGoal1Red, color: Colors.redAccent),
                    rightContent: _ValueDisplay(value: _longGoal1Blue, color: Colors.blueAccent),
                  ),
                  
                  const SizedBox(height: 16),

                  // Long Goal 2
                  _BreakdownRow(
                    image: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BreakdownImage(path: 'Images/long_goal.png', height: 80),
                        const SizedBox(height: 12),
                        _TripleButtonControl(
                          onLeft: () => setState(() => _longGoal2Red++),
                          onCenter: () => setState(() {
                            _longGoal2Red = 0;
                            _longGoal2Blue = 0;
                          }),
                          onRight: () => setState(() => _longGoal2Blue++),
                          enabled: widget.matchData.status != 'Completed',
                        ),
                      ],
                    ),
                    leftContent: _ValueDisplay(value: _longGoal2Red, color: Colors.redAccent),
                    rightContent: _ValueDisplay(value: _longGoal2Blue, color: Colors.blueAccent),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Middle Goal
                  _BreakdownRow(
                    image: const BreakdownImage(path: 'Images/middle_goal.png', height: 140),
                    leftContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BreakdownCounter(
                          value: _midGoal1Red,
                          onChanged: (v) => setState(() => _midGoal1Red = v),
                          color: Colors.redAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                        const SizedBox(height: 12),
                        _BreakdownCounter(
                          value: _midGoal2Red,
                          onChanged: (v) => setState(() => _midGoal2Red = v),
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
                          onChanged: (v) => setState(() => _midGoal1Blue = v),
                          color: Colors.blueAccent,
                          enabled: widget.matchData.status != 'Completed',
                        ),
                        const SizedBox(height: 12),
                        _BreakdownCounter(
                          value: _midGoal2Blue,
                          onChanged: (v) => setState(() => _midGoal2Blue = v),
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
                          Expanded(child: BreakdownImage(path: 'Images/parking_red.png', height: 80)),
                          SizedBox(width: 16),
                          Expanded(child: BreakdownImage(path: 'Images/parking_blue.png', height: 80)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: _BreakdownCounter(
                                value: _parkRed,
                                onChanged: (v) => setState(() => _parkRed = v),
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
                                onChanged: (v) => setState(() => _parkBlue = v),
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

  const BreakdownImage({
    super.key,
    required this.path,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
    );
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
          border: Border.all(color: value ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(), 
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: value ? Colors.white : kForegroundMuted,
                fontSize: 8,
              )
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
            color: isSelected ? color.withValues(alpha: 0.15) : kSurface.withValues(alpha: 0.3),
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

  const _ScoreInputCard({
    required this.teamName,
    required this.color,
    required this.controller,
    required this.enabled,
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            decoration: InputDecoration(
              hintText: '00',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.05)),
              filled: true,
              fillColor: kBackground.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide.none),
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
        Expanded(
          child: image,
        ),
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
        color: isActive ? color.withValues(alpha: 0.05) : kBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: isActive ? [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: -2)
        ] : null,
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
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
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

  const _CounterBtn({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon, 
          size: 18, 
          color: onTap == null 
            ? Colors.white.withValues(alpha: 0.03) 
            : (color?.withValues(alpha: 0.8) ?? Colors.white38)
        ),
      ),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  final int value;
  final Color color;

  const _ValueDisplay({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isActive = value > 0;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : kBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _TripleButtonControl extends StatelessWidget {
  final VoidCallback? onLeft;
  final VoidCallback? onCenter;
  final VoidCallback? onRight;
  final bool enabled;

  const _TripleButtonControl({
    this.onLeft,
    this.onCenter,
    this.onRight,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlBtn(
            icon: Icons.play_arrow_rounded, 
            isLeft: true, 
            onTap: onLeft, 
            enabled: enabled,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 4),
          _ControlBtn(
            icon: Icons.close_rounded, 
            onTap: onCenter, 
            enabled: enabled,
            color: Colors.white24,
          ),
          const SizedBox(width: 4),
          _ControlBtn(
            icon: Icons.play_arrow_rounded, 
            onTap: onRight, 
            enabled: enabled,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final bool isLeft;
  final VoidCallback? onTap;
  final bool enabled;
  final Color color;

  const _ControlBtn({
    required this.icon,
    this.isLeft = false,
    this.onTap,
    this.enabled = true,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Transform.rotate(
            angle: isLeft ? 3.14159 : 0,
            child: Icon(
              icon, 
              size: 16, 
              color: enabled ? color : color.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}
