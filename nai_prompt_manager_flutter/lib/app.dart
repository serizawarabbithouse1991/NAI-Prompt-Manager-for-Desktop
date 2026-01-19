import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/themes/nai_theme.dart';
import 'presentation/screens/home_screen.dart';

/// PromptVault アプリケーション
class PromptVaultApp extends ConsumerWidget {
  const PromptVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: 'PromptVault',
      debugShowCheckedModeBanner: false,
      theme: NaiTheme.dark,
      darkTheme: NaiTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
