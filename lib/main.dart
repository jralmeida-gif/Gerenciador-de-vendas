import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/auth_gate.dart';
import 'services/app_state.dart';
import 'services/repositorio.dart';
import 'theme/app_theme.dart';
import 'utils/ajuste_ios.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final repo = Repositorio();
  await repo.init();
  runApp(GestorVendasApp(repo: repo));
}

class GestorVendasApp extends StatelessWidget {
  final Repositorio repo;
  const GestorVendasApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repo),
      child: MaterialApp(
        title: 'Gestor de Vendas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        builder: (context, child) =>
            AjusteIos(child: child ?? const SizedBox.shrink()),
        home: AuthGate(repo: repo),
      ),
    );
  }
}
