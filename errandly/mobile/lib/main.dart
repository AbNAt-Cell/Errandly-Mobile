import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_inbox_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/role_select_screen.dart';
import 'features/customer/presentation/screens/customer_main_screen.dart';
import 'features/runner/presentation/screens/runner_main_screen.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  getIt.registerSingleton<ApiClient>(ApiClient());
  await PushNotificationService.initialize(getIt<ApiClient>());

  runApp(const ErrandlyApp());
}

class ErrandlyApp extends StatelessWidget {
  const ErrandlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.customerTheme,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _loading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      await PushNotificationService.registerDeviceTokenIfPossible();
      await NotificationInboxService.refresh(getIt<ApiClient>());
      final isRunner = await AuthService.isRunner();
      _nextScreen = isRunner ? const RunnerMainScreen() : const CustomerMainScreen();
    } else {
      _nextScreen = const RoleSelectScreen();
    }

    if (mounted) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.handlePendingNotification();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();
    return _nextScreen!;
  }
}
