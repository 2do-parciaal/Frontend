import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';

class ReviewsPage extends StatefulWidget {
  final Product product;
  const ReviewsPage({super.key, required this.product});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Review> reviews = [];
  String? role;
  bool busy = true;
  final commentCtrl = TextEditingController();
  int rating = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient();
    await api.loadToken();
    role = await api.role();
    reviews = await api.reviewsForProduct(widget.product.id);
    setState(() { busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isCliente = role == 'Cliente';
    return Scaffold(
      appBar: AppBar(title: Text('Reseñas · ${widget.product.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reviews.length,
              itemBuilder: (_, i) {
                final r = reviews[i];
                return Card(
                  child: ListTile(
                    leading: Text('★' * r.rating),
                    title: Text(r.comment ?? ''),
                    subtitle: Text('Usuario #${r.userId}'),
                  ),
                );
              },
            ),
          ),
          if (isCliente) Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: rating,
                  items: List.generate(5, (i) => DropdownMenuItem(value: i+1, child: Text('★' * (i+1)))).toList(),
                  onChanged: (v) => setState(() => rating = v ?? 5),
                ),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: commentCtrl, decoration: const InputDecoration(labelText: 'Comentario (opcional)'))),
                const SizedBox(width: 12),
                FilledButton(onPressed: _send, child: const Text('Enviar')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    try {
      await ApiClient().createReview(widget.product.id, rating, commentCtrl.text.isEmpty ? null : commentCtrl.text);
      if (!mounted) return;
      commentCtrl.clear();
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gracias por tu reseña!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
