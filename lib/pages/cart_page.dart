import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  OrderModel? cart;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient();
    await api.loadToken(); // <-- añade esto
    cart = await api.getCart();
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());
    final items = cart?.items ?? [];
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ...items.map((it) => Card(
                  child: ListTile(
                    title: Text(it.productName),
                    subtitle: Text(
                        'Cant: ${it.quantity} · Unit: S/${it.unitPrice.toStringAsFixed(2)}'),
                    trailing: Text('S/${it.subtotal.toStringAsFixed(2)}'),
                  ),
                )),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Center(child: Text('Tu carrito está vacío')),
            if (items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                    onPressed: _checkout,
                    icon: const Icon(Icons.payment),
                    label: Text('Pagar S/${cart!.total.toStringAsFixed(2)}')),
              )
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _checkout() async {
    try {
      final order = await ApiClient().checkout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compra OK · Pedido #${order.id}')));
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
