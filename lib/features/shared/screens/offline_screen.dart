import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/shared/widgets/offline_fallback.dart';
import 'package:eventbridge/core/network/network_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: OfflineFallback(
        onRetry: () {
          ref.read(networkStatusProvider.notifier).refresh();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checking connection...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
