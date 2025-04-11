import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/message.dart';
import 'elevenlabs_service.dart';

enum SpeechServiceState { idle, listening, speaking, processing }

enum TTSProvider { flutterTTS, elevenLabs }

/// Service to handle voice-based communication with OpenAI
class SpeechService {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();

  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();

  // ElevenLabs service for natural voice
  final ElevenLabsService _elevenLabsService = ElevenLabsService();

  // TTS provider selection
  TTSProvider _ttsProvider = TTSProvider.elevenLabs;

  // State management
  bool _isListening = false;
  bool _isSpeaking = false;
  SpeechServiceState _currentState = SpeechServiceState.idle;

  // Conversation history
  final List<Message> _messages = [];

  // Controllers for events
  final _speechController = StreamController<String>.broadcast();
  final _stateController = StreamController<SpeechServiceState>.broadcast();
  final _messagesController = StreamController<Message>.broadcast();

  // Streams for UI components to listen to
  Stream<String> get onSpeechResult => _speechController.stream;
  Stream<SpeechServiceState> get onStateChanged => _stateController.stream;
  Stream<Message> get onMessageReceived => _messagesController.stream;

  // Conversation history
  List<Message> get messages => List.unmodifiable(_messages);

  // Get current TTS provider
  TTSProvider get ttsProvider => _ttsProvider;

  // Set TTS provider
  set ttsProvider(TTSProvider provider) {
    _ttsProvider = provider;
  }

  // Initialize speech services
  Future<void> initialize() async {
    // Initialize speech recognition
    bool available = await _speechToText.initialize();

    // Configure text-to-speech (Flutter TTS)
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _updateState(SpeechServiceState.idle);
    });

    // Initialize ElevenLabs service
    await _elevenLabsService.initialize();

    // Log initialization status
    debugPrint(
      'Speech service initialized. Speech recognition available: $available',
    );
    debugPrint(
      'Using TTS provider: ${_ttsProvider == TTSProvider.elevenLabs ? "ElevenLabs" : "Flutter TTS"}',
    );

    if (!available) {
      debugPrint('Speech recognition not available');
    }
  }

  // Start listening to user speech
  Future<void> startListening() async {
    if (_isListening) return;

    _updateState(SpeechServiceState.listening);
    _isListening = true;

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          _speechController.add(text);

          // Add user message to history
          final message = Message(content: text, isUser: true);
          _messages.add(message);
          _messagesController.add(message);

          // Stop listening and process response
          stopListening();
          _getAIResponse();
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  // Stop listening to user speech
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;

    if (_currentState == SpeechServiceState.listening) {
      _updateState(SpeechServiceState.processing);
    }
  }

  // Get AI response based on conversation history
  Future<void> _getAIResponse() async {
    _updateState(SpeechServiceState.processing);

    try {
      // Prepare messages for API call
      final List<Map<String, dynamic>> formattedMessages =
          _messages.map((msg) => msg.toJson()).toList();

      // Call ChatGPT API
      final response = await http.post(
        Uri.parse(Config.openAiChatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.openAiApiKey}',
        },
        body: jsonEncode({'model': 'gpt-4', 'messages': formattedMessages}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Add AI message to history
        final message = Message(content: content, isUser: false);
        _messages.add(message);
        _messagesController.add(message);

        // Speak the response
        await speak(content);
      } else {
        debugPrint('Error: ${response.statusCode} - ${response.body}');
        _updateState(SpeechServiceState.idle);
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      _updateState(SpeechServiceState.idle);
    }
  }

  // Speak text using selected text-to-speech provider
  Future<void> speak(String text) async {
    if (_isSpeaking) return;

    _isSpeaking = true;
    _updateState(SpeechServiceState.speaking);

    debugPrint(
      'Speaking using provider: ${_ttsProvider == TTSProvider.elevenLabs ? "ElevenLabs" : "Flutter TTS"}',
    );

    if (_ttsProvider == TTSProvider.flutterTTS) {
      await _flutterTts.speak(text);
    } else {
      // Use ElevenLabs for more natural voice
      try {
        await _elevenLabsService.synthesizeAndPlay(text);

        // We need to update our state when playback completes
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (!_elevenLabsService.isPlaying) {
            _isSpeaking = false;
            _updateState(SpeechServiceState.idle);
            timer.cancel();
          }
        });
      } catch (e) {
        debugPrint('Error using ElevenLabs: $e');
        debugPrint('Falling back to Flutter TTS');
        // Fall back to Flutter TTS if ElevenLabs fails
        await _flutterTts.speak(text);
      }
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    if (_ttsProvider == TTSProvider.flutterTTS) {
      await _flutterTts.stop();
    } else {
      await _elevenLabsService.stop();
    }

    _isSpeaking = false;
    _updateState(SpeechServiceState.idle);
  }

  // Send a text message directly
  Future<void> sendTextMessage(String text) async {
    if (text.isEmpty) return;

    // Add user message to history
    final message = Message(content: text, isUser: true);
    _messages.add(message);
    _messagesController.add(message);

    // Get AI response
    await _getAIResponse();
  }

  // Update the current state
  void _updateState(SpeechServiceState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  // Clean up resources
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }

    if (_isSpeaking) {
      if (_ttsProvider == TTSProvider.flutterTTS) {
        _flutterTts.stop();
      } else {
        _elevenLabsService.stop();
      }
    }

    _speechController.close();
    _stateController.close();
    _messagesController.close();
    _elevenLabsService.dispose();
  }

  // Status getters for UI
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isProcessing => _currentState == SpeechServiceState.processing;
  SpeechServiceState get currentState => _currentState;

  // Get available ElevenLabs voices
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    return await _elevenLabsService.getAvailableVoices();
  }

  // Get available ElevenLabs models
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return await _elevenLabsService.getAvailableModels();
  }

  // Set ElevenLabs voice
  void setElevenLabsVoice(String voiceId) {
    _elevenLabsService.setVoiceId(voiceId);
  }

  // Set ElevenLabs model
  void setElevenLabsModel(String modelId) {
    _elevenLabsService.setModelId(modelId);
  }
}
