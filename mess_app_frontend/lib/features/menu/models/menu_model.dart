import 'menu_item_model.dart';

class MenuModel {
  final int? id;
  final String? weekStartDate;
  final List<MenuItemModel> items;

  MenuModel({this.id, this.weekStartDate, required this.items});

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['weeklyMenuItems'] ?? [];

    return MenuModel(
      id: json['id'],
      weekStartDate: json['weekStartDate']?.toString(),
      items: (rawItems as List)
          .map((item) => MenuItemModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
