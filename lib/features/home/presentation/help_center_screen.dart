import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    _FaqItem('How do I find a vendor?', 'Open Explore and describe what you need. EventBridge AI uses your event details to surface relevant vendors you can review and contact.'),
    _FaqItem('How does EventBridge AI work?', 'EventBridge AI looks at your event type, budget, location, guest count, and preferences to help you discover vendors that fit your request.'),
    _FaqItem('Can I message a vendor before booking?', 'Yes. Send an inquiry first. When a vendor accepts it, EventBridge AI opens a chat so you can continue the conversation directly.'),
    _FaqItem('How do I edit my profile?', 'Go to Profile, open your personal information, and update your saved details there.'),
    _FaqItem('What happens after I send an inquiry?', 'The vendor receives your request as a lead. If they accept, you are notified and a chat is created automatically.'),
    _FaqItem('How do I delete my account?', 'Go to Profile, open Security & Preferences, and choose Delete Account. This action is permanent.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Help Center', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40, // Account for padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.primary01.withValues(alpha: 0.08), AppColors.softPeach]),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppColors.primary01.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.support_agent_rounded,
                              color: AppColors.primary01, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About EventBridge AI',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1A24))),
                              Text('Learn how matching, inquiries, and chat work inside the platform.',
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('FREQUENTLY ASKED QUESTIONS',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary01,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkNeutral02 : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ExpansionPanelList.radio(
                          elevation: 0,
                          expandedHeaderPadding: EdgeInsets.zero,
                          children: _faqs.asMap().entries.map((entry) {
                            final faq = entry.value;
                            return ExpansionPanelRadio(
                              value: entry.key,
                              headerBuilder: (context, isExpanded) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                child: Text(faq.question,
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B))),
                              ),
                              body: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Text(faq.answer,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                        height: 1.5)),
                              ),
                            );
                          }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}
