import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

import 'pages/bootstrap_error_page.dart';
import 'pages/home_page.dart';
import 'widgets/scenario_dashboard.dart';
import 'examples/manual_scenario.dart';
import 'examples/di_example.dart';

class ExampleApp extends StatefulWidget {
  final String? bootstrapError;

  const ExampleApp({super.key, this.bootstrapError});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  AuthRepository? _authRepository;
  AuthBloc? _authBloc;
  bool _isDarkMode = false;
  int _currentScenario = 0; // 0: Flow, 1: Manual, 2: DI Configuration
  bool _showDashboard = true;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapError != null) {
      return;
    }

    _authRepository = FirebaseAuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      createUserCollection: true,
      serverClientId:
          '789348142189-58e9t524q6pk14a67pk21lasvogudlaj.apps.googleusercontent.com',
      clientId:
          '789348142189-58e9t524q6pk14a67pk21lasvogudlaj.apps.googleusercontent.com',
    );

    _authBloc = AuthBloc(repository: _authRepository!)
      ..add(const InitializeAuthEvent());
  }

  @override
  void dispose() {
    _authBloc?.close();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bootstrapError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: BootstrapErrorPage(error: widget.bootstrapError!),
      );
    }

    return BlocProvider.value(
      value: _authBloc!,
      child: MaterialApp(
        title: 'Remote Auth Module Examples',
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D2671),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D2671),
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          appBar:
              _showDashboard
                  ? AppBar(
                    title: const Text('Module Scenarios'),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        ),
                        onPressed: _toggleTheme,
                      ),
                    ],
                  )
                  : null,
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF1D2671)),
                  child: Text(
                    'Integration Scenarios',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                ListTile(
                  title: const Text('Scenario Dashboard'),
                  leading: const Icon(Icons.dashboard),
                  selected: _showDashboard,
                  onTap:
                      () => setState(() {
                        _showDashboard = true;
                        Navigator.pop(context);
                      }),
                ),
                const Divider(),
                ListTile(
                  title: const Text('RemoteAuthFlow (Easy)'),
                  leading: const Icon(Icons.auto_fix_high),
                  selected: !_showDashboard && _currentScenario == 0,
                  onTap:
                      () => setState(() {
                        _currentScenario = 0;
                        _showDashboard = false;
                        Navigator.pop(context);
                      }),
                ),
                ListTile(
                  title: const Text('Manual Integration'),
                  leading: const Icon(Icons.settings_input_component),
                  selected: !_showDashboard && _currentScenario == 1,
                  onTap:
                      () => setState(() {
                        _currentScenario = 1;
                        _showDashboard = false;
                        Navigator.pop(context);
                      }),
                ),
                ListTile(
                  title: const Text('DI & Repo Config'),
                  leading: const Icon(Icons.extension),
                  selected: !_showDashboard && _currentScenario == 2,
                  onTap:
                      () => setState(() {
                        _currentScenario = 2;
                        _showDashboard = false;
                        Navigator.pop(context);
                      }),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Toggle Theme'),
                  leading: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onTap: _toggleTheme,
                ),
              ],
            ),
          ),
          body: _buildScenario(),
        ),
      ),
    );
  }

  Widget _buildScenario() {
    if (_showDashboard) {
      return ScenarioDashboard(
        onSelect:
            (index) => setState(() {
              _currentScenario = index;
              _showDashboard = false;
            }),
      );
    }

    switch (_currentScenario) {
      case 0:
        return RemoteAuthFlow(
          loginTitle: 'Auth Flow Template',
          showGoogleSignIn: true,
          showPhoneSignIn: true,
          showAnonymousSignIn: true,
          authenticatedBuilder:
              (context, user) => HomePage(
                user: user,
                onToggleTheme: _toggleTheme,
                isDarkMode: _isDarkMode,
              ),
        );
      case 1:
        return const ManualIntegrationScenario();
      case 2:
        return const DIExamplePage();
      default:
        return Container();
    }
  }
}
