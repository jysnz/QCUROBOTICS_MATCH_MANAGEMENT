import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Widgets/design_system.dart';
import '../../Services/tournament_service.dart';

class CreateTournamentModal extends StatefulWidget {
  final VoidCallback onTournamentCreated;

  const CreateTournamentModal({super.key, required this.onTournamentCreated});

  @override
  State<CreateTournamentModal> createState() => _CreateTournamentModalState();
}

class _CreateTournamentModalState extends State<CreateTournamentModal> {
  final _nameController = TextEditingController();
  final _teamNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TournamentService _service = TournamentService();
  
  final List<String> _teamNames = [];
  bool _isCreating = false;

  void _addTeam() {
    final name = _teamNameController.text.trim();
    if (name.isNotEmpty) {
      if (_teamNames.contains(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team already added'))
        );
        return;
      }
      setState(() {
        _teamNames.add(name);
        _teamNameController.clear();
      });
    }
  }

  void _removeTeam(int index) {
    setState(() {
      _teamNames.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccent,
              onPrimary: Colors.white,
              surface: kSurface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: kSurface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showProgressDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(color: kAccent),
            SizedBox(height: 24),
            Text(
              'GENERATING MATCHES',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we compute the technical pairings and initialize the tournament grid...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createTournament() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a tournament name')));
      return;
    }
    if (_teamNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 2 teams')));
      return;
    }

    setState(() => _isCreating = true);
    _showProgressDialog();

    try {
      // 1. Find or Create Teams to get IDs
      final teamIds = await _service.findOrCreateTeams(_teamNames);
      
      // 2. Create Tournament and Generate Matches
      await _service.createTournament(
        _nameController.text.trim(),
        _selectedDate,
        teamIds,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Pop progress dialog
        Navigator.of(context).pop(); // Pop modal
        widget.onTournamentCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament system initialized successfully'))
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Critical System Error: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NEW TOURNAMENT',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tournament Name
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'TOURNAMENT NAME',
                      labelStyle: const TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      hintText: 'Enter name (e.g. QCU Robotics 2026)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                      filled: true,
                      fillColor: kSurface,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent)),
                      prefixIcon: const Icon(Icons.emoji_events_outlined, color: kAccent, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date Picker
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: kAccent, size: 20),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SCHEDULE DATE', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(_selectedDate).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Teams Section Header
                  Row(
                    children: [
                      const Icon(Icons.groups_outlined, color: kAccent, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'PARTICIPATING TEAMS',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                      const Spacer(),
                      Text(
                        '${_teamNames.length} ADDED',
                        style: const TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Add Team Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _teamNameController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _addTeam(),
                          decoration: InputDecoration(
                            hintText: 'Enter team name...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 14),
                            filled: true,
                            fillColor: kSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kAccent)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _addTeam,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Teams List
                  if (_teamNames.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: kSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.1), size: 32),
                          const SizedBox(height: 12),
                          const Text(
                            'NO TEAMS ADDED YET',
                            style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teamNames.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: kAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _teamNames[index].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeTeam(index),
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: TechnicalButton(
              label: 'INITIALIZE TOURNAMENT GRID',
              isLoading: _isCreating,
              onTap: _createTournament,
            ),
          ),
        ],
      ),
    );
  }
}
