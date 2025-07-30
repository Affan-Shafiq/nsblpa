import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'models/player.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';
import 'services/contract_service.dart';
import 'services/financial_service.dart';
import 'services/seed_service.dart';
import 'services/conversation_service.dart';
import 'services/admin_service.dart';
import 'services/endorsement_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/contracts/contracts_screen.dart';
import 'screens/endorsements/endorsements_screen.dart';
import 'screens/finances/finances_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/union/union_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/dev_seed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const NSBLPAApp());
}

class NSBLPAApp extends StatelessWidget {
  const NSBLPAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, PlayerService>(
          create: (_) => PlayerService(),
          update: (_, auth, playerService) => playerService!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => ContractService()),
        ChangeNotifierProvider(create: (_) => FinancialService()),
        ChangeNotifierProxyProvider<AuthService, ConversationService>(
          create: (context) => ConversationService(Provider.of<AuthService>(context, listen: false)),
          update: (_, auth, conversationService) => ConversationService(auth),
        ),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => EndorsementService()),
        Provider(create: (_) => SeedService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return MaterialApp.router(
            title: 'NSBLPA Players App',
            theme: salesBetsTheme,
            routerConfig: _createRouter(authService),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final isOnAuthPage = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/signup' ||
                           state.matchedLocation == '/splash';
        
        // Debug print to see what's happening
        print('Router redirect: isLoggedIn=$isLoggedIn, location=${state.matchedLocation}');
        
        if (!isLoggedIn && !isOnAuthPage) {
          return '/splash';
        }
        
        if (isLoggedIn && isOnAuthPage) {
          return '/dashboard';
        }
        
        // Check admin access for admin-only routes
        if (isLoggedIn && (state.matchedLocation == '/admin' || state.matchedLocation == '/dev-seed')) {
          final playerService = Provider.of<PlayerService>(context, listen: false);
          final isAdmin = playerService.currentPlayer?.role == 'admin';
          
          if (!isAdmin) {
            return '/dashboard'; // Redirect non-admin users to dashboard
          }
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/dashboard',
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/contracts',
              builder: (context, state) => const ContractsScreen(),
            ),
            GoRoute(
              path: '/endorsements',
              builder: (context, state) => const EndorsementsScreen(),
            ),
            GoRoute(
              path: '/finances',
              builder: (context, state) => const FinancesScreen(),
            ),
            GoRoute(
              path: '/messaging',
              builder: (context, state) => const MessagingScreen(),
            ),
            GoRoute(
              path: '/union',
              builder: (context, state) => const UnionScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminScreen(),
            ),
            GoRoute(
              path: '/dev-seed',
              builder: (context, state) => const DevSeedScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        return Scaffold(
          body: this.child,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.card,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.subtitle,
            currentIndex: _getCurrentIndex(context),
            onTap: (index) => _onItemTapped(context, index),
            items: _getNavigationItems(context),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getNavigationItems(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final isAdmin = playerService.currentPlayer?.role == 'admin';
    
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.description),
        label: 'Contracts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.star),
        label: 'Endorsements',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: 'Finances',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.message),
        label: 'Messages',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'Union',
      ),
    ];

    // Add admin panel for admin users
    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }

    // Add dev tools for admin users only
    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.build),
        label: 'Dev',
      ));
    }

    return items;
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final isAdmin = playerService.currentPlayer?.role == 'admin';
    
    // Get the total number of navigation items
    final items = _getNavigationItems(context);
    
    switch (location) {
      case '/dashboard':
        return 0;
      case '/profile':
        return 1;
      case '/contracts':
        return 2;
      case '/endorsements':
        return 3;
      case '/finances':
        return 4;
      case '/messaging':
        return 5;
      case '/union':
        return 6;
      case '/admin':
        return isAdmin && items.length > 7 ? 7 : 0;
      case '/dev-seed':
        return isAdmin && items.length > 8 ? 8 : 0;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final isAdmin = playerService.currentPlayer?.role == 'admin';
    
    // Get the total number of navigation items
    final items = _getNavigationItems(context);
    
    // Safety check: ensure index is within bounds
    if (index >= items.length) {
      context.go('/dashboard');
      return;
    }
    
    // Base navigation items (same for all users)
    if (index < 7) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/profile');
          break;
        case 2:
          context.go('/contracts');
          break;
        case 3:
          context.go('/endorsements');
          break;
        case 4:
          context.go('/finances');
          break;
        case 5:
          context.go('/messaging');
          break;
        case 6:
          context.go('/union');
          break;
      }
      return;
    }
    
    // Admin-only navigation items
    if (isAdmin) {
      if (index == 7 && items.length > 7) {
        context.go('/admin');
      } else if (index == 8 && items.length > 8) {
        context.go('/dev-seed');
      } else {
        // Fallback to dashboard if index is out of bounds
        context.go('/dashboard');
      }
    } else {
      // Non-admin users should not reach here, but just in case
      context.go('/dashboard');
    }
  }
}
