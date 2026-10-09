import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/gym_themes.dart';
import 'theme/study_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = GymSettings();
  await settings.load();
  final audio = BrainAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  await store.init();
  runApp(BrainGymApp(settings: settings, audio: audio, store: store));
}

class BrainGymApp extends StatefulWidget {
  final GymSettings settings;
  final BrainAudio audio;
  final StoreService store;
  const BrainGymApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
  });

  @override
  State<BrainGymApp> createState() => _BrainGymAppState();
}

class _BrainGymAppState extends State<BrainGymApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the workout screen additionally freezes its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Brain Gym',
        debugShowCheckedModeBanner: false,
        theme: Study.theme(
          GymThemes.byId(
            widget.settings.themeId,
            custom: widget.settings.customTheme,
          ),
        ),
        home: SplashScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}
