import 'enums.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final ProductCategory category;
  final String description;
  final int priceTZS;
  final String? imageUrl;
  final List<String> ingredients;
  final Set<SkinType> suitableSkinTypes;
  final Set<SkinConcern> targetsConcerns;
  final Set<Sensitivity> containsFlagged;
  final bool isComedogenic;
  final String usageInstructions;
  final List<String> sideEffects;
  final List<String> warnings;
  final int stock;
  final String sellerId;
  final String shopName;
  final String shopLocation;
  final ProductApproval approval;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.priceTZS,
    this.imageUrl,
    required this.ingredients,
    required this.suitableSkinTypes,
    required this.targetsConcerns,
    this.containsFlagged = const {},
    this.isComedogenic = false,
    required this.usageInstructions,
    this.sideEffects = const [],
    this.warnings = const [],
    required this.stock,
    required this.sellerId,
    required this.shopName,
    required this.shopLocation,
    this.approval = ProductApproval.pending,
    required this.createdAt,
  });

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? brand,
    ProductCategory? category,
    String? description,
    int? priceTZS,
    String? imageUrl,
    List<String>? ingredients,
    Set<SkinType>? suitableSkinTypes,
    Set<SkinConcern>? targetsConcerns,
    Set<Sensitivity>? containsFlagged,
    bool? isComedogenic,
    String? usageInstructions,
    List<String>? sideEffects,
    List<String>? warnings,
    int? stock,
    String? shopName,
    String? shopLocation,
    ProductApproval? approval,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      description: description ?? this.description,
      priceTZS: priceTZS ?? this.priceTZS,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      suitableSkinTypes: suitableSkinTypes ?? this.suitableSkinTypes,
      targetsConcerns: targetsConcerns ?? this.targetsConcerns,
      containsFlagged: containsFlagged ?? this.containsFlagged,
      isComedogenic: isComedogenic ?? this.isComedogenic,
      usageInstructions: usageInstructions ?? this.usageInstructions,
      sideEffects: sideEffects ?? this.sideEffects,
      warnings: warnings ?? this.warnings,
      stock: stock ?? this.stock,
      sellerId: sellerId ?? this.sellerId,
      shopName: shopName ?? this.shopName,
      shopLocation: shopLocation ?? this.shopLocation,
      approval: approval ?? this.approval,
      createdAt: createdAt,
    );
  }
}

enum ProductApproval { pending, approved, rejected }
