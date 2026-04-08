import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
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
    identifierController.text = 'admin@hostel.com';
    passwordController.text = 'admin123';
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

    final success = await authProvider.login(
      email: isAdminLogin ? identifier : null,
      cmsId: isAdminLogin ? null : identifier,
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.memberDashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  void _switchMode(bool adminMode) {
    setState(() {
      isAdminLogin = adminMode;
      identifierController.text = adminMode ? 'admin@hostel.com' : 'MEM001';
      passwordController.text = adminMode ? 'admin123' : '';
    });
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
