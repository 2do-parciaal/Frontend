import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.loadToken();
  final sp = await SharedPreferences.getInstance();
  final token = sp.getString('token');
  final role = sp.getString('role');
  runApp(MyApp(isLoggedIn: token != null, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  const MyApp({super.key, required this.isLoggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorSchemeSeed: Colors.teal,
      useMaterial3: true,
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );

    return MaterialApp(
      title: 'Ecommerce',
      theme: theme,
      home: isLoggedIn
          ? HomePage(initialRole: role ?? 'Cliente')
          : const LoginPage(),
    );
  }
}
