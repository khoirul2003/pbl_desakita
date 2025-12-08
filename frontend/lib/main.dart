import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/login/login_screen.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (context) => AuthProvider(context.read<ApiService>()),
          update: (context, apiService, previous) => AuthProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Desa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          
          
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primaryColor,
            primary: _primaryColor,
            secondary: _accentColor,
            background: const Color(0xFFF5F5F5), 
          ),
          
          
          inputDecorationTheme: InputDecorationTheme(
            
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none, 
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: _primaryColor, width: 2), 
            ),
            
            filled: true,
            fillColor: Colors.white, 
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            labelStyle: const TextStyle(color: _accentColor),
          ),

          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), 
              ),
              elevation: 4, 
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          
          appBarTheme: const AppBarTheme(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        home: const SplashScreen(),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}