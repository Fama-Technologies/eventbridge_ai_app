import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';

class AiAnalyzingScreen extends ConsumerStatefulWidget {
  const AiAnalyzingScreen({super.key});

  @override
  ConsumerState<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends ConsumerState<AiAnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late Animation<double> _sweepAnim;
  late Animation<double> _pulseAnim;

  final List<_CheckItem> _steps = [
    _CheckItem('Scanning service categories...', Icons.design_services_rounded),
    _CheckItem('Applying location & radius filter...', Icons.location_on_rounded),
    _CheckItem('Analysing vendor portfolios...', Icons.photo_library_rounded),
    _CheckItem('Checking ratings & reviews...', Icons.star_rounded),
    _CheckItem('Calculating budget fit...', Icons.account_balance_wallet_rounded),
    _CheckItem('Ranking top AI picks...', Icons.auto_awesome_rounded),
  ];

  int _completedSteps = 0;
  Timer? _stepTimer;

  static const Duration _minDisplayDuration = Duration(milliseconds: 6500);
  late final DateTime _startedAt;
  bool _navigated = false;
  bool _loadingFinished = false;
  MatchingState? _pendingNextState;

  @override
  void initState() {
    super.initState();

    _startedAt = DateTime.now();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _sweepAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_sweepController);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Tick checklist items — paced to finish around _minDisplayDuration
    const stepInterval = Duration(milliseconds: 950);
    _stepTimer = Timer.periodic(stepInterval, (_) {
      if (mounted && _completedSteps < _steps.length) {
        setState(() => _completedSteps++);
      }
    });

    // Handle case where loading already completed before this screen mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(matchingControllerProvider);
      if (!current.isLoading) {
        _loadingFinished = true;
        _pendingNextState = current;
        _maybeNavigate();
      }
    });
  }

  void _maybeNavigate() {
    if (_navigated || !_loadingFinished || !mounted) return;
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minDisplayDuration - elapsed;

    void go() {
      if (_navigated || !mounted) return;
      final next = _pendingNextState;
      if (next == null) return;
      _navigated = true;
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
        context.pop();
      } else {
        // Ensure all checklist items visually complete
        setState(() => _completedSteps = _steps.length);
        context.pushReplacement('/ai-results');
      }
    }

    if (remaining <= Duration.zero) {
      go();
    } else {
      Future.delayed(remaining, go);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MatchingState>(matchingControllerProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        _loadingFinished = true;
        _pendingNextState = next;
        _maybeNavigate();
      }
    });

    final matchCount = ref.watch(matchingControllerProvider).matches.length;
    final request = ref.watch(matchingControllerProvider).request;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(request?.eventType),
                      const SizedBox(height: 24),
                      _buildRadarWidget(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _buildChecklist(),
                      ),
                      const Spacer(),
                      _buildBottomCard(matchCount, request?.location),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String? eventType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.primary01, size: 14),
                const SizedBox(width: 6),
                Text(
                  'AI ENGINE ACTIVE',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary01,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Finding the best\nvendors for you',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A24),
              height: 1.2,
            ),
          ),
          if (eventType != null) ...[
            const SizedBox(height: 6),
            Text(
              'Planning: $eventType',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarWidget() {
    return AnimatedBuilder(
      animation: Listenable.merge([_sweepAnim, _pulseAnim]),
      builder: (context, _) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              _buildRing(220, AppColors.primary01.withValues(alpha: 0.08)),
              // Middle ring
              _buildRing(155, AppColors.primary01.withValues(alpha: 0.12)),
              // Inner ring
              _buildRing(90, AppColors.primary01.withValues(alpha: 0.18)),

              // Radar sweep
              Transform.rotate(
                angle: _sweepAnim.value,
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _RadarSweepPainter(AppColors.primary01),
                ),
              ),

              // Blips
              ..._buildBlips(),

              // Centre badge
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary01,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary01.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  List<Widget> _buildBlips() {
    final positions = [
      const Offset(0.72, 0.18),
      const Offset(-0.55, 0.40),
      const Offset(0.35, -0.62),
      const Offset(-0.70, -0.25),
      const Offset(0.15, 0.80),
    ];
    return positions.map((p) {
      return Positioned(
        left: 110 + p.dx * 90,
        top: 110 + p.dy * 90,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary01,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary01.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildChecklist() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final isDone = i < _completedSteps;
          final isActive = i == _completedSteps;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.primary01
                        : isActive
                            ? AppColors.primary01.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                    border: isActive
                        ? Border.all(color: AppColors.primary01, width: 2)
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : isActive
                          ? _buildSpinner()
                          : Icon(_steps[i].icon, color: const Color(0xFFCBD5E1), size: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _steps[i].label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isDone
                          ? FontWeight.w600
                          : isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                      color: isDone
                          ? const Color(0xFF1A1A24)
                          : isActive
                              ? AppColors.primary01
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSpinner() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary01,
      ),
    );
  }

  Widget _buildBottomCard(int matchCount, String? location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary01,
              AppColors.primary01.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary01.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_searching_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location != null ? 'Searching in $location' : 'AI Search Running',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matchCount > 0
                        ? '$matchCount vendor${matchCount == 1 ? '' : 's'} found so far'
                        : 'Scanning nearby vendors...',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Radar sweep custom painter
class _RadarSweepPainter extends CustomPainter {
  final Color color;
  _RadarSweepPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.55, 0.75, 0.98, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Leading edge line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, center + Offset(radius, 0), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CheckItem {
  final String label;
  final IconData icon;
  const _CheckItem(this.label, this.icon);
}
