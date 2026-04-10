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
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _progressAnim;

  int _messageIndex = 0;
  Timer? _messageTimer;

  final List<String> _messages = [
    'Analyzing 500+ local vendors...',
    'Matching with your style and budget...',
    'Ranking top AI picks...',
    'Almost there!',
  ];

  final List<IconData> _serviceIcons = [
    Icons.restaurant_rounded,
    Icons.celebration_rounded,
    Icons.camera_alt_rounded,
    Icons.search_rounded,
    Icons.music_note_rounded,
    Icons.palette_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_rotateController);

    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _progressController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MatchingState>(matchingControllerProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
          context.pop();
        } else {
          context.pushReplacement('/ai-results');
        }
      }
    });

    final matchCount = ref.watch(matchingControllerProvider).matches.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOrbitAnimation(),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _messages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutrals08,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Matching with your style and budget.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.neutrals07,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildProgressBar(),
                ],
              ),
            ),
            _buildBottomCard(matchCount),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _rotateAnim]),
      builder: (context, _) {
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbit ring — neutral
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neutrals03,
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Inner orbit ring — light primary tint
              Transform.scale(
                scale: _pulseAnim.value * 0.85,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary01.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Orbiting icons — neutral bg
              ...List.generate(_serviceIcons.length, (i) {
                final angle = _rotateAnim.value + (i * (2 * pi / _serviceIcons.length));
                final radius = 95.0;
                final x = cos(angle) * radius;
                final y = sin(angle) * radius;
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(_serviceIcons[i], size: 16, color: AppColors.neutrals08),
                  ),
                );
              }),
              // Center badge — primary
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary01,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary01.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 38),
              ),
              // Checkmark badge — success green
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) => LinearProgressIndicator(
                value: _progressAnim.value,
                backgroundColor: AppColors.neutrals02,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary01),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI ENGINE ACTIVE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary01,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'SEARCHING...',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutrals06,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(int matchCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.neutrals01,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary01.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary01, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY VENDOR MATCHES',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutrals07,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matchCount > 0 ? '$matchCount Matches Found' : 'Searching...',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutrals08,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.neutrals06),
          ],
        ),
      ),
    );
  }
}
