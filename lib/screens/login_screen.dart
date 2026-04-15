import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isLoginMode = true;
  bool obscurePassword = true;

  Future<void> _submitEmailAuth() async {
    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password are required.';
      }

      if (password.length < 6) {
        throw 'Password must be at least 6 characters.';
      }

      if (isLoginMode) {
        await authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        final response = await authService.signUpWithEmail(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. If email confirmation is still enabled in Supabase, check your email first.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully.'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => isLoading = true);

    try {
      await authService.signInAsGuest();
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();
      if (message.contains('anonymous_provider_disabled')) {
        message =
            'Guest login is not enabled in Supabase yet. Turn on Anonymous Sign-Ins in Authentication > Providers.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => isLoading = true);

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 60,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.yellow,
                        AppColors.orange,
                        AppColors.red,
                        AppColors.purple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.festival,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kadayawan Event Hub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Explore festival schedules, venues, and colorful celebrations in Davao City.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 16,
                        offset: Offset(0, 4),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          floatingLabelStyle: const TextStyle(
                            color: AppColors.brown,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brownLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brown,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          floatingLabelStyle: const TextStyle(
                            color: AppColors.brown,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brownLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brown,
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            isLoading
                                ? 'Please wait...'
                                : isLoginMode
                                    ? 'Login with Email'
                                    : 'Sign Up with Email',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: isLoading ? null : _toggleMode,
                        child: Text(
                          isLoginMode
                              ? 'No account yet? Create one'
                              : 'Already have an account? Login',
                          style: const TextStyle(
                            color: AppColors.brown,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _continueWithGoogle,
                          icon: const Icon(Icons.login),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brown,
                            side: const BorderSide(
                              color: AppColors.brownLight,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _continueAsGuest,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Continue as Guest'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brown,
                            side: const BorderSide(
                              color: AppColors.brownLight,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}