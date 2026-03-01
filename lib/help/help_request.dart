class HelpRequest {
  final String id;
  final String category;
  final String title;
  final String description;
  final String locationName;
  final double? lat;
  final double? lng;
  final bool isUrgent;
  final bool isMine;
  final DateTime createdAt;

  const HelpRequest({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.isUrgent,
    required this.isMine,
    required this.createdAt,
  });
}

