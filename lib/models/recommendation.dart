import 'product.dart';

class Recommendation {
  final Product product;
  final int score;
  final List<String> reasons;
  final List<String> precautions;

  const Recommendation({
    required this.product,
    required this.score,
    required this.reasons,
    required this.precautions,
  });
}
