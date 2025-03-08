import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_assets/app_assets.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, bool> _settings;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carBrandController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settings = {
      'pushNotifications': true,
      'locationServices': true,
      'darkMode': false,
    };
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId != null) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final userData = await firestoreService.getUserData(userId);
      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _carBrandController.text = userData['car']?['brand'] ?? '';
          _carModelController.text = userData['car']?['model'] ?? '';

          // Load settings
          _settings = Map<String, bool>.from(userData['settings'] ?? _settings);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.updateUserData({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'car': {
            'brand': _carBrandController.text,
            'model': _carModelController.text,
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile information saved successfully')),
          );
        }
      } catch (e) {
        print('Error saving profile info: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Error saving profile information. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _saveSettings(String key, bool value) async {
    setState(() => _settings[key] = value);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserData({
        'settings': _settings,
      });
    } catch (e) {
      print('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error saving settings. Please try again.')),
        );
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
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            selectedIcon: const Text('Save'),
            icon: const Icon(Icons.save),
            onPressed: _saveProfileInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: false,
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
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: const AssetImage(AppAssets.profile),
                              child: user.photoURL == null
                                  ? null:
                                  ClipOval(
                                child: Image.network(
                                  user.photoURL!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                            ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.displayName  ?? _firstNameController.text ?? 'User Name',
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileSection(),
                          const SizedBox(height: 24),
                          _buildSection(
                            'App Settings',
                            [
                              _buildSettingTile(
                                'Push Notifications',
                                'Receive alerts about charging status',
                                Icons.notifications,
                                _settings['pushNotifications'] ?? true,
                                (value) =>
                                    _saveSettings('pushNotifications', value),
                              ),
                              _buildSettingTile(
                                'Location Services',
                                'Allow app to access your location',
                                Icons.location_on,
                                _settings['locationServices'] ?? true,
                                (value) =>
                                    _saveSettings('locationServices', value),
                              ),
                              _buildSettingTile(
                                'Dark Mode',
                                'Switch between light and dark theme',
                                Icons.dark_mode,
                                _settings['darkMode'] ?? false,
                                (value) => _saveSettings('darkMode', value),
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
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            enabled: false,
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Vehicle Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _carBrandController,
          decoration: const InputDecoration(
            labelText: 'Car Brand',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your car brand';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _carModelController,
          decoration: const InputDecoration(
            labelText: 'Car Model',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your car model';
            }
            return null;
          },
        ),
      ],
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
        Card(
          elevation: 2,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _carBrandController.dispose();
    super.dispose();
  }
}
