import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlanTomorrowApp());
}

class PlanTomorrowApp extends StatelessWidget {
  const PlanTomorrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: MaterialApp(
        title: 'Plan Tomorrow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const HomeShell(),
      ),
    );
  }
}
