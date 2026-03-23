import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatBubbleWidget extends StatelessWidget {
  final bool isUser;
  final Widget content;
  final String? time;
  final String? attachmentName;

  const ChatBubbleWidget({
    super.key,
    required this.isUser,
    required this.content,
    this.time,
    this.attachmentName,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return _buildUserBubble();
    } else {
      return _buildAIBubble();
    }
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
                topRight: Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
              child: content,
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 4.0),
              child: Text(
                time!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFF43474F),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIBubble() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome, // fallback for the AI star icon
                  size: 12,
                  color: Color(0xFF66DD8B),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: Color(0xFF43474F),
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 2.0,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  topLeft: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 2,
                    // offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF1A1C1E),
                      height: 1.5,
                    ),
                    child: content,
                  ),
                  if (attachmentName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 10,
                              color: Color(0xFF66DD8B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Basado en: $attachmentName',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                color: Color(0xFF556474),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
