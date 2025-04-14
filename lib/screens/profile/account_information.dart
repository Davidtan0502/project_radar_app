import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:project_radar_app/screens/profile/edit_account_info.dart';

class AccountInformationScreen extends StatelessWidget {
  const AccountInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigation.pushReplacement(context, const AccountManagementScreen());
        return false;
      },
      child: _buildScreenContent(context),
    );
  }

  Widget _buildScreenContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Information',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigation.pushReplacement(
              context, const AccountManagementScreen()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context, primaryColor, cardColor!),
            const SizedBox(height: 32),
            _buildAccountInfoCard(context, cardColor, theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Color primaryColor, Color cardColor) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundImage:
                      AssetImage('assets/images/profile_placeholder.png'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('John Doe',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Premium Member',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
      BuildContext context, Color cardColor, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildInfoTile(
              context,
              icon: Icons.person_outline,
              label: 'Full Name',
              value: 'John Doe',
            ),
            _buildDivider(context),
            _buildInfoTile(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'john.doe@example.com',
            ),
            _buildDivider(context),
            _buildInfoTile(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: '+1 (555) 123-4567',
            ),
            _buildDivider(context),
            _buildInfoTile(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Joined Date',
              value: 'January 15, 2023',
            ),
          ],
        ),
      ),
    );
  }

 
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          )),
      subtitle: Text(value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          )),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
    );
  }
