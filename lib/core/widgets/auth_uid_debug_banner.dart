import 'dart:async';

import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';

/// Debug-only overlay that exposes the Firebase Auth uid / backend user_id
/// invariant. If they diverge, messaging (Firestore rule
/// `senderId == request.auth.uid`) and push notifications (Cloud Function
/// `onMessageCreate` looking up `notificationTokens/{uid}`) silently stop
/// working. This banner makes the failure visible.
///
/// Wrap the child of `MaterialApp.router`'s `builder`:
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => AuthUidDebugBanner(child: child),
///   ...
/// );
/// ```
///
/// In release builds this widget is a no-op that just returns its child.
class AuthUidDebugBanner extends StatefulWidget {
  final Widget? child;

  const AuthUidDebugBanner({super.key, required this.child});

  @override
  State<AuthUidDebugBanner> createState() => _AuthUidDebugBannerState();
}

class _AuthUidDebugBannerState extends State<AuthUidDebugBanner> {
  StreamSubscription<firebase_auth.User?>? _authSub;
  Timer? _pollTimer;
  _UidStatus _status = const _UidStatus.loading();
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) return;
    _authSub = firebase_auth.FirebaseAuth.instance.authStateChanges().listen((
      _,
    ) {
      _recompute();
    });
    // Storage changes aren't streamed, so poll every few seconds as a
    // cheap safety net for login/logout transitions.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _recompute(),
    );
    _recompute();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _recompute() {
    if (!mounted) return;
    final firebaseUid =
        firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    final backendId = StorageService().getString('user_id') ?? '';

    final _UidStatus next;
    if (backendId.isEmpty) {
      // Logged out — nothing to compare.
      next = const _UidStatus.idle();
    } else if (firebaseUid.isEmpty) {
      next = _UidStatus.missing(backendId: backendId);
    } else if (firebaseUid != backendId) {
      next = _UidStatus.mismatch(
        firebaseUid: firebaseUid,
        backendId: backendId,
      );
    } else {
      next = _UidStatus.aligned(uid: backendId);
    }

    if (next != _status) {
      setState(() => _status = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? const SizedBox.shrink();
    if (!kDebugMode) return child;
    if (_dismissed) return child;

    final banner = _status.banner(
      onDismiss: () {
        setState(() => _dismissed = true);
      },
      onFix: () async {
        try {
          // Import is not needed as it's likely in the same project, but we'll use a direct call
          await AuthRepository().forceRestoreFirebaseSession();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fix failed: $e')),
            );
          }
        }
      },
    );
    if (banner == null) return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(bottom: false, child: banner),
          ),
        ],
      ),
    );
  }
}

class _UidStatus {
  final _StatusKind kind;
  final String? firebaseUid;
  final String? backendId;

  const _UidStatus._(this.kind, {this.firebaseUid, this.backendId});

  const _UidStatus.loading() : this._(_StatusKind.loading);
  const _UidStatus.idle() : this._(_StatusKind.idle);
  const _UidStatus.aligned({required String uid})
    : this._(_StatusKind.aligned, firebaseUid: uid, backendId: uid);
  const _UidStatus.missing({required String backendId})
    : this._(_StatusKind.missing, backendId: backendId);
  const _UidStatus.mismatch({
    required String firebaseUid,
    required String backendId,
  }) : this._(
         _StatusKind.mismatch,
         firebaseUid: firebaseUid,
         backendId: backendId,
       );

  @override
  bool operator ==(Object other) =>
      other is _UidStatus &&
      other.kind == kind &&
      other.firebaseUid == firebaseUid &&
      other.backendId == backendId;

  @override
  int get hashCode => Object.hash(kind, firebaseUid, backendId);

  Widget? banner({
    required VoidCallback onDismiss,
    required VoidCallback onFix,
  }) {
    switch (kind) {
      case _StatusKind.loading:
      case _StatusKind.idle:
      case _StatusKind.aligned:
        return null;
      case _StatusKind.missing:
        return _BannerBar(
          color: const Color(0xFFB45309), // amber-700
          title: 'Firebase Auth session missing',
          subtitle:
              'Backend user_id=$backendId but FirebaseAuth.currentUser is null. '
              'Messages and push will fail until custom-token restore succeeds.',
          onDismiss: onDismiss,
          onFix: onFix,
        );
      case _StatusKind.mismatch:
        return _BannerBar(
          color: const Color(0xFFB91C1C), // red-700
          title: 'Firebase uid ≠ backend user_id',
          subtitle:
              'firebase=$firebaseUid backend=$backendId — Firestore sendMessage '
              'will be rejected by rules; push notifications disabled.',
          onDismiss: onDismiss,
          onFix: onFix,
        );
    }
  }
}

enum _StatusKind { loading, idle, aligned, missing, mismatch }

class _BannerBar extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;
  final VoidCallback onFix;

  const _BannerBar({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onDismiss,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: onDismiss,
                  ),
                  TextButton(
                    onPressed: onFix,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(40, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Text(
                      'TRY FIX',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
