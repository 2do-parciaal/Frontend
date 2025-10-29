import 'package:flutter/material.dart';
import '../api/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Cliente';
  bool _busy = false;
  String? _error;
  String? _ok;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _password, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'Cliente', child: Text('Cliente')),
                    DropdownMenuItem(value: 'Empresa', child: Text('Empresa')),
                  ],
                  onChanged: (v) => setState(() => _role = v as String),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_ok != null) Text(_ok!, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _register,
                  child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() { _busy = true; _error = null; _ok = null; });
    try {
      final api = ApiClient();
      await api.register(_name.text.trim(), _email.text.trim(), _password.text.trim(), _role);
      setState(() { _ok = 'Usuario creado, ahora inicia sesión.'; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }
}
