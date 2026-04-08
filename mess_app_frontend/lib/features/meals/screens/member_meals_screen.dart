import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../widgets/meal_entry_card.dart';

class MemberMealsScreen extends StatelessWidget {
  const MemberMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final memberId = authProvider.currentUser?.id ?? 0;

    return ChangeNotifierProvider(
      create: (_) => MealProvider()..fetchMealsByMember(memberId),
      child: const _MemberMealsView(),
    );
  }
}

class _MemberMealsView extends StatelessWidget {
  const _MemberMealsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Units')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
            ? Center(child: Text(provider.errorMessage!))
            : provider.filteredMeals.isEmpty
            ? const Center(child: Text('No meal entries found'))
            : RefreshIndicator(
                onRefresh: () async {
                  final authProvider = context.read<AuthProvider>();
                  final memberId = authProvider.currentUser?.id ?? 0;
                  await context.read<MealProvider>().fetchMealsByMember(
                    memberId,
                  );
                },
                child: ListView.builder(
                  itemCount: provider.filteredMeals.length,
                  itemBuilder: (context, index) {
                    final meal = provider.filteredMeals[index];
                    return MealEntryCard(meal: meal);
                  },
                ),
              ),
      ),
    );
  }
}
