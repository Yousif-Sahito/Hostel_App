import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../profile/services/profile_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  bool isAdminLogin = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAdminCredentials();
  }

  Future<void> _loadSavedAdminCredentials() async {
    final hasUpdated = await SecureStorageService.getAdminCredentialsUpdated();
    if (hasUpdated && mounted) {
      setState(() {
        // Keep the login fields empty for security and require the administrator to enter their current credentials.
        identifierController.text = '';
        passwordController.text = '';
      });
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    final success = await authProvider.login(
      email: isAdminLogin ? identifier : null,
      cmsId: isAdminLogin ? null : identifier,
      password: password,
    );

    if (!mounted) return;
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (success) {
      // Check if admin logged in with default credentials
      if (authProvider.isAdmin && identifier == 'admin@hostel.com' && password == 'admin123') {
        _showChangeCredentialsDialog(password);
      } else {
        if (authProvider.isAdmin) {
          router.go(AppRoutes.adminDashboard);
        } else {
          router.go(AppRoutes.memberDashboard);
        }
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  void _switchMode(bool adminMode) {
    setState(() {
      isAdminLogin = adminMode;
      identifierController.text = '';
      passwordController.text = '';
    });
  }

  void _showChangeCredentialsDialog(String currentPassword) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void> submitPasswordUpdate(String newPassword) async {
          try {
            await ProfileService.changePassword(
              oldPassword: currentPassword,
              newPassword: newPassword,
            );
            await SecureStorageService.saveAdminCredentialsUpdated(true);

            if (!mounted) return;
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Admin password updated successfully')),
            );
            Navigator.of(context).pop();
            router.go(AppRoutes.adminDashboard);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }

        return AlertDialog(
          title: const Text('Update Default Admin Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are using default admin credentials. Update the admin password for security.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go(AppRoutes.adminDashboard);
              },
              child: const Text('Skip for Now'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a new password')),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                submitPasswordUpdate(newPassword);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hostel Mess Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to continue',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _switchMode(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAdminLogin
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                foregroundColor: isAdminLogin
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: const Text('Admin'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _switchMode(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isAdminLogin
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                foregroundColor: !isAdminLogin
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: const Text('Member'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      TextField(
                        controller: identifierController,
                        decoration: InputDecoration(
                          labelText: isAdminLogin ? 'Email' : 'CMS ID',
                          prefixIcon: Icon(
                            isAdminLogin
                                ? Icons.email_outlined
                                : Icons.badge_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
