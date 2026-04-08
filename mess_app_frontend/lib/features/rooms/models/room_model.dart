class RoomModel {
  final int id;
  final String roomNumber;
  final int capacity;
  final int occupiedCount;
  final String status;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.occupiedCount,
    required this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? 0,
      roomNumber: json['roomNumber']?.toString() ?? '',
      capacity: json['capacity'] ?? 0,
      occupiedCount: json['occupiedCount'] ?? 0,
      status: json['status'] ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomNumber': roomNumber,
      'capacity': capacity,
      'occupiedCount': occupiedCount,
      'status': status,
    };
  }
}
