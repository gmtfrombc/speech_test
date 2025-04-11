import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Get the API key from .env file
  static String get openAiApiKey => dotenv.get('OPENAI_API_KEY');
  static const String openAiBaseUrl = 'https://api.openai.com/v1/audio/speech';
  static const String openAiChatUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String openAiTranscriptionUrl =
      'https://api.openai.com/v1/audio/transcriptions';

  // ElevenLabs API configuration
  static String get elevenLabsApiKey => dotenv.get('ELEVENLABS_API_KEY');
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String defaultVoiceId =
      'pNInz6obpgDQGcFmaJgB'; // Adam voice ID as placeholder
  static const String defaultModelId =
      'eleven_flash_v2_5'; // The model ID specified by the user
}
