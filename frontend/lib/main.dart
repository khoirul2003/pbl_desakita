import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/login/login_screen.dart';
import 'package:frontend/screens/home/home_screen.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B); // Digunakan sebagai warna sekunder

void main() {
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
          
          // 1. SKEMA WARNA PROSCAN
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primaryColor,
            primary: _primaryColor,
            secondary: _accentColor,
            background: const Color(0xFFF5F5F5), // Latar belakang abu-abu muda
          ),
          
          // 2. TEMA INPUT FIELD (Gaya Bersih/Floating)
          inputDecorationTheme: InputDecorationTheme(
            // Menggunakan OutlineInputBorder untuk border yang membulat
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none, // Menghilangkan border tebal
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: _primaryColor, width: 2), // Aksen biru saat fokus
            ),
            
            filled: true,
            fillColor: Colors.white, // Latar belakang input field PUTIH BERSIH
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            labelStyle: const TextStyle(color: _accentColor),
          ),

          // 3. TEMA TOMBOL ELEVATED BUTTON
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, // Warna primer untuk tombol utama
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Sudut membulat
              ),
              elevation: 4, // Menambahkan shadow lembut
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Mengatur style AppBar (untuk konsistensi jika masih ada AppBar standar yang digunakan)
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