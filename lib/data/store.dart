import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/skin_profile.dart';
import '../models/user.dart';
import 'seed_data.dart';

/// In-memory marketplace store. This plays the role of the backend server in
/// the prototype: all authoritative state (users, products, orders) lives
/// here, password verification and stock checks happen in one place, and the
/// API surface maps 1:1 to future HTTP endpoints.
class Store extends ChangeNotifier {
  static Store seeded() => Store._seed();

  Store._seed() {

    _users.addAll(
      seedUsers.map((u) => u.copyWith(passwordHash: _hash(u.passwordHash))),
    );
    _products.addAll(seedProducts);
    _nextProductIndex = _products.length + 1;
    _nextOrderIndex = 100;
  }

  final _users = <User>[];
  final _products = <Product>[];
  final _orders = <Order>[];
  final _profiles = <String, SkinProfile>{};
  final _carts = <String, List<CartItem>>{};
  late int _nextProductIndex;
  late int _nextOrderIndex;
  String? _currentUserId;

  static String _hash(String input) {
    // Demo-only stand-in for server-side bcrypt/argon2. Never ship as-is.
    var h = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return 'h${h.toRadixString(16)}';
  }

  // ---- session ----

  String? get currentUserId => _currentUserId;
  User? get currentUser => byId(_currentUserId);

  User? byId(String? id) =>
      id == null ? null : _users.where((u) => u.id == id).firstOrNull;

  bool get isLoggedIn => currentUser != null && !currentUser!.deactivated;

