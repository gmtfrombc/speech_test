import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/speech_service.dart';

class SpeechControlButton extends StatelessWidget {
  const SpeechControlButton({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final state = chatProvider.currentState;

    return GestureDetector(
      onTap: () => _handleTap(context, state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getButtonColor(state),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _getButtonIcon(state),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, SpeechServiceState state) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    switch (state) {
      case SpeechServiceState.idle:
        chatProvider.startListening();
        break;
      case SpeechServiceState.listening:
        chatProvider.stopListening();
        break;
      case SpeechServiceState.speaking:
        chatProvider.stopSpeaking();
        break;
      case SpeechServiceState.processing:
        // Do nothing while processing
        break;
    }
  }

  Color _getButtonColor(SpeechServiceState state) {
    switch (state) {
      case SpeechServiceState.idle:
        return Colors.blue;
      case SpeechServiceState.listening:
        return Colors.red;
      case SpeechServiceState.speaking:
        return Colors.green;
      case SpeechServiceState.processing:
        return Colors.orange;
    }
  }

  Widget _getButtonIcon(SpeechServiceState state) {
    switch (state) {
      case SpeechServiceState.idle:
        return const Icon(Icons.mic, color: Colors.white, size: 30);
      case SpeechServiceState.listening:
        return const Icon(Icons.stop, color: Colors.white, size: 30);
      case SpeechServiceState.speaking:
        return const Icon(Icons.volume_up, color: Colors.white, size: 30);
      case SpeechServiceState.processing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        );
    }
  }
}
