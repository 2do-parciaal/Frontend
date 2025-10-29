import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiClient {
  static const String baseUrl = 'https://app-251029145516.azurewebsites.net';
  String? _token;

  Future<void> loadToken() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('token');
  }

  // NUEVO: asegurar token sin necesidad de que la pantalla lo haga
  Future<void> _ensureToken() async {
    if (_token == null) {
      final sp = await SharedPreferences.getInstance();
      _token = sp.getString('token');
    }
  }

  Future<void> saveSession(UserSession s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', s.token);
    await sp.setString('role', s.role);
    _token = s.token;
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('role');
    _token = null;
  }

  Future<String?> role() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('role');
  }

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer ' + _token!,
      };

  Exception _error(http.Response r) {
    var msg = r.body;
    try {
      final m = jsonDecode(r.body);
      if (m is Map && m['message'] is String) msg = m['message'];
      if (m is Map && m['error'] is String) msg = m['error'];
      if (m is Map && m['title'] is String) msg = m['title'];
    } catch (_) {}
    return Exception('[${r.statusCode}] $msg');
  }

  // === Auth ===
  Future<UserSession> login(String email, String password) async {
    final payload = jsonEncode({'email': email, 'password': password});
    final paths = [
      '/api/Auth/login',
      '/api/Auth/Login',
      '/api/Authentication/login',
      '/api/Users/login',
      '/api/Account/login',
    ];
    http.Response? last;
    for (final p in paths) {
      final url = Uri.parse(baseUrl + p);
      final res = await http
          .post(url, headers: _headers(), body: payload)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token =
            (data['token'] ?? data['jwt'] ?? data['accessToken']) as String;
        final role = (data['role'] as String?) ?? 'Cliente';
        final session = UserSession(token: token, role: role);
        await saveSession(session);
        return session;
      }
      if (res.statusCode == 404 || res.statusCode == 405) {
        last = res;
        continue;
      }
      throw _error(res);
    }
    throw _error(last ?? http.Response('Endpoint de login no encontrado', 404));
  }

  Future<void> register(
      String name, String email, String password, String role) async {
    final candidates = [
      {'name': name, 'email': email, 'password': password, 'role': role},
      {'fullName': name, 'email': email, 'password': password, 'role': role},
      {'username': name, 'email': email, 'password': password, 'role': role},
    ];
    final paths = [
      '/api/Auth/register',
      '/api/Auth/Register',
      '/api/Authentication/register',
      '/api/Users/register',
      '/api/Account/register',
    ];
    http.Response? last;
    for (final body in candidates) {
      for (final p in paths) {
        final url = Uri.parse(baseUrl + p);
        final res = await http
            .post(url, headers: _headers(), body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 || res.statusCode == 201) return;
        if (res.statusCode == 404 ||
            res.statusCode == 405 ||
            res.statusCode == 400) {
          last = res;
          continue;
        }
        throw _error(res);
      }
    }
    throw _error(
        last ?? http.Response('Endpoint de registro no encontrado', 404));
  }

  // === Products ===
  Future<List<Product>> getProducts() async {
    // Tu API está devolviendo 401, entonces forzamos auth + nos aseguramos del token
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Products');
    final res = await http
        .get(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw _error(res);
  }

  Future<Product> createProduct(
      String name, String description, double price, int stock) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Products');
    final res = await http
        .post(url,
            headers: _headers(auth: true),
            body: jsonEncode({
              'name': name,
              'description': description,
              'price': price,
              'stock': stock
            }))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 201) {
      return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<Product> updateProduct(
      int id, String name, String description, double price, int stock) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Products/$id');
    final res = await http
        .put(url,
            headers: _headers(auth: true),
            body: jsonEncode({
              'name': name,
              'description': description,
              'price': price,
              'stock': stock
            }))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<void> deleteProduct(int id) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Products/$id');
    final res = await http
        .delete(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 204) throw _error(res);
  }

  // === Companies ===
  Future<Company?> myCompany() async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Companies/me');
    final res = await http
        .get(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return Company.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      return null;
    } else {
      throw _error(res);
    }
  }

  Future<Company> createCompany(String name) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Companies');
    final res = await http
        .post(url,
            headers: _headers(auth: true), body: jsonEncode({'name': name}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 201) {
      return Company.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<Company> updateCompany(String name) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Companies');
    final res = await http
        .put(url,
            headers: _headers(auth: true), body: jsonEncode({'name': name}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return Company.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<void> deleteCompany() async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Companies');
    final res = await http
        .delete(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 204) throw _error(res);
  }

  // === Orders / Cart ===
  Future<OrderModel> getCart() async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Orders/cart');
    final res = await http
        .get(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<OrderModel> addToCart(int productId, int quantity) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Orders/cart/add');
    final res = await http
        .post(url,
            headers: _headers(auth: true),
            body: jsonEncode({'productId': productId, 'quantity': quantity}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<OrderModel> removeFromCart(int orderItemId) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Orders/cart/remove/$orderItemId');
    final res = await http
        .delete(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<OrderModel> checkout() async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Orders/cart/checkout');
    final res = await http
        .post(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
    }
    throw _error(res);
  }

  Future<List<OrderModel>> myOrders() async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Orders/my');
    final res = await http
        .get(url, headers: _headers(auth: true))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw _error(res);
  }

  // === Reviews ===
  Future<List<Review>> reviewsForProduct(int productId) async {
    final url = Uri.parse(baseUrl + '/api/Reviews/product/$productId');
    final res = await http
        .get(url, headers: _headers()) // público
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw _error(res);
  }

  Future<Review> createReview(
      int productId, int rating, String? comment) async {
    await _ensureToken();
    final url = Uri.parse(baseUrl + '/api/Reviews');
    final res = await http
        .post(url,
            headers: _headers(auth: true),
            body: jsonEncode(
                {'productId': productId, 'rating': rating, 'comment': comment}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return Review.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _error(res);
  }
}
