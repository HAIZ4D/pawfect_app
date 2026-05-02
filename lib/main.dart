import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/colors.dart';
import 'core/widgets/custom_bottom_nav_bar.dart';
import 'features/auth/providers/auth_provider.dart' as app_auth;
import 'features/auth/repositories/auth_repository.dart';
import 'features/pawbook/providers/pet_provider.dart';
import 'features/pawbook/screens/pawbook_home_screen.dart';
import 'features/detector/screens/detector_home_screen.dart';
import 'features/dashboard/screens/dashboard_home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PawfectApp());
}

class PawfectApp extends StatelessWidget {
  const PawfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        ChangeNotifierProvider<app_auth.AuthProvider>(
          create: (ctx) => app_auth.AuthProvider(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<PetProvider>(
          create: (_) => PetProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Pawfect',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes the user based on Firebase auth state.
///
/// • Cold start with no signed-in user → [OnboardingScreen]
/// • Cold start with a persisted session → [HomeScreen]
/// • Sign-in / sign-out events automatically swap screens — login screens
///   only need to pop back to root, the gate does the rest.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthSplash();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}

/// Splash shown for the brief moment Firebase Auth is restoring session
/// state on cold start. Matches the brand language so the transition into
/// the home screen feels seamless.
class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/pawfect-logo.png',
              width: 320,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PawfectColors.pawfectOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main Home Screen with Custom Bottom Navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const PawbookHomeScreen(),
    const DetectorHomeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Pull this user's pets the moment we land on the authed shell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PetProvider>().loadPets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
