import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(isUser: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMessageColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          message.isUser
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (message.isPartial) ...[
                    const SizedBox(height: 6),
                    _buildTypingIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) _buildAvatar(isUser: true),
        ],
      ),
    );
  }

  Color _getMessageColor(BuildContext context) {
    if (message.isUser) {
      return Theme.of(
        context,
      ).colorScheme.primary.withOpacity(message.isPartial ? 0.6 : 0.8);
    } else {
      return Theme.of(
        context,
      ).colorScheme.secondary.withOpacity(message.isPartial ? 0.1 : 0.2);
    }
  }

  Widget _buildAvatar({required bool isUser}) {
    return CircleAvatar(
      backgroundColor: isUser ? Colors.blue.shade700 : Colors.grey.shade700,
      child: Icon(isUser ? Icons.person : Icons.smart_toy, color: Colors.white),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildDot(1), _buildDot(2), _buildDot(3)],
    );
  }

  Widget _buildDot(int position) {
    return SizedBox(
      width: 5,
      height: 5,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 * position),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.white70 : Colors.grey,
          shape: BoxShape.circle,
        ),
        curve: Curves.easeInOut,
      ),
    );
  }
}
