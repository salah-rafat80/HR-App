import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/theme_cubit.dart';
import 'core/bloc/session_cubit.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/utils/crash_reporter.dart';
import 'core/widgets/global_fallback_widget.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Easy Localization
    await EasyLocalization.ensureInitialized();
    
    // Initialize Dependency Injection
    await initDI();
    
    // Disable Google Fonts runtime fetching to prevent crashes when offline
    GoogleFonts.config.allowRuntimeFetching = true;

    // Set custom error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      final reporter = getIt<CrashReporter>();
      reporter.logError(details.exception, details.stack ?? StackTrace.empty);
      return GlobalFallbackWidget(details: details);
    };

    // Catch widget build errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final reporter = getIt<CrashReporter>();
      reporter.logError(details.exception, details.stack ?? StackTrace.empty);
      FlutterError.presentError(details);
    };

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<ThemeCubit>()),
            BlocProvider.value(value: getIt<SessionCubit>()),
          ],
          child: const App(),
        ),
      ),
    );
  }, (error, stackTrace) {
    // Catch asynchronous errors
    if (getIt.isRegistered<CrashReporter>()) {
      getIt<CrashReporter>().logError(error, stackTrace);
    } else {
      debugPrint('Uncaught Error: $error');
    }
  });
}

