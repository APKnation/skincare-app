enum SkinType { dry, oily, combination, sensitive, normal }

enum SkinConcern {
  acne,
  darkSpots,
  aging,
  dryness,
  oiliness,
  redness,
  unevenTexture,
  dullness,
}

enum ProductCategory {
  facialOil,
  bodyOil,
  serum,
  moisturizer,
  cleanser,
  sunscreen,
  lipCare,
  hairCare,
  makeup,
  other,
}

enum Sensitivity { fragrance, essentialOils, alcohol, nuts, botanicals, preservatives }

extension SkinTypeName on SkinType {
  String get label => switch (this) {
        SkinType.dry => 'Dry',
        SkinType.oily => 'Oily',
        SkinType.combination => 'Combination',
        SkinType.sensitive => 'Sensitive',
        SkinType.normal => 'Normal',
      };
}

extension SkinConcernName on SkinConcern {
  String get label => switch (this) {
        SkinConcern.acne => 'Acne & breakouts',
        SkinConcern.darkSpots => 'Dark spots & hyperpigmentation',
        SkinConcern.aging => 'Fine lines & ageing',
        SkinConcern.dryness => 'Dryness & flaking',
        SkinConcern.oiliness => 'Excess oil & shine',
        SkinConcern.redness => 'Redness & irritation',
        SkinConcern.unevenTexture => 'Uneven texture',
        SkinConcern.dullness => 'Dullness & uneven tone',
      };
}

extension CategoryName on ProductCategory {
  String get label => switch (this) {
        ProductCategory.facialOil => 'Skincare oils',
        ProductCategory.bodyOil => 'Body oils',
        ProductCategory.serum => 'Serums',
        ProductCategory.moisturizer => 'Moisturizers',
        ProductCategory.cleanser => 'Cleansers',
        ProductCategory.sunscreen => 'Sun protection',
        ProductCategory.lipCare => 'Lip care',
        ProductCategory.hairCare => 'Hair care',
        ProductCategory.makeup => 'Cosmetics',
        ProductCategory.other => 'Other',
      };
}

extension SensitivityName on Sensitivity {
  String get label => switch (this) {
        Sensitivity.fragrance => 'Fragrance / perfume',
        Sensitivity.essentialOils => 'Essential oils',
        Sensitivity.alcohol => 'Drying alcohols',
        Sensitivity.nuts => 'Nut-derived ingredients',
        Sensitivity.botanicals => 'Botanical extracts',
        Sensitivity.preservatives => 'Preservatives',
      };
}
