import 'package:flutter/material.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet.dart';

class LeadDetailsScreen extends StatelessWidget {
  final String leadId;

  const LeadDetailsScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: LeadDetailsBottomSheet(leadId: leadId)),
    );
  }
}
