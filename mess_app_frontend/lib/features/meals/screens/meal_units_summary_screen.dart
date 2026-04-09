import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../members/models/member_model.dart';
import '../../members/services/member_service.dart';
import '../services/meal_service.dart';

class MealUnitsSummaryScreen extends StatefulWidget {
  const MealUnitsSummaryScreen({super.key});

  @override
  State<MealUnitsSummaryScreen> createState() => _MealUnitsSummaryScreenState();
}

class _MealUnitsSummaryScreenState extends State<MealUnitsSummaryScreen> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  bool isLoading = true;
  List<Map<String, dynamic>> summaryData = [];

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  String get formattedStartDate => DateFormat('yyyy-MM-dd').format(startDate);
  String get formattedEndDate => DateFormat('yyyy-MM-dd').format(endDate);

  Future<void> _fetchSummary() async {
    setState(() => isLoading = true);
    try {
      final members = await MemberService.getMembers();
      final allMeals = await MealService.getMeals();

      // Filter meals within date range
      final mealsInRange = allMeals.where((meal) {
        final mealDate = DateTime.parse(meal.mealDate);
        return mealDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               mealDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final activeMembers = members.where((m) => m.role.toUpperCase() == 'MEMBER').toList();

      final summary = <Map<String, dynamic>>[];

      for (var member in activeMembers) {
        final memberMeals = mealsInRange.where((m) => m.userId == member.id).toList();

        int totalBreakfast = 0;
        int totalLunch = 0;
        int totalDinner = 0;
        int totalGuests = 0;

        for (var meal in memberMeals) {
          if (meal.breakfastTaken) totalBreakfast++;
          if (meal.lunchTaken) totalLunch++;
          if (meal.dinnerTaken) totalDinner++;
          totalGuests += meal.guestCount;
        }

        int totalUnits = totalBreakfast + totalLunch + totalDinner + totalGuests;

        summary.add({
          'member': member,
          'breakfast': totalBreakfast,
          'lunch': totalLunch,
          'dinner': totalDinner,
          'guests': totalGuests,
          'totalUnits': totalUnits,
        });
      }

      // Sort by total units descending
      summary.sort((a, b) => b['totalUnits'].compareTo(a['totalUnits']));

      setState(() {
        summaryData = summary;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Units Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSummary,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : summaryData.isEmpty
                ? const Center(child: Text('No data found'))
                : ListView.builder(
                    itemCount: summaryData.length,
                    itemBuilder: (context, index) {
                      final data = summaryData[index];
                      final member = data['member'] as MemberModel;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _unitChip('Breakfast', data['breakfast'], Colors.orange),
                                  _unitChip('Lunch', data['lunch'], Colors.green),
                                  _unitChip('Dinner', data['dinner'], Colors.blue),
                                  _unitChip('Guests', data['guests'], Colors.purple),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Chip(
                                  label: Text(
                                    'Total Units: ${data['totalUnits']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _unitChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Chip(
          label: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: color,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}