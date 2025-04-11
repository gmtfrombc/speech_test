# Voice Chat GPT

A Flutter application that allows real-time voice communication with ChatGPT's AI model.

## Features

- Speech-to-text conversion for user input
- Text-to-speech for AI responses
- Natural human-like voice synthesis with ElevenLabs
- Visual indicators for listening/speaking status
- Text transcript of the entire conversation
- Support for text input as an alternative to voice

## Setup Instructions

1. **Environment Setup**
   
   Create a `.env` file in the project root directory with the following content:

   ```
   OPENAI_API_KEY=your_actual_openai_api_key_here
   ELEVENLABS_API_KEY=your_elevenlabs_api_key_here
   ```

2. **Install Dependencies**

   Run the following command to install all required dependencies:

   ```
   flutter pub get
   ```

3. **Run the App**

   Connect a device or start an emulator, then run:

   ```
   flutter run
   ```

## Usage

1. Tap the microphone button to start speaking
2. Wait for the AI to process and respond
3. The AI will speak its response out loud
4. A transcript of the conversation is shown on screen
5. You can also type messages instead of speaking
6. Tap the settings icon in the app bar to configure voice settings:
   - Switch between Flutter TTS (mechanical voice) and ElevenLabs (natural voice)
   - Select from available ElevenLabs voice models

## Permissions

The app requires the following permissions:

- Microphone access (for speech recording)
- Internet access (for API communication)

## Technical Details

- Built with Flutter using the Provider pattern for state management
- Uses `speech_to_text` package for speech recognition
- Uses `flutter_tts` package for basic text-to-speech conversion
- Integrates ElevenLabs API for high-quality natural voice synthesis
- Integrates with OpenAI's API for AI responses
- Uses `flutter_dotenv` for secure environment variable management
- Uses `just_audio` for playback of ElevenLabs audio

## ElevenLabs Integration

The app supports ElevenLabs' advanced voice synthesis technology to provide more natural-sounding responses. Key features include:

- High-quality, human-like speech synthesis
- Multiple voice options that can be selected at runtime
- Toggle between basic TTS and premium ElevenLabs voices
- Secure API key management

To use ElevenLabs voices:
1. Sign up for an ElevenLabs account at [elevenlabs.io](https://elevenlabs.io)
2. Obtain your API key from the ElevenLabs dashboard
3. Add your API key to the `.env` file
4. Open the app settings and switch to the ElevenLabs provider
5. Select your preferred voice from the dropdown menu
