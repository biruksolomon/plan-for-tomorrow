import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/urge_activity.dart';
import '../data/repositories/urge_activities_catalog.dart';
import '../widgets/common.dart';

class UrgeSurferScreen extends StatefulWidget {
  final int streakDay;

  const UrgeSurferScreen({
    super.key,
    this.streakDay = 1,
  });

  @override
  State<UrgeSurferScreen> createState() => _UrgeSurferScreenState();
}

class _UrgeSurferScreenState extends State<UrgeSurferScreen>
    with SingleTickerProviderStateMixin {
  late UrgeActivity _currentActivity;
  int _selectedTabIndex = 0; // 0: Today's Technique, 1: 90+ Catalog
  String _selectedCategoryFilter = 'All';

  // 15-Minute Surfer Timer State
  static const int _initialSeconds = 15 * 60; // 15 minutes
  int _secondsLeft = _initialSeconds;
  Timer? _timer;
  bool _isRunning = false;

  // Breathing Controller
  late AnimationController _breathingController;
  String _breathingPhase = 'Inhale (4s)';

  @override
  void initState() {
    super.initState();
    _currentActivity = UrgeActivitiesCatalog.getForDay(widget.streakDay);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19), // 4s in + 7s hold + 8s out
    )..addListener(_updateBreathingPhase);
  }

  void _selectActivity(UrgeActivity activity) {
    setState(() {
      _currentActivity = activity;
      _selectedTabIndex = 0; // switch to technique view
      _resetTimer();
    });
  }

  void _updateBreathingPhase() {
    final value = _breathingController.value;
    if (value < 0.21) {
      if (_breathingPhase != 'Inhale (4s)') {
        setState(() => _breathingPhase = 'Inhale (4s)');
      }
    } else if (value < 0.58) {
      if (_breathingPhase != 'Hold (7s)') {
        setState(() => _breathingPhase = 'Hold (7s)');
      }
    } else {
      if (_breathingPhase != 'Exhale (8s)') {
        setState(() => _breathingPhase = 'Exhale (8s)');
      }
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _breathingController.stop();
      setState(() => _isRunning = false);
    } else {
      _isRunning = true;
      _breathingController.repeat();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          t.cancel();
          _breathingController.stop();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _breathingController.reset();
    setState(() {
      _secondsLeft = _initialSeconds;
      _isRunning = false;
      _breathingPhase = 'Inhale (4s)';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('URGE SURFER', style: AppTheme.display(20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? AppColors.ink
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'DAY ${_currentActivity.dayNumber} TECHNIQUE',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(12,
                              color: _selectedTabIndex == 0
                                  ? AppColors.paper
                                  : AppColors.ink,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? AppColors.ink
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '90+ CATALOG',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(12,
                              color: _selectedTabIndex == 1
                                  ? AppColors.paper
                                  : AppColors.ink,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _selectedTabIndex == 0
                ? _buildTechniqueView()
                : _buildCatalogView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
      children: [
        // SOS Emergency Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.accentTint, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${_currentActivity.dayNumber}: ${_currentActivity.title}',
                      style: AppTheme.body(14,
                          color: AppColors.accentTint, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentActivity.description,
                      style: AppTheme.body(12, color: AppColors.accentTint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Runner Area (Breathing Circle & Timer)
        Center(
          child: AnimatedBuilder(
            animation: _breathingController,
            builder: (ctx, child) {
              final val = _breathingController.value;
              double scale = 1.0;
              if (val < 0.21) {
                scale = 1.0 + (val / 0.21) * 0.35;
              } else if (val < 0.58) {
                scale = 1.35;
              } else {
                scale = 1.35 - ((val - 0.58) / 0.42) * 0.35;
              }
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper2,
                    border: Border.all(color: AppColors.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_secondsLeft),
                        style: AppTheme.display(32, color: AppColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentActivity.interactiveType == 'breathing'
                            ? _breathingPhase
                            : 'Focus & Ride',
                        style: AppTheme.body(12,
                            color: AppColors.ink, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isRunning ? 'Pause' : 'Start Technique'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _resetTimer,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Psychological Benefit Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('PSYCHOLOGICAL BENCHMARK',
                      style: AppTheme.body(11,
                          color: AppColors.accent, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _currentActivity.psychologicalBenefit,
                style: AppTheme.body(13, color: AppColors.ink),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Step-by-Step Instructions', style: AppTheme.display(18)),
        const SizedBox(height: 10),

        ..._currentActivity.steps.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final stepText = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: AppTheme.body(11,
                          color: AppColors.paper, weight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stepText,
                    style: AppTheme.body(13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        const QuoteLine(
          'An urge is like a wave in the ocean. You cannot stop it, but you can learn to surf it.',
        ),
      ],
    );
  }

  Widget _buildCatalogView() {
    final categories = ['All', ...UrgeActivitiesCatalog.categories];
    final activities = _selectedCategoryFilter == 'All'
        ? UrgeActivitiesCatalog.getAll()
        : UrgeActivitiesCatalog.getByCategory(_selectedCategoryFilter);

    return Column(
      children: [
        // Category Filter Horizontal Scroll
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat,
                      style: AppTheme.body(12,
                          color: isSelected ? AppColors.paper : AppColors.ink,
                          weight:
                              isSelected ? FontWeight.w700 : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.ink,
                  backgroundColor: AppColors.paper2,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryFilter = cat);
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            itemCount: activities.length,
            itemBuilder: (ctx, idx) {
              final act = activities[idx];
              final isCurrent = act.dayNumber == _currentActivity.dayNumber;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.accent.withValues(alpha: 0.1)
                      : AppColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.accent
                        : AppColors.ink.withValues(alpha: 0.12),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  title: Text(
                    act.title,
                    style: AppTheme.body(14,
                        color: AppColors.ink, weight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${act.category} • ${act.durationSeconds ~/ 60} min',
                      style: AppTheme.body(12, color: AppColors.muted),
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _selectActivity(act),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCurrent ? AppColors.accent : AppColors.ink,
                      foregroundColor: AppColors.paper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      isCurrent ? 'Active' : 'Surf This',
                      style: AppTheme.body(11, weight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
