import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'page/home/home.dart';
import 'page/home/home_decide.dart';
import 'page/login/login.dart';
import 'page/login/register.dart';
import 'page/pronunciation_guide/voice_assistant.dart';
import 'page/quiz/topic_quiz.dart';
import 'page/talk_with_insighted/talk_insighted_p1.dart';
import 'page/talk_with_insighted/talk_insighted_p3.dart';
import 'page/story_telling/storytelling.dart';
import 'page/story_telling/storytelling2.dart';
import 'page/game/game.dart';
import 'page/ui/comingsoon.dart';
import 'page/ui/welcome.dart';
import 'page/insighted_gyan/story1.dart';
import 'page/insighted_gyan/tech/ch1.dart';
import 'page/insighted_gyan/tech/DSA.dart';
import 'page/insighted_gyan/tech/quizDsa.dart';
import 'page/quiz/StartQuiz.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const InsightEdApp());
}

class InsightEdApp extends StatefulWidget {
  const InsightEdApp({super.key});

  @override
  State<InsightEdApp> createState() => _InsightEdAppState();
}

class _InsightEdAppState extends State<InsightEdApp> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'insightED',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A6CF7),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6CF7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: 'welcome',
      routes: {
        'welcome': (context) => const WelcomeScreen(),
        'homeDecide': (context) => const HomeDecide(),
        'register': (context) => const MyRegister(),
        'login': (context) => const MyLogin(),
        'home': (context) => const HomePage(),
        'TopicQuiz': (context) => const TopicQuiz(),
        'VoiceAssistant': (context) => const VoiceAssistant(),
        'talkInsightEd1': (context) => const TalkInsightEd1(),
        'talkInsightEd3': (context) => const TalkInsightEd3(),
        'StoryTelling': (context) => const StoryTelling(),
        'StoryTelling2': (context) => const Storytelling2(),
        'ComingSoon': (context) => const ComingSoon(),
        'vocogyan': (context) => const InsightEdGyan(),
        'Technical': (context) => const Technical(),
        'dsa': (context) => const DSA(),
        'DsaQuiz': (context) => const DsaQuiz(),
        'StartQuiz': (context) => const StartQuiz(),
        'Games': (context) => const Games(),
      },
    );
  }
}
