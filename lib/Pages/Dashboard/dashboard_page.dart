import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Widgets/design_system.dart';
import '../../Widgets/loading_ui.dart';
import '../../Services/tournament_service.dart';
import '../../Services/user_service.dart';
import '../../Models/tournament.dart';
import '../Tournament/create_tournament_modal.dart';
import '../Tournament/tournament_details_page.dart';
import '../Auth/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TournamentService _tournamentService = TournamentService();
  final UserService _userService = UserService();
  
  List<Tournament> _tournaments = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _tournamentService.getRecentTournaments(),
        _userService.getCurrentUserProfile(),
      ]);
      
      if (mounted) {
        setState(() {
          _tournaments = results[0] as List<Tournament>;
          _userProfile = results[1] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTournaments() async {
    try {
      final tournaments = await _tournamentService.getRecentTournaments();
      if (mounted) {
        setState(() {
          _tournaments = tournaments;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
    }
  }

  void _showCreateTournamentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTournamentModal(
        onTournamentCreated: _fetchTournaments,
      ),
    );
  }

  void _navigateToTournament(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentDetailsPage(tournamentId: id),
      ),
    ).then((_) => _fetchTournaments());
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: DashboardSkeleton(),
      );
    }

    final greeting = _userService.getGreeting();
    final fullName = _userProfile?['full_name'] ?? 'User';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: GestureDetector(
              onTap: _navigateToProfile,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccent.withValues(alpha: 0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: kSurface,
                  backgroundImage: _userProfile?['avatar_url'] != null 
                    ? NetworkImage(_userProfile!['avatar_url']) 
                    : null,
                  child: _userProfile?['avatar_url'] == null 
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      )
                    : null,
                ),
              ),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: _navigateToProfile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              Text(
                fullName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: kAccent, size: 20),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          const TechnicalGridBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: kAccent,
              backgroundColor: kSurface,
              onRefresh: _loadInitialData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(kPadding),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TechnicalButton(
                            label: 'Start Tournament',
                            icon: Icons.add_circle_outline,
                            onTap: _showCreateTournamentModal,
                          ),
                          const SizedBox(height: 32),
                          const TechnicalSectionHeader(label: 'Recent Tournaments', color: kAccent, topPadding: 0),
                        ],
                      ),
                    ),
                  ),
                  if (_tournaments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: kAccent.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kAccent.withValues(alpha: 0.1)),
                                ),
                                child: Icon(
                                  Icons.emoji_events_outlined,
                                  size: 48,
                                  color: kAccent.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'NO TOURNAMENTS FOUND',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your competitive arena is empty. Start your first tournament to begin tracking match statistics and team rankings.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TechnicalButton(
                                label: 'Quick Start',
                                icon: Icons.bolt_rounded,
                                onTap: _showCreateTournamentModal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(kPadding, 0, kPadding, kPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tournament = _tournaments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TournamentCard(
                                tournament: tournament,
                                onTap: () => _navigateToTournament(tournament.id),
                              ),
                            );
                          },
                          childCount: _tournaments.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = tournament.status == 'Completed';
    final statusColor = isCompleted ? kMuted : kAccent;

    return TechnicalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  tournament.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                tournament.tournamentDate.toString().split(' ')[0],
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
              const Spacer(),
              _TeamCountBadge(tournamentId: tournament.id),
            ],
          ),
          const SizedBox(height: 16),
          TechnicalButton(
            label: 'View Details',
            color: Colors.white,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _TeamCountBadge extends StatefulWidget {
  final String tournamentId;

  const _TeamCountBadge({required this.tournamentId});

  @override
  State<_TeamCountBadge> createState() => _TeamCountBadgeState();
}

class _TeamCountBadgeState extends State<_TeamCountBadge> {
  final TournamentService _service = TournamentService();
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final count = await _service.getTournamentTeamCount(widget.tournamentId);
      if (mounted) setState(() => _count = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.group, size: 14, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          '$_count Teams',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}
