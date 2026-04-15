import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../../../app/routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final hostelNameController = TextEditingController();
  final breakfastPriceController = TextEditingController();
  final lunchPriceController = TextEditingController();
  final dinnerPriceController = TextEditingController();
  final guestMealPriceController = TextEditingController();
  final helperChargeController = TextEditingController();
  final currencyController = TextEditingController();
  final cutoffDayController = TextEditingController();

  bool messOffEnabled = true;
  String messStatus = 'ON';
  bool _didFillForm = false;

  @override
  void dispose() {
    hostelNameController.dispose();
    breakfastPriceController.dispose();
    lunchPriceController.dispose();
    dinnerPriceController.dispose();
    guestMealPriceController.dispose();
    helperChargeController.dispose();
    currencyController.dispose();
    cutoffDayController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  void _fillForm(SettingsModel settings) {
    hostelNameController.text = settings.hostelName;
    breakfastPriceController.text = settings.breakfastPrice > 0 ? settings.breakfastPrice.toStringAsFixed(0) : '';
    lunchPriceController.text = settings.lunchPrice > 0 ? settings.lunchPrice.toStringAsFixed(0) : '';
    dinnerPriceController.text = settings.dinnerPrice > 0 ? settings.dinnerPrice.toStringAsFixed(0) : '';
    guestMealPriceController.text = settings.guestMealPrice > 0 ? settings.guestMealPrice.toStringAsFixed(0) : '';
    helperChargeController.text = settings.helperCharge > 0 ? settings.helperCharge.toStringAsFixed(0) : '';
    currencyController.text = settings.currency;
    cutoffDayController.text = settings.cutoffDay.toString();
    messOffEnabled = settings.messOffEnabled;
    messStatus = settings.messStatus;
    _didFillForm = true;
  }

  Future<void> _saveSettings(SettingsProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    if (provider.settings == null) return;

    final updatedSettings = provider.settings!.copyWith(
      hostelName: hostelNameController.text.trim(),
      breakfastPrice:
          double.tryParse(breakfastPriceController.text.trim()) ?? 0,
      lunchPrice: double.tryParse(lunchPriceController.text.trim()) ?? 0,
      dinnerPrice: double.tryParse(dinnerPriceController.text.trim()) ?? 0,
      guestMealPrice:
          double.tryParse(guestMealPriceController.text.trim()) ?? 0,
      helperCharge: double.tryParse(helperChargeController.text.trim()) ?? 0,
      currency: currencyController.text.trim(),
      cutoffDay: int.tryParse(cutoffDayController.text.trim()) ?? 25,
      messOffEnabled: messOffEnabled,
      messStatus: messStatus,
    );

    final success = await provider.saveSettings(updatedSettings);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (provider.successMessage ?? 'Settings updated successfully')
              : (provider.errorMessage ?? 'Failed to update settings'),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(AuthProvider authProvider) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your hostel and ALL records (members, rooms, meals, bills, payments, etc.).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (first != true) return;

    final confirmController = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final canDelete =
              confirmController.text.trim().toUpperCase() == 'DELETE';

          return AlertDialog(
            title: const Text('Final confirmation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type DELETE to confirm.'),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (confirmController.text.trim().toUpperCase() == 'DELETE') {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canDelete ? () => Navigator.pop(context, true) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete permanently'),
              ),
            ],
          );
        },
      ),
    );
    confirmController.dispose();

    if (second != true) return;

    try {
      final success = await authProvider.deleteAccount();
      
      if (!mounted) return;
      
      if (success) {
        context.go(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to delete account'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _numberValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? _cutoffValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cutoff day is required';
    }

    final day = int.tryParse(value.trim());
    if (day == null) {
      return 'Enter a valid day';
    }
    if (day < 1 || day > 31) {
      return 'Cutoff day must be between 1 and 31';
    }

    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withValues(alpha: 0.12),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role.toUpperCase() == 'ADMIN';

    final settings = settingsProvider.settings;

    if (settings != null && !_didFillForm) {
      _fillForm(settings);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: settingsProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : settingsProvider.errorMessage != null && settings == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    settingsProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            : settings == null
            ? const Center(child: Text('No settings found'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.settings,
                                  size: 52,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Mess Application Settings',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAdmin
                                      ? 'Admin can manage general system settings from here.'
                                      : 'You can view current application settings here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (isAdmin)
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: hostelNameController,
                                      label: 'Hostel Name',
                                      icon: Icons.home_work_outlined,
                                      validator: (value) => _requiredValidator(
                                        value,
                                        'Hostel name',
                                      ),
                                    ),
                                    _buildTextField(
                                      controller: breakfastPriceController,
                                      label: 'Breakfast Price',
                                      icon: Icons.free_breakfast,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) =>
                                          _numberValidator(value, 'Breakfast price'),
                                    ),
                                    _buildTextField(
                                      controller: lunchPriceController,
                                      label: 'Lunch Price',
                                      icon: Icons.lunch_dining,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) =>
                                          _numberValidator(value, 'Lunch price'),
                                    ),
                                    _buildTextField(
                                      controller: dinnerPriceController,
                                      label: 'Dinner Price',
                                      icon: Icons.dinner_dining,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) =>
                                          _numberValidator(value, 'Dinner price'),
                                    ),
                                    _buildTextField(
                                      controller: guestMealPriceController,
                                      label: 'Guest Meal Price',
                                      icon: Icons.person,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) =>
                                          _numberValidator(value, 'Guest meal price'),
                                    ),
                                    _buildTextField(
                                      controller: helperChargeController,
                                      label: 'Helper Charge',
                                      icon: Icons.payments_outlined,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) => _numberValidator(
                                        value,
                                        'Helper charge',
                                      ),
                                    ),
                                    _buildTextField(
                                      controller: currencyController,
                                      label: 'Currency',
                                      icon: Icons.currency_exchange,
                                      validator: (value) =>
                                          _requiredValidator(value, 'Currency'),
                                    ),
                                    _buildTextField(
                                      controller: cutoffDayController,
                                      label: 'Mess Off Cutoff Day',
                                      icon: Icons.calendar_today_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: _cutoffValidator,
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                        'Enable Mess Off Option',
                                      ),
                                      subtitle: const Text(
                                        'Allow mess off functionality in the app',
                                      ),
                                      value: messOffEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          messOffEnabled = value;
                                        });
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Global Mess Status'),
                                      subtitle: Text(messStatus == 'ON' ? 'Mess is currently OPEN' : 'Mess is currently CLOSED'),
                                      value: messStatus == 'ON',
                                      activeThumbColor: Colors.green,
                                      onChanged: (value) {
                                        setState(() {
                                          messStatus = value ? 'ON' : 'OFF';
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton.icon(
                                        onPressed: settingsProvider.isSaving
                                            ? null
                                            : () => _saveSettings(
                                                settingsProvider,
                                              ),
                                        icon: settingsProvider.isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.save),
                                        label: Text(
                                          settingsProvider.isSaving
                                              ? 'Saving...'
                                              : 'Save Settings',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: settingsProvider.isSaving
                                            ? null
                                            : () => _deleteAccount(authProvider),
                                        icon: const Icon(Icons.delete_forever),
                                        label: const Text('Delete Account'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  _buildReadOnlyTile(
                                    icon: Icons.home_work_outlined,
                                    title: 'Hostel Name',
                                    value: settings.hostelName,
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.free_breakfast,
                                    title: 'Breakfast Price',
                                    value: settings.breakfastPrice.toStringAsFixed(0),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.lunch_dining,
                                    title: 'Lunch Price',
                                    value: settings.lunchPrice.toStringAsFixed(0),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.dinner_dining,
                                    title: 'Dinner Price',
                                    value: settings.dinnerPrice.toStringAsFixed(0),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.person,
                                    title: 'Guest Meal Price',
                                    value: settings.guestMealPrice.toStringAsFixed(0),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.payments_outlined,
                                    title: 'Helper Charge',
                                    value: settings.helperCharge
                                        .toStringAsFixed(0),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.currency_exchange,
                                    title: 'Currency',
                                    value: settings.currency,
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.calendar_today_outlined,
                                    title: 'Mess Off Cutoff Day',
                                    value: settings.cutoffDay.toString(),
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.settings_power,
                                    title: 'Global Mess Status',
                                    value: settings.messStatus == 'ON' ? 'OPEN' : 'CLOSED',
                                  ),
                                  _buildReadOnlyTile(
                                    icon: Icons.toggle_on_outlined,
                                    title: 'Mess Off Allow Status',
                                    value: settings.messOffEnabled
                                        ? 'Enabled'
                                        : 'Disabled',
                                  ),
                                ],
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
