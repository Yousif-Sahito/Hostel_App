import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not available';
    return value;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.withValues(alpha: 0.12),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
    final authUser = authProvider.currentUser;

    final profile = ProfileModel.fromAuthUser(authUser);

    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..setProfile(profile),
      child: Builder(
        builder: (context) {
          final provider = context.watch<ProfileProvider>();
          final data = provider.profile;

          if (data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              drawer: const AppDrawer(),
              body: const Center(child: Text('No profile data found')),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            drawer: const AppDrawer(),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.blue.withValues(alpha: 
                                    0.15,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 42,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  data.fullName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Chip(
                                      avatar: const Icon(
                                        Icons.badge_outlined,
                                        size: 18,
                                      ),
                                      label: Text(data.role),
                                    ),
                                    Chip(
                                      avatar: Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: _statusColor(data.status),
                                      ),
                                      label: Text(data.status),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                _infoTile(
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  value: _displayValue(data.fullName),
                                ),
                                _infoTile(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: _displayValue(data.email),
                                ),
                                _infoTile(
                                  icon: Icons.badge_outlined,
                                  label: 'CMS ID',
                                  value: _displayValue(data.cmsId),
                                ),
                                _infoTile(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: 'Role',
                                  value: _displayValue(data.role),
                                ),
                                _infoTile(
                                  icon: Icons.verified_user_outlined,
                                  label: 'Account Status',
                                  value: _displayValue(data.status),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: context.read<ProfileProvider>(),
                                    child: const ChangePasswordScreen(),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.lock_reset),
                            label: const Text(
                              'Change Password',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
        },
      ),
    );
  }
}
