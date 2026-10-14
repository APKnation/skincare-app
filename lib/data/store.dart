import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/skin_profile.dart';
import '../models/user.dart';
import 'api_client.dart';

/// API-backed marketplace state. Getters read the local cache (so widgets
/// stay simple); every mutation goes to the backend first, then refreshes
/// the affected slice. All authoritative data lives in PostgreSQL.
class Store extends ChangeNotifier {
  Store(this.api);

  static const _tokenKey = 'sura_yangu_token';

  final ApiClient api;

  User? _me;
  List<Product> _catalog = const [];
  List<Product> _myProducts = const [];
  List<Product> _pendingProducts = const [];
  List<Product> _allProducts = const [];
  List<Order> _myOrders = const [];
  List<Order> _salesOrders = const [];
  List<Order> _allOrders = const [];
  List<User> _sellers = const [];
  List<User> _users = const [];
  List<CartItem> _cart = const [];
  SkinProfile? _profile;
  bool _bootstrapped = false;

  // ---- session ----

  bool get isLoggedIn => _me != null && !_me!.deactivated;
  User? get currentUser => _me;
  bool get isBootstrapped => _bootstrapped;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      api.token = token;
      try {
        final me = await api.request('GET', '/api/me');
        _me = User.fromJson(me);
        await refresh();
      } catch (_) {
        await _clearSession();
      }
    }
    _bootstrapped = true;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await api.request('POST', '/api/auth/login',
          body: {'email': email, 'password': password});
      return await _afterAuth(res['token'] as String);
    } on Exception catch (e) {
      return e is ApiException ? e.message : 'Login failed: $e';
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await api.request('POST', '/api/auth/register', body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });
      return await _afterAuth(res['token'] as String);
    } on Exception catch (e) {
      return e is ApiException ? e.message : 'Registration failed: $e';
    }
  }

  Future<String?> _afterAuth(String token) async {
    api.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final me = await api.request('GET', '/api/me');
    _me = User.fromJson(me);
    await refresh();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await api.attempt('POST', '/api/auth/logout');
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    api.token = null;
    _me = null;
    _cart = const [];
    _myOrders = const [];
    _salesOrders = const [];
    _myProducts = const [];
    _profile = null;
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final error = await api.attempt('PUT', '/api/me',
        body: {'name': name, 'email': email, 'phone': phone});
    if (error == null) await _refreshMe();
    return error;
  }

  Future<String?> changePassword(String current, String next) =>
      api.attempt('PUT', '/api/me/password',
          body: {'current': current, 'next': next});

  Future<void> _refreshMe() async {
    final me = await api.request('GET', '/api/me');
    _me = User.fromJson(me);
  }

  // ---- refresh slices ----

  Future<void> refresh() async {
    await Future.wait([
      refreshCatalog(),
      refreshCart(),
      refreshSkinProfile(),
      if (_me != null) refreshOrders(),
      if (_me != null &&
          (_me!.role == UserRole.seller || _me!.role == UserRole.admin))
        refreshMyProducts(),
      if (_me?.role == UserRole.seller) refreshSalesOrders(),
      if (_me?.role == UserRole.admin) refreshAdmin(),
    ]);
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    final rows = await api.request('GET', '/api/products');
    _catalog = [
      for (final p in asList(rows)) Product.fromJson(p),
    ];
    notifyListeners();
  }

  Future<void> refreshCart() async {
    if (_me == null) return;
    try {
      final rows = await api.request('GET', '/api/me/cart');
      _cart = [
        for (final c in (rows['items'] as List? ?? [])
            .cast<Map<String, Object?>>())
          CartItem.fromJson(c),
      ];
    } on Exception {
      _cart = const [];
    }
    notifyListeners();
  }

  Future<void> refreshSkinProfile() async {
    if (_me == null) return;
    try {
      final res = await api.request('GET', '/api/me/skin-profile');
      _profile = res.isEmpty || res['result'] == null
          ? null
          : SkinProfile.fromJson(_me!.id, res);
    } on Exception {
      _profile = null;
    }
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    final rows = await api.request('GET', '/api/orders');
    _myOrders = [
      for (final o in asList(rows)) Order.fromJson(o),
    ];
    notifyListeners();
  }

  Future<void> refreshSalesOrders() async {
    if (_me?.role != UserRole.seller) return;
    try {
      final rows = await api.request('GET', '/api/orders/sales');
      _salesOrders = [
        for (final o in asList(rows)) Order.fromJson(o),
      ];
    } on Exception {
      _salesOrders = const [];
    }
    notifyListeners();
  }

  Future<void> refreshMyProducts() async {
    final rows = await api.request('GET', '/api/products/mine');
    _myProducts = [
      for (final p in asList(rows)) Product.fromJson(p),
    ];
    notifyListeners();
  }

  Future<void> refreshAdmin() async {
    if (_me?.role != UserRole.admin) return;
    final sellers = await api.request('GET', '/api/admin/sellers');
    _sellers = [
      for (final u in asList(sellers)) User.fromJson(u),
    ];
    final users = await api.request('GET', '/api/admin/users');
    _users = [
      for (final u in asList(users)) User.fromJson(u),
    ];
    final orders = await api.request('GET', '/api/admin/orders');
    _allOrders = [
      for (final o in asList(orders)) Order.fromJson(o),
    ];
    final products = await api.request('GET', '/api/admin/products');
    _pendingProducts = [
      for (final p in asList(products)) Product.fromJson(p),
    ];
    final allProducts = await api.request('GET', '/api/admin/products/all');
    _allProducts = [
      for (final p in asList(allProducts)) Product.fromJson(p),
    ];
    notifyListeners();
  }

  static List<Map<String, Object?>> asList(Map<String, Object?> rows) =>
      rows['result'] is List
          ? (rows['result'] as List).cast<Map<String, Object?>>()
          : const [];

  // ---- seller onboarding ----

  Future<String?> applyForSeller({
    required String shopName,
    required String shopLocation,
    required String shopDescription,
    required String contactInfo,
  }) async {
    final error = await api.attempt('POST', '/api/me/seller-application', body: {
      'shopName': shopName,
      'shopLocation': shopLocation,
      'shopDescription': shopDescription,
      'contactInfo': contactInfo,
    });
    if (error == null) await _refreshMe();
    return error;
  }

  // ---- products ----

  /// Uploads image bytes to the backend. Returns the absolute image URL on
  /// success, or throws [ApiException]-style via api.postBytes on failure.
  Future<String> uploadProductImage(List<int> bytes,
      {String ext = 'jpg'}) async {
    final res = await api.postBytes('/api/upload', bytes, query: {'ext': ext});
    final path = res['path'] as String;
    return '${ApiClient.baseUrl}$path';
  }

  Future<String?> updateShopProfile({
    required String shopName,
    required String shopLocation,
    required String shopDescription,
    required String contactInfo,
  }) async {
    final error = await api.attempt('PUT', '/api/me/shop', body: {
      'shopName': shopName,
      'shopLocation': shopLocation,
      'shopDescription': shopDescription,
      'contactInfo': contactInfo,
    });
    if (error == null) await _refreshMe();
    return error;
  }

  List<Product> get approvedProducts => _catalog;
  List<Product> get myProducts => _myProducts;
  List<Product> get pendingProducts => _pendingProducts;

  Product? productById(String id) =>
      _catalog.where((p) => p.id == id).firstOrNull;

  List<String> get shopLocations => _catalog
      .map((p) => p.shopLocation)
      .toSet()
      .toList(growable: false)
    ..sort();

  Future<String?> addProduct(Product draft) async {
    final error =
        await api.attempt('POST', '/api/products', body: draft.toJson());
    if (error == null) {
      await Future.wait([refreshMyProducts(), refreshAdmin()]);
    }
    return error;
  }

  Future<String?> updateProduct(Product updated) async {
    final error = await api
        .attempt('PUT', '/api/products/${updated.id}', body: updated.toJson());
    if (error == null) {
      await Future.wait([
        refreshCatalog(),
        refreshMyProducts(),
        if (_me?.role == UserRole.admin) refreshAdmin(),
      ]);
    }
    return error;
  }

  Future<String?> deleteProduct(String productId) async {
    final error = await api.attempt('DELETE', '/api/products/$productId');
    if (error == null) {
      await Future.wait([
        refreshCatalog(),
        refreshMyProducts(),
        if (_me?.role == UserRole.admin) refreshAdmin(),
      ]);
    }
    return error;
  }

  // ---- admin ----

  List<User> get sellers => _sellers;
  List<User> get managedUsers => _users;
  List<Order> get allOrders => _allOrders;

  Future<String?> setSellerStatus(String userId, String status) async {
    final error = await api
        .attempt('PUT', '/api/admin/sellers/$userId/status', body: {
      'status': status,
    });
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> reviewProduct(String productId, String approval) async {
    final error = await api
        .attempt('PUT', '/api/admin/products/$productId/approval',
            body: {'approval': approval});
    if (error == null) {
      await Future.wait([refreshCatalog(), refreshAdmin()]);
    }
    return error;
  }

  Future<String?> setUserActive(String userId, bool active) async {
    final error = await api.attempt('PUT', '/api/admin/users/$userId/active',
        body: {'active': active});
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> advanceOrder(String orderId, String status, String note) async {
    final error = await api.attempt('PUT', '/api/admin/orders/$orderId/status',
        body: {'status': status, 'note': note});
    if (error == null) await refreshAdmin();
    return error;
  }

  List<Product> get allProducts => _allProducts;

  Future<String?> adminCreateUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final error = await api.attempt('POST', '/api/admin/users', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> adminUpdateUser(
    String userId, {
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    final error = await api.attempt('PUT', '/api/admin/users/$userId', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    });
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> adminDeleteUser(String userId) async {
    final error = await api.attempt('DELETE', '/api/admin/users/$userId');
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> adminDeleteOrder(String orderId) async {
    final error = await api.attempt('DELETE', '/api/admin/orders/$orderId');
    if (error == null) await refreshAdmin();
    return error;
  }

  Future<String?> deleteMyAccount() async {
    final error = await api.attempt('DELETE', '/api/me');
    if (error == null) {
      await _clearSession();
      _catalog = const [];
      _allProducts = const [];
      _pendingProducts = const [];
      _sellers = const [];
      _users = const [];
      _allOrders = const [];
      notifyListeners();
    }
    return error;
  }

  // ---- skin profile ----

  SkinProfile? get skinProfile => _profile;

  Future<String?> saveSkinProfile(SkinProfile profile) async {
    final error =
        await api.attempt('PUT', '/api/me/skin-profile', body: profile.toJson());
    if (error == null) _profile = profile;
    notifyListeners();
    return error;
  }

  // ---- cart ----

  List<CartItem> get cart => _cart;
  int get cartCount => _cart.fold(0, (sum, i) => sum + i.quantity);

  Product? productInCart(CartItem item) => productById(item.productId);

  int get cartSubtotal => _cart.fold(
        0,
        (sum, item) {
          final p = productById(item.productId);
          return sum + (p == null ? 0 : p.priceTZS * item.quantity);
        },
      );

  Future<String?> addToCart(String productId, {int quantity = 1}) async {
    final error = await api.attempt('POST', '/api/me/cart',
        body: {'productId': productId, 'quantity': quantity});
    if (error == null) await refreshCart();
    return error;
  }

  Future<String?> setCartQuantity(String productId, int quantity) async {
    final error = await api.attempt('PUT', '/api/me/cart/$productId',
        body: {'quantity': quantity});
    if (error == null) await refreshCart();
    return error;
  }

  Future<String?> removeFromCart(String productId) =>
      setCartQuantity(productId, 0);

  int deliveryFeeFor(String city) =>
      city.trim().toLowerCase() == 'dar es salaam' ? 3000 : 5000;

  // ---- orders ----

  List<Order> get myOrders => _myOrders;
  List<Order> get salesOrders => _salesOrders;

  Order? orderById(String id) =>
      _myOrders.where((o) => o.id == id).firstOrNull ??
      _salesOrders.where((o) => o.id == id).firstOrNull ??
      _allOrders.where((o) => o.id == id).firstOrNull;

  Future<String?> placeOrder({
    required String recipientName,
    required String recipientPhone,
    required String address,
    required String city,
    required String deliveryNotes,
    required PaymentMethod paymentMethod,
  }) async {
    String? orderId;
    try {
      final res = await api.request('POST', '/api/orders', body: {
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'address': address,
        'city': city,
        'deliveryNotes': deliveryNotes,
        'paymentMethod': paymentMethod.name,
      });
      orderId = res['orderId'] as String?;
    } on ApiException catch (e) {
      return e.message;
    } on Exception {
      return 'Could not place the order.';
    }
    await Future.wait([refreshOrders(), refreshCatalog()]);
    return orderId == null ? 'Could not place the order.' : null;
  }

  /// Starts a mobile-money prompt. Returns provider prompt data or null.
  Future<Map<String, Object?>?> payStart(String orderId) async {
    try {
      final res = await api.request('POST', '/api/orders/$orderId/pay/start');
      return res;
    } on ApiException {
      return null;
    } on Exception {
      return null;
    }
  }

  /// Server verifies the transaction; the client never decides "paid".
  Future<({bool success, String message})> payConfirm(
      String orderId, String pin) async {
    try {
      final res = await api.request('POST', '/api/orders/$orderId/pay/confirm',
          body: {'pin': pin});
      await refreshOrders();
      return (
        success: res['success'] as bool? ?? false,
        message: res['message'] as String? ?? 'Payment verified.',
      );
    } on Exception {
      return (success: false, message: 'Payment could not be verified.');
    }
  }

  Future<String?> cancelOrder(String orderId) async {
    final error = await api.attempt('PUT', '/api/orders/$orderId/cancel');
    if (error == null) await refreshOrders();
    return error;
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}
