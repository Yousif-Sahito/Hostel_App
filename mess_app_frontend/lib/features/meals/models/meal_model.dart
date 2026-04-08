class MealModel {
  final int? id;
  final int userId;
  final String? userName;
  final String mealDate;
  final bool breakfastTaken;
  final bool lunchTaken;
  final bool dinnerTaken;
  final int guestCount;

  MealModel({
    this.id,
    required this.userId,
    this.userName,
    required this.mealDate,
    required this.breakfastTaken,
    required this.lunchTaken,
    required this.dinnerTaken,
    required this.guestCount,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userName:
          json['user']?['fullName']?.toString() ?? json['userName']?.toString(),
      mealDate: json['mealDate']?.toString() ?? json['date']?.toString() ?? '',
      breakfastTaken: json['breakfastTaken'] ?? json['breakfast'] ?? false,
      lunchTaken: json['lunchTaken'] ?? json['lunch'] ?? false,
      dinnerTaken: json['dinnerTaken'] ?? json['dinner'] ?? false,
      guestCount: json['guestCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': mealDate,
      'breakfast': breakfastTaken,
      'lunch': lunchTaken,
      'dinner': dinnerTaken,
      'guestCount': guestCount,
    };
  }
}
