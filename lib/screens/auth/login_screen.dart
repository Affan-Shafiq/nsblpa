import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    print('_submitForm called on login screen');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    print('Attempting signin...');
    
    final success = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/salesbet_player_logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'NSBLPA',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return ElevatedButton(
                          onPressed: authService.isLoading ? null : _submitForm,
                          child: authService.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Sign In'),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Error Message
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        if (authService.error != null) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                            ),
                            child: Text(
                              authService.error!,
                              style: TextStyle(color: AppColors.danger),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

                          // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.subtitle.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.subtitle.withOpacity(0.3))),
              ],
            ),

            const SizedBox(height: 24),

            // Google Sign In Button
            OutlinedButton.icon(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                final success = await authService.signInWithGoogle();
                if (success && mounted) {
                  context.go('/dashboard');
                }
              },
              icon: Image.network(
                'https://developers.google.com/identity/images/g-logo.png',
                height: 20,
                width: 20,
              ),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.subtitle.withOpacity(0.3)),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
} 