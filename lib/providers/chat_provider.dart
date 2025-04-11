import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/speech_service.dart';

class ChatProvider with ChangeNotifier {
  final SpeechService _speechService;

  ChatProvider(this._speechService) {
    // Initialize the speech service
    _speechService.initialize();

    // Listen for speech results
    _speechService.onSpeechResult.listen((text) {
      notifyListeners();
    });

    // Listen for messages
    _speechService.onMessageReceived.listen((message) {
      notifyListeners();
    });

    // Listen for state changes
    _speechService.onStateChanged.listen((_) {
      notifyListeners();
    });
  }

  List<Message> get messages => _speechService.messages;
  bool get isListening => _speechService.isListening;
  bool get isSpeaking => _speechService.isSpeaking;
  bool get isProcessing => _speechService.isProcessing;
  SpeechServiceState get currentState => _speechService.currentState;

  // Get current TTS provider
  TTSProvider get ttsProvider => _speechService.ttsProvider;

  // Set TTS provider
  Future<void> setTTSProvider(TTSProvider provider) async {
    _speechService.ttsProvider = provider;
    notifyListeners();
  }

  // Get available ElevenLabs voices
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    return await _speechService.getAvailableVoices();
  }

  // Get available ElevenLabs models
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return await _speechService.getAvailableModels();
  }

  // Set ElevenLabs voice ID
  void setElevenLabsVoice(String voiceId) {
    _speechService.setElevenLabsVoice(voiceId);
    notifyListeners();
  }

  // Set ElevenLabs model ID
  void setElevenLabsModel(String modelId) {
    _speechService.setElevenLabsModel(modelId);
    notifyListeners();
  }

  // Start the speech recognition
  Future<void> startListening() async {
    await _speechService.startListening();
    notifyListeners();
  }

  // Stop the speech recognition
  Future<void> stopListening() async {
    await _speechService.stopListening();
    notifyListeners();
  }

  // Stop AI from speaking
  Future<void> stopSpeaking() async {
    await _speechService.stopSpeaking();
    notifyListeners();
  }

  // Send a text message without voice
  Future<void> sendTextMessage(String text) async {
    if (text.isEmpty) return;

    await _speechService.sendTextMessage(text);
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
