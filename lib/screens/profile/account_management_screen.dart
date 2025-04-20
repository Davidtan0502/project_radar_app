import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/edit_account_info.dart';
import 'package:project_radar_app/screens/profile/change_password.dart';
import 'package:project_radar_app/screens/profile/account_information.dart';
import 'package:project_radar_app/services/navigation.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Account"),
            content: const Text(
              "Are you sure you want to delete your account? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deletion initiated."),
                    ),
                  );
                  // TODO: Add delete logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigation.back(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text(
                      'Account Information',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap:
                        () => Navigation.push(
                          context,
                          const AccountInformationScreen(),
                        ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                    title: const Text(
                      'Edit Account Details',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap:
                        () => Navigation.push(context, const EditAccountinfo()),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.lock, color: theme.colorScheme.primary),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap:
                        () => Navigation.push(context, const ChangePassword()),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () => _confirmDeleteAccount(context),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
