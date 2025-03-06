import 'package:flutter/material.dart';
import 'package:ev_charging_app/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_assets/app_assets.dart';
import 'package:ev_charging_app/core/services/firestore_service.dart';

import '../../../../core/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.getCurrentUserId();
    if (userId != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final userData = await firestoreService.getUserData(userId);
      if (userData != null && mounted) {
        setState(() {
          _emailController.text = userData['email'] ?? '';
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      }
    } catch (e) {
      // Handle sign out error
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      // Handle not logged in state
      return const Center(child: Text('Please sign in'));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(AppAssets.profile),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Personal Information',
                    [
                      _buildTextField(
                        'First Name',
                        _firstNameController,
                        Icons.person,
                      ),
                      _buildTextField(
                        'Last Name',
                        _lastNameController,
                        Icons.person,
                      ),
                      _buildTextField(
                        'Email',
                        _emailController,
                        Icons.email,
                        enabled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Vehicle Information',
                    [
                      _buildTextField(
                        'Brand',
                        TextEditingController(),
                        Icons.directions_car,
                      ),
                      _buildTextField(
                        'Model',
                        TextEditingController(),
                        Icons.car_repair,
                      ),
                      _buildTextField(
                        'Year',
                        TextEditingController(),
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'App Settings',
                    [
                      _buildSettingTile(
                        'Push Notifications',
                        'Receive alerts about charging status',
                        Icons.notifications,
                        true,
                      ),
                      _buildSettingTile(
                        'Location Services',
                        'Allow app to access your location',
                        Icons.location_on,
                        true,
                      ),
                      _buildSettingTile(
                        'Dark Mode',
                        'Switch between light and dark theme',
                        Icons.dark_mode,
                        false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool initialValue,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: initialValue,
      onChanged: (value) {
        // Handle setting change
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
