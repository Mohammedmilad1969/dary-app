import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../widgets/user_listing_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_screen.dart';
import '../../services/property_service.dart';
import '../../services/persistence_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserProperties();
  }

  Future<void> _loadUserProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      await ProfileService.loadUserProperties(currentUser.id);
      if (mounted) {
        setState(() {});
      }
    }
  }
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      return LoginRequiredScreen(
        featureName: l10n?.profile ?? 'Profile',
        description: 'Please login to view your profile and manage your listings',
      );
    }

    final user = authProvider.currentUser;
    final activeListings = ProfileService.activeListings;
    final totalListings = ProfileService.userListings.length;
    final activeCount = ProfileService.activeListings.length;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.profile ?? 'Profile'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        AppBar(
          title: Text(l10n?.profile ?? 'Profile'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: user.profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user.profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.green,
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            l10n?.activeListings ?? 'Total Listings',
                            '$totalListings',
                            Icons.home,
                          ),
                          _buildStatItem(
                            l10n?.activeListings ?? 'Active Listings',
                            '$activeCount',
                            Icons.check_circle,
                          ),
                          _buildStatItem(
                            'Member Since',
                            '2024',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Active Listings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n?.activeListings ?? 'Active Listings',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n?.viewAll ?? 'View all listings'),
                                ),
                              );
                            },
                            child: Text(l10n?.viewAll ?? 'View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (activeListings.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No active listings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeListings.length,
                          itemBuilder: (context, index) {
                            return UserListingCard(
                              listing: activeListings[index],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Management Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            Text(
                              l10n?.accountManagement ?? 'Account Management',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(height: 16),
                      
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit profile functionality coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(l10n?.editProfile ?? 'Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Notification Settings Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.go('/notification-settings');
                          },
                          icon: const Icon(Icons.notifications),
                          label: Text(l10n?.notificationSettings ?? 'Notification Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Verification Button (only show if not verified)
                      if (!user.isVerified) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/verification'),
                            icon: const Icon(Icons.verified_user),
                            label: Text(l10n?.getVerified ?? 'Get Verified'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Analytics Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/analytics'),
                          icon: const Icon(Icons.analytics),
                          label: Text(l10n?.viewAnalytics ?? 'View Analytics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Admin Dashboard Button (only show for admin users)
                      if (user.email == 'admin@dary.com' || user.email == 'john.doe@example.com') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/admin'),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: Text(l10n?.adminDashboard ?? 'Admin Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Upgrade Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/paywall'),
                          icon: const Icon(Icons.star),
                          label: Text(l10n?.upgradeToPremium ?? 'Upgrade to Premium'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Delete Account Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showDeleteAccountDialog(context);
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: Text(l10n?.deleteAccount ?? 'Delete Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete account functionality coming soon!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Update your information',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Customize your experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
