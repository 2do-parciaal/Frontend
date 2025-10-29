class UserSession {
  final String token;
  final String role; // 'Cliente' | 'Empresa' | 'Admin'
  UserSession({required this.token, required this.role});
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int companyId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.companyId,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        stock: j['stock'] as int? ?? 0,
        companyId: j['companyId'] as int? ?? 0,
      );
}

class Company {
  final int id;
  final String name;
  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> j) =>
      Company(id: j['id'] as int, name: (j['name'] ?? '') as String);
}

class Review {
  final int id;
  final int userId;
  final int productId;
  final int rating;
  final String? comment;
  Review({required this.id, required this.userId, required this.productId, required this.rating, this.comment});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        userId: j['userId'] as int? ?? 0,
        productId: j['productId'] as int? ?? 0,
        rating: j['rating'] as int? ?? 0,
        comment: j['comment'] as String?,
      );
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as int,
        productId: j['productId'] as int? ?? 0,
        productName: j['product']?['name'] as String? ?? j['productName'] as String? ?? '',
        quantity: j['quantity'] as int? ?? 0,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? (j['price'] as num?)?.toDouble() ?? 0.0,
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0.0,
      );
}

class OrderModel {
  final int id;
  final bool isPaid;
  final List<OrderItem> items;
  final double total;
  OrderModel({required this.id, required this.isPaid, required this.items, required this.total});

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (j['total'] as num?)?.toDouble()
        ?? items.fold<double>(0.0, (p, e) => p + e.subtotal);
    return OrderModel(
      id: j['id'] as int,
      isPaid: j['isPaid'] as bool? ?? false,
      items: items,
      total: total,
    );
  }
}
