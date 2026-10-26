/// Display data required by the legacy plant detail screen.
/// This is not a disease classification model or inference result.
class Plants {
  final String name;
  final String category;
  final String description;
  final String imagePath;
  final double price;

  const Plants({
    required this.name,
    required this.category,
    required this.description,
    required this.imagePath,
    required this.price,
  });
}
