import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/speech_service.dart';

class VoiceSettings extends StatefulWidget {
  const VoiceSettings({super.key});

  @override
  State<VoiceSettings> createState() => _VoiceSettingsState();
}

class _VoiceSettingsState extends State<VoiceSettings> {
  List<Map<String, dynamic>> _availableVoices = [];
  List<Map<String, dynamic>> _availableModels = [];
  String? _selectedVoiceId;
  String? _selectedModelId;
  bool _isLoadingVoices = false;
  bool _isLoadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadVoices();
    _loadModels();
  }

  Future<void> _loadVoices() async {
    setState(() {
      _isLoadingVoices = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final voices = await chatProvider.getAvailableVoices();

      setState(() {
        _availableVoices = voices;
        if (voices.isNotEmpty) {
          _selectedVoiceId = voices.first['voice_id'];
          // Immediately apply the voice selection
          chatProvider.setElevenLabsVoice(_selectedVoiceId!);
          debugPrint('VoiceSettings: Set voice ID to $_selectedVoiceId');
        }
      });
    } catch (e) {
      debugPrint('Error loading voices: $e');
    } finally {
      setState(() {
        _isLoadingVoices = false;
      });
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final models = await chatProvider.getAvailableModels();

      setState(() {
        _availableModels = models;
        // Default to the user's preferred model
        _selectedModelId = 'eleven_flash_v2_5';

        // If the preferred model exists in the list, select it
        final preferredModelExists = models.any(
          (model) => model['model_id'] == _selectedModelId,
        );

        // If not found, select the first one
        if (!preferredModelExists && models.isNotEmpty) {
          _selectedModelId = models.first['model_id'];
        }

        // Set the model in the provider
        if (_selectedModelId != null) {
          chatProvider.setElevenLabsModel(_selectedModelId!);
          debugPrint('VoiceSettings: Set model ID to $_selectedModelId');
        }
      });
    } catch (e) {
      debugPrint('Error loading models: $e');
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentProvider = chatProvider.ttsProvider;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Voice Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // TTS Provider selection
            const Text('Voice Provider:'),
            Row(
              children: [
                Radio<TTSProvider>(
                  value: TTSProvider.flutterTTS,
                  groupValue: currentProvider,
                  onChanged: (value) {
                    if (value != null) {
                      chatProvider.setTTSProvider(value);
                    }
                  },
                ),
                const Text('Flutter TTS'),
                const SizedBox(width: 16),
                Radio<TTSProvider>(
                  value: TTSProvider.elevenLabs,
                  groupValue: currentProvider,
                  onChanged: (value) {
                    if (value != null) {
                      chatProvider.setTTSProvider(value);
                    }
                  },
                ),
                const Text('ElevenLabs'),
              ],
            ),

            // ElevenLabs voice and model selection
            if (currentProvider == TTSProvider.elevenLabs) ...[
              const SizedBox(height: 16),
              const Text('ElevenLabs Voice:'),
              const SizedBox(height: 8),

              if (_isLoadingVoices)
                const Center(child: CircularProgressIndicator())
              else if (_availableVoices.isEmpty)
                Row(
                  children: [
                    const Text('No voices found. '),
                    TextButton(
                      onPressed: _loadVoices,
                      child: const Text('Refresh'),
                    ),
                  ],
                )
              else
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedVoiceId,
                  items:
                      _availableVoices.map((voice) {
                        return DropdownMenuItem<String>(
                          value: voice['voice_id'],
                          child: Text(voice['name']),
                        );
                      }).toList(),
                  onChanged: (voiceId) {
                    if (voiceId != null) {
                      setState(() {
                        _selectedVoiceId = voiceId;
                      });
                      chatProvider.setElevenLabsVoice(voiceId);
                    }
                  },
                ),

              const SizedBox(height: 16),
              const Text('ElevenLabs Model:'),
              const SizedBox(height: 8),

              if (_isLoadingModels)
                const Center(child: CircularProgressIndicator())
              else if (_availableModels.isEmpty)
                Row(
                  children: [
                    const Text('No models found. '),
                    TextButton(
                      onPressed: _loadModels,
                      child: const Text('Refresh'),
                    ),
                  ],
                )
              else
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedModelId,
                  items:
                      _availableModels.map((model) {
                        return DropdownMenuItem<String>(
                          value: model['model_id'],
                          child: Text(
                            '${model['name']} (${model['model_id']})',
                          ),
                        );
                      }).toList(),
                  onChanged: (modelId) {
                    if (modelId != null) {
                      setState(() {
                        _selectedModelId = modelId;
                      });
                      chatProvider.setElevenLabsModel(modelId);
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
