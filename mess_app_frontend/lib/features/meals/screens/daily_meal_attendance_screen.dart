import 'package:flutter/material.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../members/models/member_model.dart';
import '../../members/services/member_service.dart';
import '../services/meal_service.dart';

class MealAttendanceRow {
  final MemberModel member;
  bool breakfast;
  bool lunch;
  bool dinner;
  int guestCount;

  MealAttendanceRow({
    required this.member,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.guestCount,
  });
}

class DailyMealAttendanceScreen extends StatefulWidget {
  const DailyMealAttendanceScreen({super.key});

  @override
  State<DailyMealAttendanceScreen> createState() => _DailyMealAttendanceScreenState();
}

class _DailyMealAttendanceScreenState extends State<DailyMealAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;
  List<MealAttendanceRow> rows = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String get formattedDate {
    return '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final members = await MemberService.getMembers();
      final allMeals = await MealService.getMeals();

      // Find meals specifically for selectedDate
      final mealsOnDate = allMeals.where((m) => m.mealDate.startsWith(formattedDate)).toList();

      final activeMembers = members.where((m) => m.role.toUpperCase() == 'MEMBER').toList();

      final newRows = <MealAttendanceRow>[];

      for (var member in activeMembers) {
        // use iterable.where().firstOrNull pattern manually compatible with dart 2.x
        final matchingMeals = mealsOnDate.where((m) => m.userId == member.id);
        final existingMeal = matchingMeals.isNotEmpty ? matchingMeals.first : null;
        
        final isMessOff = member.status == 'MESS OFF';
        final isMealDisabled = !member.mealUnitEnabled;
        final shouldDisable = isMessOff || isMealDisabled;

        newRows.add(MealAttendanceRow(
          member: member,
          // Mess-off members: always false (no units), shown as disabled
          breakfast: shouldDisable ? false : (existingMeal?.breakfastTaken ?? true),
          lunch: shouldDisable ? false : (existingMeal?.lunchTaken ?? false),
          dinner: shouldDisable ? false : (existingMeal?.dinnerTaken ?? true),
          guestCount: shouldDisable ? 0 : (existingMeal?.guestCount ?? 0),
        ));
      }

      setState(() {
        rows = newRows;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchData();
    }
  }

  Future<void> _saveAll() async {
    setState(() => isSaving = true);
    try {
      final payload = rows.map((r) => {
        'userId': r.member.id,
        'breakfast': r.breakfast,
        'lunch': r.lunch,
        'dinner': r.dinner,
        'guestCount': r.guestCount,
      }).toList();

      await MealService.bulkRecordMeals(
        mealDate: formattedDate,
        meals: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit attendance saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isSaving ? null : _saveAll,
            tooltip: 'Save All',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: $formattedDate',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Change Date'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                              columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                          DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                          DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                          DataColumn(label: Text('Guest', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: List.generate(rows.length, (index) {
                          final row = rows[index];
                          final isMessOff = row.member.status == 'MESS OFF';
                          final isMealDisabled = !row.member.mealUnitEnabled;
                          final shouldDisable = isMessOff || isMealDisabled;
                          return DataRow(
                            color: shouldDisable
                                ? WidgetStateProperty.all(Colors.red.shade50)
                                : null,
                            cells: [
                            DataCell(Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: shouldDisable ? Colors.grey : null,
                              ),
                            )),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    row.member.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: shouldDisable ? Colors.grey : null,
                                      decoration: shouldDisable ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (shouldDisable)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'UNITS DISABLED',
                                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              )
                            ),
                            DataCell(
                              Checkbox(
                                value: row.breakfast,
                                activeColor: Colors.green,
                                onChanged: shouldDisable ? null : (val) {
                                  if (val != null) setState(() => row.breakfast = val);
                                },
                              )
                            ),
                            DataCell(
                              Checkbox(
                                value: row.lunch,
                                activeColor: Colors.green,
                                onChanged: shouldDisable ? null : (val) {
                                  if (val != null) setState(() => row.lunch = val);
                                },
                              )
                            ),
                            DataCell(
                              Checkbox(
                                value: row.dinner,
                                activeColor: Colors.green,
                                onChanged: shouldDisable ? null : (val) {
                                  if (val != null) setState(() => row.dinner = val);
                                },
                              )
                            ),
                            DataCell(
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: row.guestCount > 0 ? row.guestCount.toString() : '',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  enabled: !shouldDisable,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (val) {
                                    row.guestCount = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                            ),
                          ]);
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
              ],
            ),
      bottomNavigationBar: isSaving 
        ? const LinearProgressIndicator() 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Save All Units', style: TextStyle(fontSize: 16)),
              onPressed: _saveAll,
            ),
          ),
    );
  }
}
