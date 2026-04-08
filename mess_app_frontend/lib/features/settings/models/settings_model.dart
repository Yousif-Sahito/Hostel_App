class SettingsModel {
  final int? id;
  final double mealRate;
  final double helperCharge;
  final double breakfastPrice;
  final double lunchPrice;
  final double dinnerPrice;
  final double guestMealPrice;
  final String currency;
  final String hostelName;
  final bool messOffEnabled;
  final String messStatus;
  final int cutoffDay;
  final String? updatedAt;

  const SettingsModel({
    this.id,
    required this.mealRate,
    required this.helperCharge,
    required this.breakfastPrice,
    required this.lunchPrice,
    required this.dinnerPrice,
    required this.guestMealPrice,
    required this.currency,
    required this.hostelName,
    required this.messOffEnabled,
    required this.messStatus,
    required this.cutoffDay,
    this.updatedAt,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'],
      mealRate: (json['mealRate'] ?? 0).toDouble(),
      helperCharge: (json['helperCharge'] ?? 0).toDouble(),
      breakfastPrice: (json['breakfastPrice'] ?? json['mealRate'] ?? 0).toDouble(),
      lunchPrice: (json['lunchPrice'] ?? json['mealRate'] ?? 0).toDouble(),
      dinnerPrice: (json['dinnerPrice'] ?? json['mealRate'] ?? 0).toDouble(),
      guestMealPrice: (json['guestMealPrice'] ?? json['mealRate'] ?? 0).toDouble(),
      currency: (json['currency'] ?? 'PKR').toString(),
      hostelName: (json['hostelName'] ?? 'Hostel Mess').toString(),
      messOffEnabled: json['messOffEnabled'] ?? true,
      messStatus: (json['messStatus'] ?? 'ON').toString(),
      cutoffDay: json['cutoffDay'] ?? 25,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealRate': mealRate,
      'helperCharge': helperCharge,
      'breakfastPrice': breakfastPrice,
      'lunchPrice': lunchPrice,
      'dinnerPrice': dinnerPrice,
      'guestMealPrice': guestMealPrice,
      'currency': currency,
      'hostelName': hostelName,
      'messOffEnabled': messOffEnabled,
      'messStatus': messStatus,
      'cutoffDay': cutoffDay,
    };
  }

  SettingsModel copyWith({
    int? id,
    double? mealRate,
    double? helperCharge,
    double? breakfastPrice,
    double? lunchPrice,
    double? dinnerPrice,
    double? guestMealPrice,
    String? currency,
    String? hostelName,
    bool? messOffEnabled,
    String? messStatus,
    int? cutoffDay,
    String? updatedAt,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      mealRate: mealRate ?? this.mealRate,
      helperCharge: helperCharge ?? this.helperCharge,
      breakfastPrice: breakfastPrice ?? this.breakfastPrice,
      lunchPrice: lunchPrice ?? this.lunchPrice,
      dinnerPrice: dinnerPrice ?? this.dinnerPrice,
      guestMealPrice: guestMealPrice ?? this.guestMealPrice,
      currency: currency ?? this.currency,
      hostelName: hostelName ?? this.hostelName,
      messOffEnabled: messOffEnabled ?? this.messOffEnabled,
      messStatus: messStatus ?? this.messStatus,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
