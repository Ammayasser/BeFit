import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/init/bootstrap.dart';
import 'core/init/provider_setup.dart';
import 'core/init/app_init_manager.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Bootstrap.init();
  final prefs = await SharedPreferences.getInstance();

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: ProviderSetup.getProviders(authProvider, prefs),
      child: BeFitApp(authProvider: authProvider),
    ),
  );
}

class BeFitApp extends StatefulWidget {
  final AuthProvider authProvider;
  const BeFitApp({super.key, required this.authProvider});

  @override
  State<BeFitApp> createState() => _BeFitAppState();
}

class _BeFitAppState extends State<BeFitApp> {
  late final _router = AppRouter.router(authProvider: widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return AppInitManager(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.themeMode == ThemeMode.dark || 
                        (themeProvider.themeMode == ThemeMode.system && 
                         MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          
          return MaterialApp.router(
            title: 'BeFit',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            // Ensure transitions are smooth
            builder: (context, child) {
              return AnimatedTheme(
                data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
