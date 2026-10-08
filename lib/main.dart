import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const BrainGymApp());

class BrainGymApp extends StatelessWidget {
  const BrainGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Brain Gym',
      tagline: 'Daily brain workouts across memory, logic and focus',
      emoji: '🧠',
      slug: 'braingym',
      howToPlay:
          '• Three mini-tests train your brain: Memory Matrix, Quick Tap and Color Clash.\n• Memory Matrix: memorize the glowing tiles, then tap them back.\n• Quick Tap: wait for green… then smash it as fast as you can!\n• Color Clash: tap the INK color of the word, not what it says.\n• Your three scores combine into one mighty Brain Score. 💪',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          BrainGymScreen(players: players, callbacks: cb),
    );
  }
}
