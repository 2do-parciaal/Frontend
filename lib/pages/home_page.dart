import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'products_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'company_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String initialRole;
  const HomePage({super.key, required this.initialRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String role = 'Cliente';
  int index = 0;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = role == 'Empresa';
    final isCliente = role == 'Cliente';
    final tabs = <Widget>[
      const ProductsPage(),
      if (isCliente) const CartPage(),
      if (isCliente) const OrdersPage(),
      if (isEmpresa) const CompanyPage(),
    ];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Productos'),
      if (isCliente) const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
      if (isCliente) const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Mis pedidos'),
      if (isEmpresa) const BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Mi empresa'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Ecommerce · $role'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: items,
      ),
    );
  }

  Future<void> _logout() async {
    await ApiClient().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }
}
