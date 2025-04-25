import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import '../locale_notifier.dart';
import '../router/routing_config.dart';
import '../theme/theme.dart';
import 'providers/bloc_providers.dart';

class App extends StatelessWidget {
  final bool isDarkMode;
  const App({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier(isDarkMode: isDarkMode)),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return Consumer<LocaleNotifier>(
            builder: (context, localeNotifier, child) {
              return MultiBlocProvider(
                providers: appBlocProviders,
                child: MaterialApp.router(
                  routerConfig: RoutingConfig.router,
                  title: 'Dr Copilot',
                  theme: themeNotifier.currentTheme.copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbVisibility: WidgetStateProperty.all(true),
                      thickness: WidgetStateProperty.all(12.0),
                    ),
                    textTheme: context.locale.languageCode == 'ar'
                        ? GoogleFonts.tajawalTextTheme()
                        : GoogleFonts.robotoTextTheme(),
                  ),
                  debugShowCheckedModeBanner: false,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  builder: (context, child) {
                    debugPrint('2 Current Locale: \\${Localizations.localeOf(context).languageCode}');
                    return Stack(
                      children: [
                        child!,
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
