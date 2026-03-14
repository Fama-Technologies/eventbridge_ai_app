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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF1A1A24), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A24),
          ),
        ),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Everything you need to know about planning your next event with EventBridge.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            ..._faqs.map((faq) => _FAQItem(
                  question: faq['question']!,
                  answer: faq['answer']!,
                  isDark: isDark,
                )),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkNeutral02 : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary01.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.primary01),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Still have questions?',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Can't find the answer you're looking for? Please chat to our friendly team.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement contact team
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary01,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get in touch',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
  final bool isDark;

  const _FAQItem({required this.question, required this.answer, required this.isDark});

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
        color: widget.isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _isExpanded ? AppColors.primary01 : (widget.isDark ? Colors.white30 : const Color(0xFF94A3B8)),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Text(
              widget.answer,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: widget.isDark ? Colors.white60 : const Color(0xFF4B5563),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
