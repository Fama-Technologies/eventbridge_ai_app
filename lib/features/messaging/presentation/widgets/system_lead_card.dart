import 'package:eventbridge/features/shared/widgets/lead_milestone_card.dart';
import 'package:flutter/material.dart';

class SystemLeadCard extends StatelessWidget {
  final Map<String, dynamic> systemData;
  const SystemLeadCard({super.key, required this.systemData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LeadMilestoneCard(data: systemData, isDark: isDark);
  }
}
