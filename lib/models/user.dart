enum UserRole { customer, seller, admin }

enum SellerStatus { none, pending, approved, rejected }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final UserRole role;
  final SellerStatus sellerStatus;
  final String? shopName;
  final String? shopLocation;
  final String? shopDescription;
  final String? contactInfo;
  final bool deactivated;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.role = UserRole.customer,
    this.sellerStatus = SellerStatus.none,
    this.shopName,
    this.shopLocation,
    this.shopDescription,
    this.contactInfo,
    this.deactivated = false,
    required this.createdAt,
  });

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    UserRole? role,
    SellerStatus? sellerStatus,
    String? shopName,
    String? shopLocation,
    String? shopDescription,
    String? contactInfo,
    bool? deactivated,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      shopName: shopName ?? this.shopName,
      shopLocation: shopLocation ?? this.shopLocation,
      shopDescription: shopDescription ?? this.shopDescription,
      contactInfo: contactInfo ?? this.contactInfo,
      deactivated: deactivated ?? this.deactivated,
      createdAt: createdAt,
    );
  }
}
