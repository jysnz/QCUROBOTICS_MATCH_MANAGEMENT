import 'package:flutter/material.dart';
import '../../Widgets/design_system.dart';
import '../../Services/tournament_service.dart';
import '../../Models/team.dart';

class CreateTournamentModal extends StatefulWidget {
  final VoidCallback onTournamentCreated;

  const CreateTournamentModal({super.key, required this.onTournamentCreated});

  @override
  State<CreateTournamentModal> createState() => _CreateTournamentModalState();
}

class _CreateTournamentModalState extends State<CreateTournamentModal> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TournamentService _service = TournamentService();
  
  List<Team> _allTeams = [];
  final List<Team> _selectedTeams = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final teams = await _service.getAllTeams();
      setState(() => _allTeams = teams);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teams: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleTeam(Team team) {
    setState(() {
      if (_selectedTeams.contains(team)) {
        _selectedTeams.remove(team);
      } else {
        _selectedTeams.add(team);
      }
    });
  }

  Future<void> _createTournament() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a tournament name')));
      return;
    }
    if (_selectedTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 teams')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _service.createTournament(
        _nameController.text.trim(),
        _selectedDate,
        _selectedTeams.map((t) => t.id).toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onTournamentCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament created and matches generated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating tournament: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
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
          const Text(
            'CREATE TOURNAMENT',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tournament Name',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.emoji_events_outlined, color: kAccent),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(kRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: kAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Date: ${_selectedDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Select Teams', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allTeams.length,
                  itemBuilder: (context, index) {
                    final team = _allTeams[index];
                    final isSelected = _selectedTeams.contains(team);
                    return CheckboxListTile(
                      title: Text(team.teamName, style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      onChanged: (bool? value) => _toggleTeam(team),
                      activeColor: kAccent,
                      checkColor: kBackground,
                      tileColor: isSelected ? kAccent.withValues(alpha: 0.1) : Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
                    );
                  },
                ),
          ),
          const SizedBox(height: 16),
          TechnicalButton(
            label: 'Generate Matches',
            isLoading: _isCreating,
            onTap: _createTournament,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
