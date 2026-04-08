import 'package:flutter/material.dart';

import '../models/menu_item_model.dart';

class MenuDayCard extends StatelessWidget {
  final MenuItemModel item;

  const MenuDayCard({super.key, required this.item});

  Widget _mealRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.dayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            _mealRow('Breakfast', item.breakfast, Icons.free_breakfast),
            _mealRow('Lunch', item.lunch, Icons.lunch_dining),
            _mealRow('Dinner', item.dinner, Icons.dinner_dining),
          ],
        ),
      ),
    );
  }
}
