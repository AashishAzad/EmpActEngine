import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_helper.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storageHelper = StorageHelper();
  await storageHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final dioClient = DioClient();
    final storageHelper = StorageHelper();

    // Create data sources
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      dioClient: dioClient,
    );

    // Create repositories
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      storageHelper: storageHelper,
    );

    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            storageHelper: storageHelper,
          ),
        ),
        // Add more BLoCs here as you create them
      ],
      child: MaterialApp.router(
        title: 'Employee Activity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}