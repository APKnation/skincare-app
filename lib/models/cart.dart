class CartItem {
  final String productId;
  final int quantity;

  const CartItem({required this.productId, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(productId: productId, quantity: quantity ?? this.quantity);

  factory CartItem.fromJson(Map<String, Object?> j) => CartItem(
        productId: j['productId'] as String,
        quantity: j['quantity'] as int,
      );

  Map<String, Object?> toJson() =>
      {'productId': productId, 'quantity': quantity};
}
