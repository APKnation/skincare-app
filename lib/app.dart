import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/store.dart';
import 'features/admin/admin_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/profile_page.dart';
import 'features/cart/cart_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/customer/customer_dashboard_page.dart';
import 'features/orders/orders_page.dart';
import 'features/seller/seller_dashboard_page.dart';
import 'features/seller/seller_finance_page.dart';
import 'features/seller/seller_inventory_page.dart';
import 'features/seller/seller_orders_page.dart';

import 'models/order.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'widgets/advanced_bottom_nav.dart';
import 'widgets/app_logo.dart';
import 'widgets/customer_support_icon.dart';

class SuraYanguApp extends StatefulWidget {
  const SuraYanguApp({super.key});

  @override
  State<SuraYanguApp> createState() => _SuraYanguAppState();
}

class _SuraYanguAppState extends State<SuraYanguApp> {
  final store = Store(ApiClient());

  @override
  void initState() {
    super.initState();
    store.bootstrap();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sura Yangu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.isBootstrapped) {
            return const _SplashScreen();
          }
          return store.isLoggedIn
              ? RootShell(key: ValueKey(store.currentUser!.id), store: store)
              : LoginScreen(store: store);
        },
      ),
    );
  }
}

// ─── Splash Screen ─────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/launch_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFF1B5E40),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3E9270).withValues(alpha: 0.4),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const AppLogo(size: 84),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Sura Yangu',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tanzania\'s certified beauty & skincare marketplace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF3E9270),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Root Shell ─────────────────────────────────────────────────────────────────

class RootShell extends StatefulWidget {
  final Store store;

