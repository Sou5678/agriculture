import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/auth_provider.dart';
import '../providers/detection_provider.dart';
import '../core/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, DetectionProvider>(
        builder: (context, authProvider, detectionProvider, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: AnimationLimiter(
                child: Column(
                  children: [
                    // Profile Header
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppConstants.paddingLarge),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Profile Avatar
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: authProvider.photoURL != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(40),
                                          child: Image.network(
                                            authProvider.photoURL!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                
                                // User Name
                                Text(
                                  authProvider.displayName,
                                  style: AppTextStyles.headline2,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                
                                // User Email or Status
                                Text(
                                  authProvider.isAnonymous 
                                      ? 'Guest User'
                                      : authProvider.email,
                                  style: AppTextStyles.bodyText2,
                                  textAlign: TextAlign.center,
                                ),
                                
                                if (authProvider.isAnonymous) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/login'),
                                    icon: const Icon(Icons.person_add, size: 18),
                                    label: const Text('Create Account'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Statistics Cards
                    AnimationConfiguration.staggeredList(
                      position: 1,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Scans',
                                  detectionProvider.totalDetections.toString(),
                                  Icons.camera_alt,
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Healthy Plants',
                                  detectionProvider.healthyDetections.toString(),
                                  Icons.eco,
                                  AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AnimationConfiguration.staggeredList(
                      position: 2,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Diseases Found',
                                  detectionProvider.diseaseDetections.toString(),
                                  Icons.warning,
                                  AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'This Week',
                                  detectionProvider.getRecentDetections().length.toString(),
                                  Icons.calendar_today,
                                  AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Settings Section
                    AnimationConfiguration.staggeredList(
                      position: 3,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                                  child: Text(
                                    'Settings',
                                    style: AppTextStyles.headline3,
                                  ),
                                ),
                                
                                // Cloud Sync Toggle
                                if (detectionProvider.isCloudSyncAvailable)
                                  _buildSettingsTile(
                                    icon: Icons.cloud_sync,
                                    title: 'Cloud Sync',
                                    subtitle: 'Sync your data across devices',
                                    trailing: Switch(
                                      value: detectionProvider.syncWithCloud,
                                      onChanged: (value) {
                                        detectionProvider.toggleCloudSync(value);
                                      },
                                    ),
                                  ),
                                
                                // Sync Now Button
                                if (detectionProvider.isCloudSyncAvailable && detectionProvider.syncWithCloud)
                                  _buildSettingsTile(
                                    icon: Icons.sync,
                                    title: 'Sync Now',
                                    subtitle: 'Manually sync with cloud',
                                    onTap: () async {
                                      await detectionProvider.performCloudSync();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Sync completed'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                
                                // View History
                                _buildSettingsTile(
                                  icon: Icons.history,
                                  title: 'Detection History',
                                  subtitle: 'View all your plant scans',
                                  onTap: () => context.go('/history'),
                                ),
                                
                                // About
                                _buildSettingsTile(
                                  icon: Icons.info,
                                  title: 'About',
                                  subtitle: 'App version and information',
                                  onTap: () => _showAboutDialog(context),
                                ),
                                
                                // Sign Out
                                if (!authProvider.isAnonymous)
                                  _buildSettingsTile(
                                    icon: Icons.logout,
                                    title: 'Sign Out',
                                    subtitle: 'Sign out of your account',
                                    onTap: () => _showSignOutDialog(context, authProvider),
                                    isDestructive: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headline2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodyText2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyText1.copyWith(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Plant Disease Detector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            const Text('AI-powered plant disease detection app that helps farmers and gardeners identify plant diseases early.'),
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Real-time disease detection'),
            const Text('• Treatment recommendations'),
            const Text('• Detection history'),
            const Text('• Cloud synchronization'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You can continue using the app as a guest.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}