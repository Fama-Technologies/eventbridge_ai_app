import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge_ai/features/vendors_screen/models/lead_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBox(),
            Expanded(child: _buildChatList(context)),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppColors.primary01,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 28,
            ),
          ).animate().scale(
            delay: 400.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A24),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '3 New Conversations',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF1A1A24),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search people or keywords...',
            hintStyle: GoogleFonts.roboto(
              color: const Color(0xFF94A3B8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Lead lead, int index) {
    final bool isUnread = lead.id == '1' || lead.id == '4';
    final String time = index == 0
        ? '2m ago'
        : (index == 1 ? '1h ago' : 'Yesterday');

    return InkWell(
      onTap: () => context.push('/vendor-chat/${lead.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(lead),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lead.clientName,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: isUnread
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isUnread
                              ? AppColors.primary01
                              : const Color(0xFF94A3B8),
                          fontWeight: isUnread
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead.clientMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: isUnread
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B),
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                              margin: const EdgeInsets.only(left: 12),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary01,
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.2, 1.2),
                              duration: 1000.ms,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).moveX(begin: 10, end: 0);
  }

  Widget _buildAvatar(Lead lead) {
    final bool isOnline = lead.id == '1' || lead.id == '3';
    return Stack(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              lead.clientImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatList(BuildContext context) {
    final leads = MockLeadRepository.leads;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: leads.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 98, right: 24),
        child: Divider(height: 1, color: const Color(0xFFF1F5F9)),
      ),
      itemBuilder: (context, index) {
        return _buildChatTile(context, leads[index], index);
      },
    );
  }
}
