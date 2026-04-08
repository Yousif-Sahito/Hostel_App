class MenuItemModel {
  final int? id;
  final String dayName;
  final String breakfast;
  final String lunch;
  final String dinner;

  MenuItemModel({
    this.id,
    required this.dayName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      dayName: json['dayName']?.toString() ?? '',
      breakfast: json['breakfast']?.toString() ?? '',
      lunch: json['lunch']?.toString() ?? '',
      dinner: json['dinner']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayName': dayName,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}
