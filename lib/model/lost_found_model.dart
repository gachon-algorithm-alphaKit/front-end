class LostFoundPost {
  final String id, itemName, description, location, contact, date;
  final bool isAnonymous;
  final String? imagePath; // 첨부 사진 경로 (없으면 null)
  const LostFoundPost({
    required this.id,
    required this.itemName,
    required this.description,
    required this.location,
    required this.contact,
    required this.date,
    this.isAnonymous = false,
    this.imagePath,
  });
  LostFoundPost copyWith({
    String? itemName,
    String? description,
    String? location,
    String? contact,
    bool? isAnonymous,
    String? imagePath,
    bool clearImage = false,
  }) => LostFoundPost(
    id: id,
    itemName: itemName ?? this.itemName,
    description: description ?? this.description,
    location: location ?? this.location,
    contact: contact ?? this.contact,
    date: date,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    imagePath: clearImage ? null : (imagePath ?? this.imagePath),
  );
}

// 분실물
class LostItem {
  final String id, itemName, description, location, foundDate, status;
  final int similarity; // 0~100
  const LostItem({
    required this.id,
    required this.itemName,
    required this.description,
    required this.location,
    required this.foundDate,
    required this.status,
    this.similarity = 100,
  });
}

// 장학금
