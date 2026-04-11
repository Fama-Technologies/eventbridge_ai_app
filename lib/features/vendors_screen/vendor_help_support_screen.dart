import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class VendorHelpSupportScreen extends StatefulWidget {
  const VendorHelpSupportScreen({super.key});

  @override
  State<VendorHelpSupportScreen> createState() => _VendorHelpSupportScreenState();
}

class _VendorHelpSupportScreenState extends State<VendorHelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is EventBridge AI?',
      'answer': 'EventBridge AI helps event planners discover vendors, compare options, send inquiries, and manage conversations in one place.'
    },
    {
      'question': 'Does EventBridge AI handle vendor payments?',
      'answer': 'No. Payments are still agreed on directly between the vendor and the customer. EventBridge AI currently focuses on matching, inquiries, chat, and business management tools.'
    },
    {
      'question': 'What can vendors do on EventBridge AI?',
      'answer': 'Vendors can list services, receive leads, chat with customers, manage bookings, track their calendar, and use tools like invoicing and receipts.'
    },
    {
      'question': 'Is EventBridge AI free?',
      'answer': 'Yes. EventBridge AI includes a free plan, with additional features available on paid plans.'
    },
    {
      'question': 'Who can join EventBridge AI?',
      'answer': 'Event service providers can create a business profile, showcase services and packages, and connect with customers looking for the right fit.'
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
              'Learn how EventBridge AI helps vendors and event planners discover each other, send inquiries, and manage event work with less friction.',
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
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                      color: AppColors.primary01.withValues(alpha: 0.1),
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
                    'Need more help with EventBridge AI? Contact our team for support with setup, matching, leads, or account questions.',
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
                          borderRadius: BorderRadius.zero,
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
        border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
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
