import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import 'reviews_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  bool busy = true;
  String? error;
  String? role;
  Company? myCompany;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    final api = ApiClient();
    try {
      await api.loadToken();
      role = await api.role();
      if (role == 'Empresa') {
        myCompany = await api.myCompany();
      }
      products = await api.getProducts();
      setState(() {
        busy = false;
      });
    } catch (e) {
      setState(() {
        busy = false;
        error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final isEmpresa = role == 'Empresa';
    final isCliente = role == 'Cliente';

    return Scaffold(
      floatingActionButton: isEmpresa
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              label: const Text('Nuevo'),
              icon: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            final owned =
                isEmpresa && myCompany != null && p.companyId == myCompany!.id;

            return Card(
              child: ListTile(
                isThreeLine: true,
                minVerticalPadding: 6,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                title: Text(p.name),
                subtitle: Text(
                  p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 👇 Escala el bloque de la derecha si no entra (evita overflow)
                trailing: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('S/${p.price.toStringAsFixed(2)}'),
                      Text('Stock: ${p.stock}'),
                      if (isCliente && p.stock > 0)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(64, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _addToCart(p),
                          child: const Text('Agregar'),
                        ),
                    ],
                  ),
                ),
                onTap: () => _openReviews(p),
                leading: owned
                    ? PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _openEdit(p);
                          if (v == 'del') _delete(p);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'del', child: Text('Eliminar')),
                        ],
                        child: const Icon(Icons.more_vert),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  void _openReviews(Product p) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReviewsPage(product: p)));
  }

  Future<void> _openCreate() async {
    await showDialog(context: context, builder: (_) => const _ProductDialog());
    await _load();
  }

  Future<void> _openEdit(Product p) async {
    await showDialog(context: context, builder: (_) => _ProductDialog(edit: p));
    await _load();
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar ${p.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await ApiClient().deleteProduct(p.id);
      await _load();
    }
  }

  Future<void> _addToCart(Product p) async {
    final qtyCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Agregar ${p.name}'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true) {
      final qty = int.tryParse(qtyCtrl.text) ?? 1;
      try {
        await ApiClient().addToCart(p.id, qty);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto agregado al carrito')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? edit;
  const _ProductDialog({this.edit});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      nameCtrl.text = widget.edit!.name;
      descCtrl.text = widget.edit!.description;
      priceCtrl.text = widget.edit!.price.toString();
      stockCtrl.text = widget.edit!.stock.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 8),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  final api = ApiClient();
                  if (widget.edit == null) {
                    await api.createProduct(
                      nameCtrl.text,
                      descCtrl.text,
                      double.tryParse(priceCtrl.text) ?? 0,
                      int.tryParse(stockCtrl.text) ?? 0,
                    );
                  } else {
                    await api.updateProduct(
                      widget.edit!.id,
                      nameCtrl.text,
                      descCtrl.text,
                      double.tryParse(priceCtrl.text) ?? 0,
                      int.tryParse(stockCtrl.text) ?? 0,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
          child: busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.edit == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
