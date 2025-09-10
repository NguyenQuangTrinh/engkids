import 'package:engkids/widgets/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
// Import màn hình chính

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Có thể tùy chỉnh theme ở đây
        fontFamily: 'Comic Sans MS', // Nhớ thêm font vào pubspec.yaml và assets
        visualDensity: VisualDensity.adaptivePlatformDensity, // Thích ứng giao diện
      ),
      home: AuthWrapper(), // Gọi màn hình câu hỏi
      debugShowCheckedModeBanner: false, // Ẩn banner debug
        navigatorObservers: [routeObserver]
    );
  }
}