import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_helper.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/app_splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageHelper = StorageHelper();
  runApp(
    AppBootstrap(
      storageHelper: storageHelper,
      initialization: storageHelper.init(),
    ),
  );
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({
    required this.storageHelper,
    required this.initialization,
    super.key,
  });

  final StorageHelper storageHelper;
  final Future<void> initialization;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const Scaffold(
              backgroundColor: Color(0xFF2196F3),
              body: AppSplashView(),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text('Failed to start app: ${snapshot.error}'),
              ),
            ),
          );
        }

        return MyApp(storageHelper: storageHelper);
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.storageHelper,
    super.key,
  });

  final StorageHelper storageHelper;

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      dioClient: dioClient,
    );

    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      storageHelper: storageHelper,
    );
    final authBloc = AuthBloc(
      authRepository: authRepository,
      storageHelper: storageHelper,
    );
    final appRouter = AppRouter(
      authBloc: authBloc,
      storageHelper: storageHelper,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
      ],
      child: MaterialApp.router(
        title: 'Employee Activity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: appRouter.router,
      ),
    );
  }
}
