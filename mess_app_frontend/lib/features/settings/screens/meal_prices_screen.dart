import 'package:flutter/material.dart';

import '../models/settings_model.dart';
import '../services/settings_service.dart';

class MealPricesScreen extends StatefulWidget {
  const MealPricesScreen({super.key});

  @override
  State<MealPricesScreen> createState() => _MealPricesScreenState();
}

class _MealPricesScreenState extends State<MealPricesScreen> {
  late Future<SettingsModel> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = SettingsService.getSettings();
  }

  Future<void> _refresh() async {
    setState(() {
      _settingsFuture = SettingsService.getSettings();
    });
    await _settingsFuture;
  }

  Widget _priceTile(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withAlpha(26),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Prices')),
      body: FutureBuilder<SettingsModel>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final settings = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Mess Prices',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'These values are used to calculate your monthly bill.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _priceTile(
                    'Breakfast Price',
                    '${settings.breakfastPrice.toStringAsFixed(0)} ${settings.currency}',
                    Icons.free_breakfast,
                  ),
                  _priceTile(
                    'Lunch Price',
                    '${settings.lunchPrice.toStringAsFixed(0)} ${settings.currency}',
                    Icons.lunch_dining,
                  ),
                  _priceTile(
                    'Dinner Price',
                    '${settings.dinnerPrice.toStringAsFixed(0)} ${settings.currency}',
                    Icons.dinner_dining,
                  ),
                  _priceTile(
                    'Guest Meal Price',
                    '${settings.guestMealPrice.toStringAsFixed(0)} ${settings.currency}',
                    Icons.person,
                  ),
                  _priceTile(
                    'Helper Charge',
                    '${settings.helperCharge.toStringAsFixed(0)} ${settings.currency}',
                    Icons.payments,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prices last updated: ${settings.updatedAt ?? 'Unknown'}',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
