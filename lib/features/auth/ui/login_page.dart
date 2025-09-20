import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/common/styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        backgroundColor: kTransparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Sign in with your YCDSB Google account\n(ycdsb.ca or ycdsbk12.ca).',
                  style: kBodyText,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                // Use the provided google icon asset (fallback to built-in Icon
                // if something goes wrong).
                icon: Image.asset(
                  'assets/logos/google_icon.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (c, e, s) => const Icon(Icons.login),
                ),
                label: _loading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in with Google'),
                onPressed: _loading
                    ? null
                    : () async {
                        // Capture these before awaiting to avoid using BuildContext
                        // across async gaps.
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        setState(() {
                          _loading = true;
                        });
                        var success = false;
                        String? errorMessage;
                        try {
                          await auth.signInWithGoogle();
                          success = true;
                        } catch (e) {
                          success = false;
                          var msg = e.toString();
                          if (msg.startsWith('Exception: ')) {
                            msg = msg.substring('Exception: '.length);
                          }
                          errorMessage = msg.isNotEmpty
                              ? msg
                              : 'Sign in failed';
                        } finally {
                          if (mounted) {
                            setState(() {
                              _loading = false;
                            });
                          }
                        }

                        if (!mounted) return;
                        if (success) {
                          navigator.pop();
                        } else {
                          // On web, if we switched to redirect sign-in, the page may reload.
                          // Provide a brief hint to the user before returning.
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(errorMessage ?? 'Sign in failed'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(padding: kButtonPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
