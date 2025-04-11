import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/speech_service.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

Future<void> main() async {
  // Enable detailed logging
  debugPrint('Starting Voice Chat GPT app');

  // Load environment variables before running the app
  debugPrint('Loading environment variables from .env');
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SpeechService>(
          create: (_) => SpeechService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<SpeechService, ChatProvider>(
          create:
              (context) => ChatProvider(
                Provider.of<SpeechService>(context, listen: false),
              ),
          update:
              (context, speechService, previous) =>
                  previous ?? ChatProvider(speechService),
        ),
      ],
      child: MaterialApp(
        title: 'Voice Chat GPT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const ChatScreen(),
      ),
    );
  }
}
