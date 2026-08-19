
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Log out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx);


              context.read<AuthBloc>().add(LogoutRequested());

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF1A1A2E),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(

        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              SizedBox(height: 30),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: Icon(Icons.logout, color: Colors.red.shade900),
                  label: Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    textStyle: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),

              const Spacer(),

              // Delete Account Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteAccountDialog(context);
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Privacy Policy Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('By using this app, you agree to our '),
                  GestureDetector(
                    onTap: () => _launchPrivacyPolicy(),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before deleting account
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                context.read<AuthBloc>().add(LogoutRequested());

                _launchDelete();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchDelete() async {
    const privacyPolicyUrl = 'https://campus-crush-du8m.vercel.app/';
    final Uri uri = Uri.parse(privacyPolicyUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $privacyPolicyUrl';
      }
    } catch (e) {
      // AppSnackBar.show(context, 'Could not open privacy policy: $e', type: SnackBarType.error);
    }
  }

  /// Launches the privacy policy URL
  Future<void> _launchPrivacyPolicy() async {
    const privacyPolicyUrl =
        'https://sites.google.com/view/campuscrushprivacypolicy';
    final Uri uri = Uri.parse(privacyPolicyUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $privacyPolicyUrl';
      }
    } catch (e) {
      // AppSnackBar.show(context, 'Could not open privacy policy: $e', type: SnackBarType.error);
    }
  }
}

