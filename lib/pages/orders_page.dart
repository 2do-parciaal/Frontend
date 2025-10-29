import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<OrderModel> orders = [];
  bool busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient();
    await api.loadToken(); // <-- añade esto
    orders = await api.myOrders();
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final o = orders[i];
            return Card(
              child: ListTile(
                leading: Icon(o.isPaid ? Icons.check_circle : Icons.pending),
                title: Text('Pedido #${o.id}'),
                subtitle: Text('Items: ${o.items.length}'),
                trailing: Text('Total: S/${o.total.toStringAsFixed(2)}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
