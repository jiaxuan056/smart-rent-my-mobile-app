import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/main_shell.dart';
import 'services/government_data_service.dart';
import 'services/local_account_service.dart';
import 'services/local_app_data_service.dart';
import 'state/app_state.dart';

class SmartRentApp extends StatefulWidget {
  const SmartRentApp({
    super.key,
    this.loadRemoteData = true,
    this.localAccountService,
    this.localAppDataService,
  });

  final bool loadRemoteData;
  final LocalAccountService? localAccountService;
  final LocalAppDataService? localAppDataService;

  @override
  State<SmartRentApp> createState() => _SmartRentAppState();
}

class _SmartRentAppState extends State<SmartRentApp> {
  late final AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState(
      GovernmentDataService(),
      localAccountService: widget.localAccountService,
      localAppDataService: widget.localAppDataService,
    );
    appState.initialize(loadRemoteData: widget.loadRemoteData);
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'SmartRent MY',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: appState.isInitializing
              ? const _StartupScreen()
              : appState.isSignedIn
              ? appState.isAdmin
                    ? AdminShell(appState: appState)
                    : MainShell(appState: appState)
              : AuthScreen(appState: appState),
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing SmartRent MY...'),
          ],
        ),
      ),
    );
  }
}
