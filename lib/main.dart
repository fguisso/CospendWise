import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/screens.dart';
import 'providers/user_provider.dart';
import 'providers/project_provider.dart';
import 'services/data_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DataRepository>(
          create: (_) => DataRepository(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'CospendWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF), // Modern purple
            brightness: Brightness.light,
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF03DAC5),
            tertiary: const Color(0xFFFF6584),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF03DAC5),
            tertiary: const Color(0xFFFF6584),
            background: const Color(0xFF121212),
            surface: const Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: AppBarTheme(
            centerTitle: false,
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            selectedItemColor: Color(0xFF6C63FF),
            unselectedItemColor: Colors.grey,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3D3D3D),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3D3D3D),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
            labelStyle: const TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey.shade600),
          ),
          dividerColor: const Color(0xFF3D3D3D),
        ),
        themeMode: ThemeMode.system, // This will respect the system theme
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthenticationWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-expense': (context) => const AddExpenseScreen(),
          '/user-info': (context) => const UserInfoScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/settle-up') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => SettleUpScreen(
                projectId: args['projectId']!,
                currentUserId: args['currentUserId']!,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  Future<bool> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('cospend_url');
    final username = prefs.getString('cospend_username');
    final password = prefs.getString('cospend_password');
    
    return url != null && username != null && password != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthentication(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