  String? login(String email, String password) {
    final user = _users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    ).firstOrNull;
    if (user == null || user.passwordHash != _hash(password)) {
      return 'Wrong email or password.';
    }
    if (user.deactivated) {
      return 'This account has been deactivated. Contact support.';
    }
    _currentUserId = user.id;
    notifyListeners();
    return null;
  }

  String? register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    if (_users.any(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    )) {
      return 'An account with this email already exists.';
    }
    final user = User(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _currentUserId = user.id;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }

  String? updateProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    final me = currentUser;
    if (me == null) return 'Not logged in.';
    if (_users.any((u) =>
        u.id != me.id && u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'That email belongs to another account.';
    }
    final index = _users.indexWhere((u) => u.id == me.id);
    _users[index] = _users[index].copyWith(name: name.trim(), email: email.trim(), phone: phone.trim());
    notifyListeners();
    return null;
  }

  String? changePassword(String current, String next) {
    final me = currentUser;
    if (me == null) return 'Not logged in.';
    if (me.passwordHash != _hash(current)) return 'Current password is wrong.';
    if (next.length < 6) return 'New password must be at least 6 characters.';
    final index = _users.indexWhere((u) => u.id == me.id);
    _users[index] = _users[index].copyWith(passwordHash: _hash(next));
    notifyListeners();
    return null;
  }

  // ---- seller onboarding ----

  String? applyForSeller({
    required String shopName,
    required String shopLocation,
    required String shopDescription,
    required String contactInfo,
  }) {
    final me = currentUser;
    if (me == null) return 'Not logged in.';
    if (me.sellerStatus == SellerStatus.approved) return null;
    if (me.sellerStatus == SellerStatus.pending) {
      return 'Your seller application is already under review.';
    }
    final index = _users.indexWhere((u) => u.id == me.id);
    _users[index] = _users[index].copyWith(
      sellerStatus: SellerStatus.pending,
      shopName: shopName.trim(),
      shopLocation: shopLocation.trim(),
      shopDescription: shopDescription.trim(),
      contactInfo: contactInfo.trim(),
    );
    notifyListeners();
    return null;
  }

  // ---- products / catalog ----

  List<Product> get approvedProducts => _products
      .where((p) => p.approval == ProductApproval.approved)
      .toList(growable: false);

  List<Product> get allProducts => List.unmodifiable(_products);

  List<Product> productsBySeller(String sellerId) =>
      _products.where((p) => p.sellerId == sellerId).toList();

  List<Product> get pendingProducts => _products
      .where((p) => p.approval == ProductApproval.pending)
      .toList(growable: false);

  Product? productById(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

  List<String> get shopLocations => _products
      .map((p) => p.shopLocation)
      .toSet()
      .toList(growable: false)
    ..sort();

  String? addProduct(Product draft) {
    final me = currentUser;
    if (me == null ||
        (me.role != UserRole.seller && me.role != UserRole.admin)) {
      return 'Only approved sellers can add products.';
    }
    if (me.role == UserRole.seller && me.sellerStatus != SellerStatus.approved) {
      return 'Your seller account is not approved yet.';
    }
    _products.add(
      draft.copyWith(
        id: 'p-${_nextProductIndex++}',
        sellerId: me.id,
        shopName: me.shopName ?? draft.shopName,
        shopLocation: me.shopLocation ?? draft.shopLocation,
      ),
    );
    notifyListeners();
    return null;
  }

  String? updateProduct(Product updated) {
    final me = currentUser;
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index == -1) return 'Product not found.';
    if (me == null) return 'Not logged in.';
    if (me.role != UserRole.admin && _products[index].sellerId != me.id) {
      return 'You can only edit your own products.';
    }
    _products[index] = updated;
    notifyListeners();
    return null;
  }

  String? deleteProduct(String productId) {
    final me = currentUser;
    if (me == null) return 'Not logged in.';
    final product = productById(productId);
    if (product == null) return 'Product not found.';
    if (me.role != UserRole.admin && product.sellerId != me.id) {
      return 'You can only delete your own products.';
    }
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
    return null;
  }

  // ---- admin ----

  List<User> get sellers => _users
      .where((u) =>
          u.role == UserRole.seller || u.sellerStatus != SellerStatus.none)
      .toList(growable: false);

  List<User> get customers =>
      _users.where((u) => u.role == UserRole.customer).toList(growable: false);

  List<Order> get allOrders => List.unmodifiable(_orders);

  String? setSellerStatus(String userId, SellerStatus status) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return 'Seller not found.';
    _users[index] = _users[index].copyWith(
      sellerStatus: status,
      role: status == SellerStatus.approved ? UserRole.seller : _users[index].role,
    );
    notifyListeners();
    return null;
  }

  String? reviewProduct(String productId, ProductApproval approval) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return 'Product not found.';
    _products[index] = _products[index].copyWith(approval: approval);
    notifyListeners();
    return null;
  }

  String? setUserActive(String userId, bool active) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return 'User not found.';
    if (_users[index].role == UserRole.admin) return 'Admins cannot be deactivated.';
    _users[index] = _users[index].copyWith(deactivated: !active);
    if (!active && _currentUserId == userId) _currentUserId = null;
    notifyListeners();
    return null;
  }

  // ---- skin profile ----

  SkinProfile? profileFor(String userId) => _profiles[userId];

  void saveSkinProfile(SkinProfile profile) {
    _profiles[profile.userId] = profile;
    notifyListeners();
  }

  // ---- cart ----

  List<CartItem> get cart =>
      _currentUserId == null ? const [] : _carts[_currentUserId] ?? const [];

  int get cartCount => cart.fold(0, (sum, i) => sum + i.quantity);

  Product? productInCart(CartItem item) => productById(item.productId);

  String? addToCart(String productId, {int quantity = 1}) {
    final me = _currentUserId;
    if (me == null) return 'Please log in first.';
    final product = productById(productId);
    if (product == null || product.approval != ProductApproval.approved) {
      return 'Product unavailable.';
    }
    final list = _carts.putIfAbsent(me, () => []);
    final index = list.indexWhere((i) => i.productId == productId);
    final newQty = (index == -1 ? 0 : list[index].quantity) + quantity;
    if (newQty > product.stock) {
      return 'Only ${product.stock} left in stock.';
    }
    if (index == -1) {
      list.add(CartItem(productId: productId, quantity: quantity));
    } else {
      list[index] = list[index].copyWith(quantity: newQty);
    }
    notifyListeners();
    return null;
  }

  void setCartQuantity(String productId, int quantity) {
    final me = _currentUserId;
    if (me == null) return;
    final list = _carts[me] ??= [];
    final index = list.indexWhere((i) => i.productId == productId);
    if (index == -1) return;
    final product = productById(productId)!;
    final clamped = quantity.clamp(0, product.stock);
    if (clamped == 0) {
      list.removeAt(index);
    } else {
      list[index] = list[index].copyWith(quantity: clamped);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) =>
      setCartQuantity(productId, 0);

  void clearCart() {
    if (_currentUserId != null) {
      _carts[_currentUserId!] = [];
      notifyListeners();
    }
  }

  int get cartSubtotal => cart.fold(
        0,
        (sum, item) {
          final p = productById(item.productId);
          return sum + (p == null ? 0 : p.priceTZS * item.quantity);
        },
      );

  int deliveryFeeFor(String city) =>
      city.trim().toLowerCase() == 'dar es salaam' ? 3000 : 5000;

  // ---- orders ----

  List<Order> ordersFor(String userId) =>
      _orders.where((o) => o.userId == userId).toList(growable: false);

  Order? orderById(String id) => _orders.where((o) => o.id == id).firstOrNull;

  String? placeOrder({
    required String recipientName,
    required String recipientPhone,
    required String address,
    required String city,
    required String deliveryNotes,
    required PaymentMethod paymentMethod,
  }) {
    final me = _currentUserId;
    if (me == null) return 'Please log in first.';
    if (cart.isEmpty) return 'Your cart is empty.';
    if (recipientName.trim().isEmpty || recipientPhone.trim().length < 9) {
      return 'Enter a valid recipient name and phone number.';
    }
    if (address.trim().isEmpty || city.trim().isEmpty) {
      return 'Enter a complete delivery address.';
    }
    for (final item in cart) {
      final p = productById(item.productId);
      if (p == null || p.approval != ProductApproval.approved) {
        return 'A product in your cart is no longer available.';
      }
      if (item.quantity > p.stock) {
        return 'Stock changed for ${p.name}. Adjust your cart.';
      }
    }
    final lines = cart.map((item) {
      final p = productById(item.productId)!;
      return OrderLine(
        productId: p.id,
        name: p.name,
        unitPriceTZS: p.priceTZS,
        quantity: item.quantity,
      );
    }).toList();
    final subtotal = lines.fold(0, (sum, l) => sum + l.total);
    final fee = deliveryFeeFor(city);
    final now = DateTime.now();
    final order = Order(
      id: 'SY${_nextOrderIndex++}',
      userId: me,
      lines: lines,
      subtotalTZS: subtotal,
      deliveryFeeTZS: fee,
      totalTZS: subtotal + fee,
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      address: address.trim(),
      city: city.trim(),
      deliveryNotes: deliveryNotes.trim(),
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == PaymentMethod.cashOnDelivery
          ? PaymentStatus.unpaid
          : PaymentStatus.unpaid,
      status: OrderStatus.placed,
      timeline: [
        OrderEvent(status: OrderStatus.placed, note: 'Order received', at: now),
      ],
    );
    _orders.insert(0, order);
    for (final item in cart) {
      final index = _products.indexWhere((p) => p.id == item.productId);
      _products[index] = _products[index]
          .copyWith(stock: (_products[index].stock - item.quantity).clamp(0, 1 << 30));
    }
    clearCart();
    notifyListeners();
    return null;
  }

  /// Server-side payment verification result hook.
  void markOrderPaid(String orderId, String paymentRef) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final now = DateTime.now();
    _orders[index] = _orders[index].copyWith(
      paymentStatus: PaymentStatus.paid,
      paymentRef: paymentRef,
      status: OrderStatus.confirmed,
      timeline: [
        ..._orders[index].timeline,
        OrderEvent(
          status: OrderStatus.confirmed,
          note: 'Payment verified by provider ($paymentRef)',
          at: now,
        ),
      ],
    );
    notifyListeners();
  }

  void markOrderPaymentFailed(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    _orders[index] = _orders[index].copyWith(paymentStatus: PaymentStatus.failed);
    notifyListeners();
  }

  String? advanceOrder(String orderId, OrderStatus status, String note) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return 'Order not found.';
    _orders[index] = _orders[index].copyWith(
      status: status,
      timeline: [
        ..._orders[index].timeline,
        OrderEvent(status: status, note: note, at: DateTime.now()),
      ],
    );
    notifyListeners();
    return null;
  }

  String? cancelOrder(String orderId) {
    final order = orderById(orderId);
    if (order == null) return 'Order not found.';
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return 'This order can no longer be cancelled.';
    }
    return advanceOrder(orderId, OrderStatus.cancelled, 'Cancelled by customer');
  }
}
