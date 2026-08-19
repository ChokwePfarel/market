import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:market/data/data_source/otherUser_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'app.dart';
import 'data/data_source/auth_remote_data_source.dart';
import 'data/data_source/product_remote_data_source.dart';
import 'data/data_source/user_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';

import 'data/repositories/other_user_repositoryImpl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/other_user_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'data/data_source/chat_remote_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'data/data_source/images_remote_data_source.dart';
import 'data/repositories/images_repository_impl.dart';
import 'domain/repositories/images_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/data_source/payment_remote_data_source.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'domain/repositories/payment_repository.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';
import 'features/product/presentation/my_products_page.dart';
import 'core/utils/offline_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- App Startup Started ---');

  await OfflineCache.init();

  bool isSupabaseInitialized = false;

  try {
    debugPrint('Loading .env file...');
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url != null && anonKey != null) {
      debugPrint('Initializing Supabase...');
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      isSupabaseInitialized = true;
      debugPrint('Supabase initialized successfully.');
    } else {
      debugPrint('Supabase credentials missing in .env');
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  debugPrint('Setting up dependency injection...');
  _setupDependencyInjection(isSupabaseInitialized);

  debugPrint('Running MarketApp...');
  runApp(const MarketApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



//DEPENDENCES THAT CLASSES DEPENDS ON
void _setupDependencyInjection(bool isSupabaseInitialized) {
  final getIt = GetIt.instance;

  if (isSupabaseInitialized) {
    // Data Sources
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      client: Supabase.instance.client,
    );
    
    // Register live Repositories
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: authRemoteDataSource),
    );
    
    // In a real app, you'd also have a MockChatRepository
    getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(ChatRemoteDataSourceImpl(Supabase.instance.client)),
    );

    getIt.registerLazySingleton<ImagesRepository>(
      () => ImagesRepositoryImpl(ImagesRemoteDataSourceImpl(Supabase.instance.client)),
    );
  }

  // Use Mocks for these regardless (as per current main.dart state)
  final userRemoteDataSource = UserRemoteDataSourceImpl(
    client: Supabase.instance.client,
  );


  getIt.registerLazySingleton<UserRepository>(
    () {
      debugPrint('GetIt: Creating UserRepository instance...');
      final repo = UserRepositoryImpl(remoteDataSource: userRemoteDataSource);
      debugPrint('GetIt: Created repo: $repo');
      return repo;
    },
  );

  final productRemoteDataSource = ProductRemoteDataSourceImpl(
    client: Supabase.instance.client,
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: productRemoteDataSource),
  );

  getIt.registerLazySingleton<OtherUserRepository>(
    () => OtherUserRepositoryImpl(dataSource: OtherUserRemoteDataSourceImpl(client: Supabase.instance.client)),
  );

  final paymentRemoteDataSource = PaymentRemoteDataSourceImpl(
    client: http.Client(),
  );

  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: paymentRemoteDataSource),
  );
}
