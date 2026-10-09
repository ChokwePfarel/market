import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market/domain/repositories/other_user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/theme/app_theme.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_event.dart';
import 'features/auth/auth_state.dart';
import 'features/conversation/conversation_event.dart';
import 'features/otheruser/otheruser_bloc.dart';
import 'features/presentation/home_screen.dart';
import 'features/presentation/create_account_profile_page.dart';
import 'features/presentation/verify_page.dart';
import 'features/presentation/my_products_page.dart';
import 'features/presentation/reset_password_page.dart';
import 'features/presentation/login_page.dart';
import 'features/user/user_bloc.dart';
import 'features/user/user_event.dart';
import 'features/product/bloc/product_bloc.dart';
import 'features/product/bloc/my_products_bloc.dart';
import 'features/product/bloc/other_user_products_bloc.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/payment_repository.dart';
import 'features/chat/chat_bloc.dart';
import 'features/conversation/conversation_bloc.dart';

import 'domain/repositories/chat_repository.dart';
import 'features/images/bloc/images_bloc.dart';
import 'domain/repositories/images_repository.dart';
import 'features/network/bloc/network_bloc.dart';
import 'features/search/bloc/search_bloc.dart';
import 'package:get_it/get_it.dart';
import 'main.dart'; // Add this for navigatorKey

class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NetworkBloc()),
        BlocProvider(
          create: (context) {
            return AuthBloc(GetIt.I<AuthRepository>())
              ..add(AuthCheckRequested());
          },
        ),
        BlocProvider(
          create: (context) {
            return UserBloc(GetIt.I<UserRepository>());
          },
        ),
        BlocProvider(
          create: (context) {
            final productRepo = GetIt.I<ProductRepository>();
            final userRepo = GetIt.I<UserRepository>();
            final paymentRepo = GetIt.I<PaymentRepository>();
            return ProductBloc(productRepo, userRepo, paymentRepo);
          },
        ),
        BlocProvider(
          create: (context) {
            return ConversationsBloc(GetIt.I<ChatRepository>());
          },
        ),
        BlocProvider(
          create: (context) {
            return ChatBloc(GetIt.I<ChatRepository>());
          },
        ),
        BlocProvider(
          create: (context) {
            return OtherUserBloc(GetIt.I<OtherUserRepository>());
          },
        ),
        BlocProvider(
          create: (context) {
            return ImagesBloc(GetIt.I<ImagesRepository>());
          },
        ),
        BlocProvider(
          create: (context) => SearchBloc(GetIt.I<ProductRepository>()),
        ),
        BlocProvider(
          create: (context) => MyProductsBloc(GetIt.I<ProductRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              OtherUserProductsBloc(GetIt.I<ProductRepository>()),
        ),
      ],
      child: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _setupAuthStateListener();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    //Handle link when the app is already running in the background.
    _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });

    //Handle link when the app is launched from a terminated state..
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleIncomingLink(initialUri);
    }
  }

  void _handleIncomingLink(Uri uri) {
    // Handle payment callback
    if (uri.scheme == 'marketapp' && uri.host == 'paymentrecieved-callback') {

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyProductsPage()),
        (route) => route.isFirst,
      );
      return;
    }

    // Supabase sends the reset token as a hash fragment (e.g., #access_token=...)
    //Importantttt

    if (uri.fragment.contains('access_token')) {
      //The auth listener handles navigation when it detects passwordRecovery event
    }
  }

  void _setupAuthStateListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      // Usng GetIt since we might not have a reliable context for providers yet
      // or it's cleaner here
      final userRepo = GetIt.I<UserRepository>();

      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        //Start persistent listeners immediately

        if(!mounted) return;

        context.read<UserBloc>().add(const WatchCurrentUser());
        context.read<ConversationsBloc>().add(
          LoadConversations(session.user.id),
        );

        //Fetch specific profile details
        context.read<UserBloc>().add(LoadUserProfile(session.user.id));

        //Handle Navigation|| Check if profile is completed
        final isCompleted = await userRepo.checkIsProfileCompleted(
          session.user.id,
        );

        if (!isCompleted) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CreateAccountProfilePage()),
            (route) => false,
          );
        } else {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {

        if(!mounted) return;

        context.read<ConversationsBloc>().add(ClearConversations());
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomeScreen();
        }

        if (state is Unauthenticated || state is AuthError) {
          return const LoginPage();
        }

        if (state is EmailVerificationRequired) {
          return const VerifyPage();
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }
}

