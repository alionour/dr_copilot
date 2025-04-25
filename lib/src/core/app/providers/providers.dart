import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../locale_notifier.dart';

final appProviders = [
  ChangeNotifierProvider(create: (context) => ThemeNotifier(isDarkMode: false)),
  ChangeNotifierProvider(create: (context) => LocaleNotifier()),
];
