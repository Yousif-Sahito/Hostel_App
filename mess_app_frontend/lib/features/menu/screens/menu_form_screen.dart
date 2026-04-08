import 'package:flutter/material.dart';

import '../models/menu_item_model.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuFormScreen extends StatefulWidget {
  final MenuModel? menu;

  const MenuFormScreen({super.key, this.menu});

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController weekStartDateController;

  final List<String> days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final Map<String, TextEditingController> breakfastControllers;
  late final Map<String, TextEditingController> lunchControllers;
  late final Map<String, TextEditingController> dinnerControllers;

  bool isLoading = false;

  bool get isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();

    String getCurrentWeekMonday() {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return '${monday.year.toString().padLeft(4, '0')}-'
          '${monday.month.toString().padLeft(2, '0')}-'
          '${monday.day.toString().padLeft(2, '0')}';
    }

    weekStartDateController = TextEditingController(
      text: (widget.menu?.weekStartDate != null)
          ? widget.menu!.weekStartDate!.split('T')[0]
          : getCurrentWeekMonday(),
    );

    breakfastControllers = {};
    lunchControllers = {};
    dinnerControllers = {};

    for (final day in days) {
      final existing = widget.menu?.items
          .where((e) => e.dayName == day)
          .toList();

      breakfastControllers[day] = TextEditingController(
        text: existing != null && existing.isNotEmpty
            ? existing.first.breakfast
            : '',
      );
      lunchControllers[day] = TextEditingController(
        text: existing != null && existing.isNotEmpty
            ? existing.first.lunch
            : '',
      );
      dinnerControllers[day] = TextEditingController(
        text: existing != null && existing.isNotEmpty
            ? existing.first.dinner
            : '',
      );
    }
  }

  @override
  void dispose() {
    weekStartDateController.dispose();

    for (final controller in breakfastControllers.values) {
      controller.dispose();
    }
    for (final controller in lunchControllers.values) {
      controller.dispose();
    }
    for (final controller in dinnerControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget _mealField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final items = days.map((day) {
        return MenuItemModel(
          dayName: day,
          breakfast: breakfastControllers[day]!.text.trim(),
          lunch: lunchControllers[day]!.text.trim(),
          dinner: dinnerControllers[day]!.text.trim(),
        ).toJson();
      }).toList();

      if (isEdit) {
        await MenuService.updateMenu(
          id: widget.menu!.id!,
          weekStartDate: weekStartDateController.text.trim(),
          items: items,
        );
      } else {
        await MenuService.createMenu(
          weekStartDate: weekStartDateController.text.trim(),
          items: items,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Weekly menu updated successfully'
                : 'Weekly menu created successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _daySection(String day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _mealField('Breakfast', breakfastControllers[day]!),
            _mealField('Lunch', lunchControllers[day]!),
            _mealField('Dinner', dinnerControllers[day]!),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Weekly Menu' : 'Create Weekly Menu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: weekStartDateController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Week Start Date is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Week Start Date',
                      hintText: 'yyyy-mm-dd',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...days.map(_daySection),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEdit ? 'Update Menu' : 'Create Menu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