  const RootShell({super.key, required this.store});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;
  bool _isCustomerPreview = false;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _togglePreviewMode() {
    setState(() {
      _isCustomerPreview = !_isCustomerPreview;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.store.currentUser!;
    final isSeller =
        me.role == UserRole.seller || me.sellerStatus == SellerStatus.approved;
    final isAdmin = me.role == UserRole.admin;

    // Seller/Admin can preview the customer view to understand shopper experience
    final effectiveRole = _isCustomerPreview
        ? UserRole.customer
        : (isAdmin
            ? UserRole.admin
            : (isSeller ? UserRole.seller : UserRole.customer));

    final pages = _buildPages(effectiveRole);
    final navItems = _buildNavItems(effectiveRole);
    final accentColor = _roleAccentColor(effectiveRole);

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;

    return Scaffold(
      body: Column(
        children: [
          // Role Mode Banner — visible only for seller/admin, hides in preview
          if ((isAdmin || isSeller) && !_isCustomerPreview)
            RoleBannerBar(
              roleTitle: isAdmin ? 'Admin Console' : 'Seller Workspace',
              subtitle: isAdmin
                  ? 'Superuser platform operations'
                  : (me.shopName ?? 'Merchant Store'),
              icon: isAdmin ? Icons.shield : Icons.storefront,
              themeColor: isAdmin
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF0F5132),
              isCustomerPreview: _isCustomerPreview,
              onToggleMode: _togglePreviewMode,
            ),
          if (_isCustomerPreview)
            _PreviewBanner(onExit: _togglePreviewMode),

          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: pages,
            ),
          ),
        ],
      ),
      floatingActionButton:
          effectiveRole == UserRole.customer ? const CustomerSupportIcon() : null,
      bottomNavigationBar: AdvancedBottomNav(
        currentIndex: safeIndex,
        onTap: _onTabSelected,
        items: navItems,
        accentColor: accentColor,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PAGES — strict role isolation
  // ──────────────────────────────────────────────────────────────────────────

  List<Widget> _buildPages(UserRole role) {
    return switch (role) {
      // ── SELLER: manage their shop only, no buy/cart access ──────────────
      UserRole.seller => [
          SellerDashboardPage(store: widget.store),   // 0 Overview / KPIs
          SellerInventoryPage(store: widget.store),   // 1 My Products
          SellerOrdersPage(store: widget.store),      // 2 Customer Orders
          SellerFinancePage(store: widget.store),     // 3 Profit & Finance
          ProfilePage(store: widget.store),           // 4 Profile / Shop
        ],

      // ── ADMIN: platform operations only ─────────────────────────────────
      UserRole.admin => [
          AdminOverviewPage(store: widget.store),     // 0 Platform Console
          AdminSellersPage(store: widget.store),      // 1 Seller Management
          AdminModerationPage(store: widget.store),   // 2 Product Moderation
          AdminPlatformOpsPage(store: widget.store),  // 3 Users & Orders
          ProfilePage(store: widget.store),           // 4 Admin Profile
        ],

      // ── CUSTOMER: shop, track, pay, skin routine ─────────────────────────
      UserRole.customer => [
          CustomerDashboardPage(                      // 0 Personal Dashboard
            store: widget.store,
            onGoToShop: () => _onTabSelected(1),
            onGoToOrders: () => _onTabSelected(3),
            onGoToCart: () => _onTabSelected(2),
          ),
          CatalogPage(store: widget.store),           // 1 Shop / Browse
          CartPage(store: widget.store),              // 2 Cart & Checkout
          OrdersPage(store: widget.store),            // 3 My Orders
          ProfilePage(store: widget.store),           // 4 Profile / Skin
        ],
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  NAV ITEMS — matching pages above 1:1
  // ──────────────────────────────────────────────────────────────────────────

  List<NavItem> _buildNavItems(UserRole role) {
    final cartCount = widget.store.cartCount;

    return switch (role) {
      // ── SELLER nav ───────────────────────────────────────────────────────
      UserRole.seller => [
          const NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Overview',
          ),
          NavItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Products',
            badgeCount: widget.store.myProducts
                .where((p) => p.approval == ProductApproval.pending)
                .length,
            badgeColor: Colors.amber.shade900,
          ),
          NavItem(
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping,
            label: 'Orders',
            badgeCount: widget.store.salesOrders
                .where((o) =>
                    o.status == OrderStatus.placed ||
                    o.status == OrderStatus.confirmed)
                .length,
            badgeColor: Colors.blue.shade800,
          ),
          const NavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'Finance',
          ),
          const NavItem(
            icon: Icons.store_outlined,
            activeIcon: Icons.store,
            label: 'Shop Profile',
          ),
        ],

      // ── ADMIN nav ────────────────────────────────────────────────────────
      UserRole.admin => [
          const NavItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Console',
          ),
          NavItem(
            icon: Icons.verified_user_outlined,
            activeIcon: Icons.verified_user,
            label: 'Sellers',
            badgeCount: widget.store.sellers
                .where((s) => s.sellerStatus == SellerStatus.pending)
                .length,
            badgeColor: Colors.amber.shade900,
          ),
          NavItem(
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            label: 'Moderation',
            badgeCount: widget.store.pendingProducts.length,
            badgeColor: Colors.orange.shade800,
          ),
          const NavItem(
            icon: Icons.manage_accounts_outlined,
            activeIcon: Icons.manage_accounts,
            label: 'Operations',
          ),
          const NavItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            label: 'Admin',
          ),
        ],

      // ── CUSTOMER nav ─────────────────────────────────────────────────────
      UserRole.customer => [
          const NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          const NavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            label: 'Shop',
          ),
          NavItem(
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'Orders',
          ),
          const NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
    };
  }

  Color _roleAccentColor(UserRole role) {
    return switch (role) {
      UserRole.admin => const Color(0xFF1E3A8A),
      UserRole.seller => const Color(0xFF0F5132),
      UserRole.customer => const Color(0xFF1B5E40),
    };
  }
}

// ─── Customer-preview banner for sellers/admins ────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final VoidCallback onExit;

  const _PreviewBanner({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1565C0),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 12,
        right: 8,
        bottom: 6,
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Viewing as Customer — This is the shopper experience',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onExit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Exit Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
