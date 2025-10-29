import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  Company? company;
  bool busy = true;
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient();
    await api.loadToken(); // <-- añade esto
    company = await api.myCompany();
    if (company != null) nameCtrl.text = company!.name;
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company == null ? 'No tienes empresa' : 'Mi empresa',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre de la empresa')),
            const SizedBox(height: 12),
            Row(
              children: [
                if (company == null)
                  FilledButton(onPressed: _create, child: const Text('Crear')),
                if (company != null) ...[
                  FilledButton(
                      onPressed: _update, child: const Text('Guardar')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                      onPressed: _delete, child: const Text('Eliminar')),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    try {
      final c = await ApiClient().createCompany(nameCtrl.text.trim());
      setState(() => company = c);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Empresa creada')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _update() async {
    try {
      final c = await ApiClient().updateCompany(nameCtrl.text.trim());
      setState(() => company = c);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Empresa actualizada')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar empresa'),
        content: const Text('Esta acción no se puede deshacer.'),
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
      try {
        await ApiClient().deleteCompany();
        setState(() => company = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Empresa eliminada')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
