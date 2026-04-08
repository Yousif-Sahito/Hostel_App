import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../members/models/member_model.dart';
import '../../members/services/member_service.dart';
import '../models/meal_model.dart';
import '../providers/meal_provider.dart';
import '../services/meal_service.dart';
import '../widgets/meal_entry_card.dart';
import 'daily_meal_attendance_screen.dart';

class MealEntryScreen extends StatelessWidget {
  const MealEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MealProvider()..fetchMeals(),
      child: const _MealEntryView(),
    );
  }
}

class _MealEntryView extends StatelessWidget {
  const _MealEntryView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search units...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchMeals,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredMeals.isEmpty
                  ? const Center(child: Text('No unit entries found'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchMeals,
                      child: ListView.builder(
                        itemCount: provider.filteredMeals.length,
                        itemBuilder: (context, index) {
                          final meal = provider.filteredMeals[index];

                          return MealEntryCard(
                            meal: meal,
                            showActions: true,
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MealFormScreen(meal: meal),
                                ),
                              );

                              if (updated == true && context.mounted) {
                                await context.read<MealProvider>().fetchMeals();
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Unit Entry'),
                                  content: const Text(
                                      'Are you sure you want to delete this unit entry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  await MealService.deleteMeal(meal.id!);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unit entry deleted successfully',
                                        ),
                                      ),
                                    );
                                  }

                                  if (context.mounted) {
                                    await context
                                        .read<MealProvider>()
                                        .fetchMeals();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyMealAttendanceScreen()),
          );

          if (created == true && context.mounted) {
            await context.read<MealProvider>().fetchMeals();
          }
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Add Daily Units'),
      ),
    );
  }
}

class MealFormScreen extends StatefulWidget {
  final MealModel? meal;

  const MealFormScreen({super.key, this.meal});

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final guestCountController = TextEditingController();

  bool breakfastTaken = false;
  bool lunchTaken = false;
  bool dinnerTaken = false;
  bool isLoading = false;
  bool isMembersLoading = true;

  List<MemberModel> members = [];
  int? selectedMemberId;

  bool get isEdit => widget.meal != null;

  @override
  void initState() {
    super.initState();

    dateController.text = widget.meal?.mealDate ?? _todayDate();
    guestCountController.text = widget.meal?.guestCount.toString() ?? '0';

    breakfastTaken = widget.meal?.breakfastTaken ?? false;
    lunchTaken = widget.meal?.lunchTaken ?? false;
    dinnerTaken = widget.meal?.dinnerTaken ?? false;
    selectedMemberId = widget.meal?.userId;

    _loadMembers();
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMembers() async {
    try {
      final fetchedMembers = await MemberService.getMembers();

      if (!mounted) return;

      setState(() {
        members = fetchedMembers
            .where((m) => m.role.toUpperCase() == 'MEMBER')
            .toList();
        isMembersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isMembersLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    guestCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a member')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final guestCount = int.tryParse(guestCountController.text.trim()) ?? 0;

      if (isEdit) {
        await MealService.updateMeal(
          id: widget.meal!.id!,
          userId: selectedMemberId!,
          mealDate: dateController.text.trim(),
          breakfastTaken: breakfastTaken,
          lunchTaken: lunchTaken,
          dinnerTaken: dinnerTaken,
          guestCount: guestCount,
        );
      } else {
        await MealService.addMeal(
          userId: selectedMemberId!,
          mealDate: dateController.text.trim(),
          breakfastTaken: breakfastTaken,
          lunchTaken: lunchTaken,
          dinnerTaken: dinnerTaken,
          guestCount: guestCount,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Unit entry updated successfully'
                : 'Unit entry created successfully',
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

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Unit Entry' : 'Add Unit Entry'),
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
                  if (isMembersLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMemberId,
                        decoration: InputDecoration(
                          labelText: 'Member',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: members
                            .map(
                              (member) => DropdownMenuItem<int>(
                                value: member.id,
                                child: Text(
                                  '${member.fullName} (${member.cmsId ?? '-'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedMemberId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a member' : null,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: dateController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Date is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Unit Date',
                        hintText: 'yyyy-mm-dd',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  _switchTile(
                    'Breakfast Taken',
                    breakfastTaken,
                    (value) => setState(() => breakfastTaken = value),
                  ),
                  _switchTile(
                    'Lunch Taken',
                    lunchTaken,
                    (value) => setState(() => lunchTaken = value),
                  ),
                  _switchTile(
                    'Dinner Taken',
                    dinnerTaken,
                    (value) => setState(() => dinnerTaken = value),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: guestCountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Guest count is required';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Guest Count',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit
                                  ? 'Update Unit Entry'
                                  : 'Create Unit Entry',
                            ),
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
