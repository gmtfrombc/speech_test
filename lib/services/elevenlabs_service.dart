import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../config.dart';

/// Service to handle text-to-speech using ElevenLabs API
class ElevenLabsService {
  // Audio player for ElevenLabs audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Track if audio is currently playing
  bool _isPlaying = false;

  // Voice ID to use (can be changed)
  String _voiceId;

  // Model ID to use (can be changed)
  String _modelId;

  // Constructor
  ElevenLabsService({String? voiceId, String? modelId})
    : _voiceId = voiceId ?? Config.defaultVoiceId,
      _modelId = modelId ?? Config.defaultModelId;

  // Getter for playing status
  bool get isPlaying => _isPlaying;

  // Set voice ID
  void setVoiceId(String voiceId) {
    _voiceId = voiceId;
  }

  // Set model ID
  void setModelId(String modelId) {
    _modelId = modelId;
  }

  /// Initialize the service
  Future<void> initialize() async {
    // Set up completion handlers
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
      }
    });

    // Initialize audio player without preloading
    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse('about:blank')),
      );
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      // Continue without preloading if there's an error
    }
  }

  /// Synthesize speech using ElevenLabs API and play the result
  Future<void> synthesizeAndPlay(String text) async {
    if (text.isEmpty) return;

    try {
      _isPlaying = true;
      debugPrint(
        'ElevenLabs: Synthesizing speech with voice ID: $_voiceId, model: $_modelId',
      );

      // Check if API key is available
      final apiKey = Config.elevenLabsApiKey;
      if (apiKey.isEmpty) {
        throw Exception(
          'ElevenLabs API key is missing. Add it to your .env file.',
        );
      }

      // Make API request to ElevenLabs
      final url = Uri.parse(
        '${Config.elevenLabsBaseUrl}/text-to-speech/$_voiceId',
      );
      debugPrint('ElevenLabs: Making request to: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'xi-api-key': apiKey},
        body: jsonEncode({
          'text': text,
          'model_id': _modelId,
          'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('ElevenLabs: Successfully received audio response');
        // Save audio bytes to a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/elevenlabs_audio.mp3');
        await file.writeAsBytes(response.bodyBytes);

        debugPrint('ElevenLabs: Saved audio to ${file.path}');

        // Play the audio
        await _audioPlayer.setFilePath(file.path);
        await _audioPlayer.play();
        debugPrint('ElevenLabs: Started playing audio');
      } else {
        // Handle error
        debugPrint('ElevenLabs API Error: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        _isPlaying = false;
        throw Exception('ElevenLabs API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ElevenLabs synthesis error: $e');
      _isPlaying = false;
      rethrow; // Rethrow to let calling code handle the error
    }
  }

  /// Synthesize and stream audio for faster playback using streaming API
  Future<void> synthesizeAndStreamAudio(String text) async {
    if (text.isEmpty) return;

    try {
      _isPlaying = true;
      debugPrint(
        'ElevenLabs: Streaming speech with voice ID: $_voiceId, model: $_modelId',
      );

      // Check if API key is available
      final apiKey = Config.elevenLabsApiKey;
      if (apiKey.isEmpty) {
        throw Exception(
          'ElevenLabs API key is missing. Add it to your .env file.',
        );
      }

      // Start the API request in parallel with audio player setup
      final url = Uri.parse(
        '${Config.elevenLabsBaseUrl}/text-to-speech/$_voiceId',
      );

      // Create a temporary file path
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/elevenlabs_audio.mp3');

      // Make the API request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'xi-api-key': apiKey},
        body: jsonEncode({
          'text': text,
          'model_id': _modelId,
          'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
        }),
      );

      if (response.statusCode == 200) {
        // Write the audio file
        await file.writeAsBytes(response.bodyBytes);

        // Set up the audio player in parallel
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.file(file.path)),
          preload: true,
        );

        // Start playback immediately
        await _audioPlayer.play();
        debugPrint('ElevenLabs: Started playing audio');
      } else {
        debugPrint('ElevenLabs API Error: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        _isPlaying = false;
        throw Exception('ElevenLabs API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ElevenLabs synthesis error: $e');
      _isPlaying = false;
      rethrow;
    }
  }

  /// Stop speech playback
  Future<void> stop() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }

  /// Get available voices from ElevenLabs
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.elevenLabsBaseUrl}/voices'),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': Config.elevenLabsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['voices']);
      } else {
        debugPrint(
          'Error getting voices: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Exception getting voices: $e');
      return [];
    }
  }

  /// Get available models from ElevenLabs
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      debugPrint('ElevenLabs: Fetching available models');
      final response = await http.get(
        Uri.parse('${Config.elevenLabsBaseUrl}/models'),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': Config.elevenLabsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('ElevenLabs: Models API response: ${response.body}');

        // Different parsing based on response structure
        if (data.containsKey('models')) {
          return List<Map<String, dynamic>>.from(data['models']);
        } else if (data is List) {
          // Handle case where response is an array
          return List<Map<String, dynamic>>.from(data);
        } else {
          // Create a model list from the data if it's a single model
          return [Map<String, dynamic>.from(data)];
        }
      } else {
        debugPrint(
          'Error getting models: ${response.statusCode} - ${response.body}',
        );
        // Return default model as fallback
        return [
          {
            'model_id': Config.defaultModelId,
            'name': 'Default Model (${Config.defaultModelId})',
          },
        ];
      }
    } catch (e) {
      debugPrint('Exception getting models: $e');
      // Return default model as fallback
      return [
        {
          'model_id': Config.defaultModelId,
          'name': 'Default Model (${Config.defaultModelId})',
        },
      ];
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
