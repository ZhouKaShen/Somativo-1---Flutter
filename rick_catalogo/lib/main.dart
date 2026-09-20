import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/consumed_provider.dart';
import 'screens/login_screen.dart';
import 'screens/catalog_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização da nuvem Supabase
  await Supabase.initialize(
    url: 'https://eujpdeqbgwvydagrvooo.supabase.co',
    publishableKey: 'sb_publishable_bT9w9VzSLUeQ4d0yP9WVdg_Uz8_xSEd',
  );

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(storage)),
        ChangeNotifierProvider(create: (_) => ConsumedProvider(storage)),
      ],
      child: MaterialApp(
        title: 'Catálogo Rick and Morty',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        // RF10 — respeita o ajuste de fonte do sistema, sem estourar
        // no máximo o dobro do tamanho padrão para não quebrar layouts.
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.6,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },
        home: const _AuthGate(),
      )
    );
  }
}

// Decide, na abertura do app, se mostra Login ou o catalogo direto,
// restaurando a sessão salva localmente (RF07).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastLoadedUser;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o usuário está logado e mudou desde a última carga (ex: acabou de logar)
        if (auth.isLoggedIn && auth.currentUser != null) {
          final currentUser = auth.currentUser!;
          if (_lastLoadedUser != currentUser) {
            _lastLoadedUser = currentUser;
            // Executa o carregamento das listas em segundo plano
            Future.microtask(() async {
              if (context.mounted) {
                await context.read<FavoritesProvider>().loadForUser(currentUser);
                await context.read<ConsumedProvider>().loadForUser(currentUser);
              }
            });
          }
        } else {
          _lastLoadedUser = null;
        }

        return auth.isLoggedIn ? const CatalogScreen() : const LoginScreen();
      },
    );
  }
}