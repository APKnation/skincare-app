class CartItem {
  final String productId;
  final int quantity;

  const CartItem({required this.productId, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(productId: productId, quantity: quantity ?? this.quantity);
}
