import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // format date

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({Key? key}) : super(key: key);

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userDoc;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userDoc = FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // intercept Android back button
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userDoc,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Account Information'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const Center(child: Text('No user data found')),
            );
          }
          final data = snap.data!.data()!;
          final fullName =
              "${data['firstName']} ${data['middleName']} ${data['lastName']}";
          final email = data['email'] as String? ?? '';
          final phone = data['phone'] as String? ?? '';
          final dob = data['dob'] as String? ?? '';
          final address = data['address'] as String? ?? '';
          final bloodType = data['bloodType'] as String? ?? '';
          final height = data['height'] as String? ?? '';
          final weight = data['weight'] as String? ?? '';
          final Timestamp ts = data['createdAt'] as Timestamp;
          final joinedDate = DateFormat('MMMM d, y').format(ts.toDate());

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Account Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(fullName),
                  const SizedBox(height: 32),
                  _buildAccountInfoCard(
                    fullName,
                    email,
                    phone,
                    dob,
                    address,
                    bloodType,
                    height,
                    weight,
                    joinedDate,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String fullName) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

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
            child: const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage(
                'assets/images/profile_placeholder.png',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
    String fullName,
    String email,
    String phone,
    String dob,
    String address,
    String bloodType,
    String height,
    String weight,
    String joinedDate,
  ) {
    final theme = Theme.of(context);
    final cardColor =
        theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: fullName,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: dob,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.home_outlined,
              label: 'Address',
              value: address,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.water_drop_outlined,
              label: 'Blood Type',
              value: bloodType,
            ),
            _buildDivider(),
            _buildInfoTile(icon: Icons.height, label: 'Height', value: height),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: weight,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Joined Date',
              value: joinedDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
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
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
    );
  }
}
