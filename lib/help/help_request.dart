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
  final String? creatorUid;

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
    this.creatorUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'locationName': locationName,
      'lat': lat,
      'lng': lng,
      'isUrgent': isUrgent,
      'creatorUid': creatorUid,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static HelpRequest fromMap(String id, Map<String, dynamic> data, String? currentUid) {
    final createdAt = data['createdAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
        : DateTime.now();
    final creatorUid = data['creatorUid'] as String?;
    return HelpRequest(
      id: id,
      category: (data['category'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      locationName: (data['locationName'] ?? '') as String,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      isUrgent: (data['isUrgent'] ?? false) as bool,
      isMine: currentUid != null && creatorUid == currentUid,
      createdAt: createdAt,
      creatorUid: creatorUid,
    );
  }
}

