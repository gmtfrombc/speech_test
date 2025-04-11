import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message.dart';
import '../widgets/speech_control_button.dart';
import '../widgets/voice_settings.dart';
import '../services/speech_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSettings = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Toggle settings visibility
  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Chat GPT'),
        actions: [
          _buildVoiceStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _toggleSettings,
            tooltip: 'Voice Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show settings if toggled
          if (_showSettings) const VoiceSettings(),

          // Chat messages list
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final messages = chatProvider.messages;

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  if (messages.isEmpty) {
                    return _buildWelcomeMessage();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemBuilder: (context, index) {
                      return ChatMessageWidget(message: messages[index]);
                    },
                  );
                },
              ),
            ),
          ),

          // Text input and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      ),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),

                // Voice control button
                const SpeechControlButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle submitted text
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    Provider.of<ChatProvider>(context, listen: false).sendTextMessage(text);
  }

  // Welcome message
  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Voice Chat GPT!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the microphone button to start a conversation, or type a message below.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Powered by OpenAI and ElevenLabs',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStatusIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final state = chatProvider.currentState;

        switch (state) {
          case SpeechServiceState.listening:
            return _buildPulsatingIndicator(Colors.red, Icons.mic);
          case SpeechServiceState.speaking:
            return _buildPulsatingIndicator(Colors.green, Icons.volume_up);
          case SpeechServiceState.processing:
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          case SpeechServiceState.idle:
            return const SizedBox.shrink();
        }
      },
    );
  }

  // Pulsating indicator animation
  Widget _buildPulsatingIndicator(Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Opacity(opacity: value, child: Icon(icon, color: color));
        },
        onEnd: () {
          setState(() {}); // Trigger rebuild to restart animation
        },
      ),
    );
  }
}
