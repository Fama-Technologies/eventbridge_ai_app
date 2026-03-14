import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';

class VendorHelpSupportScreen extends StatefulWidget {
  const VendorHelpSupportScreen({super.key});

  @override
  State<VendorHelpSupportScreen> createState() => _VendorHelpSupportScreenState();
}

class _VendorHelpSupportScreenState extends State<VendorHelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is EventBridge?',
      'answer': 'Event Bridge is an E-services connection platform connecting event service providers to event organizers and planners providing them with tools to connect and manage their events.'
    },
    {
      'question': 'Does EventBridge manage payments to the vendors?',
      'answer': 'No, Event Bridge does not currently process payment to the vendors. Payments are negotiable between the provider and customer but we provide digital invoicing and Receipt generation tools.'
    },
    {
      'question': 'What features does EventBridge currently offer?',
      'answer': 'We offer Digital invoicing and Receipting generation. Manage Bookings and Calendar management. Event Budget management and checklists, Leads and inquires and direct customer chats.'
    },
    {
      'question': 'Is EventBridge free?',
      'answer': 'Yes, Event Bridge has a free plan that all customers enjoy but we also provide premium features in our pro and pro max versions.'
    },
    {
      'question': 'What businesses can list on EventBridge?',
      'answer': 'All service providers can create their business profile on event bridge and list their services and packages.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Everything you need to know about planning your next event with EventBridge.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ..._faqs.map((faq) => _FAQItem(
                  question: faq['question']!,
                  answer: faq['answer']!,
                )),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 48, color: AppColors.primary01),
                  const SizedBox(height: 16),
                  Text(
                    'Still have questions?',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Can't find the answer you're looking for? Please chat to our friendly team.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement contact team
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary01,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get in touch',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.add_rounded,
              color: _isExpanded ? AppColors.primary01 : const Color(0xFF94A3B8),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Text(
              widget.answer,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
