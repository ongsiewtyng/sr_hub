// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileProvider.notifier).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/profile/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stackTrace) => ErrorDisplay(
          message: 'Failed to load profile',
          onRetry: () => ref.read(userProfileProvider.notifier).loadUserProfile(),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No user data found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(userProfileProvider.notifier).loadUserProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),

                  // Profile Information Cards
                  _buildInfoCard('Personal Information', [
                    _buildInfoRow('Full Name', user.name),
                    _buildInfoRow('Email', user.email),
                    _buildInfoRow('Phone', user.phoneNumber ?? 'Not provided'),
                    _buildInfoRow('Date of Birth', user.dateOfBirth?.toString().split(' ')[0] ?? 'Not provided'),
                  ]),

                  const SizedBox(height: 16),

                  _buildInfoCard('Academic Information', [
                    _buildInfoRow('Student ID', user.studentId),
                    _buildInfoRow('Department', user.department),
                    _buildInfoRow('Role', user.role.toUpperCase()),
                    _buildInfoRow('Member Since', user.memberSince?.toString().split(' ')[0] ?? 'Unknown'),
                  ]),

                  const SizedBox(height: 16),

                  _buildInfoCard('Account Status', [
                    _buildInfoRow('Verification Status', user.isVerified ? 'Verified' : 'Not Verified'),
                    _buildInfoRow('Account Created', user.createdAt?.toString().split(' ')[0] ?? 'Unknown'),
                    _buildInfoRow('Last Updated', user.updatedAt?.toString().split(' ')[0] ?? 'Unknown'),
                  ]),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                  ? Icon(
                Icons.person,
                size: 60,
                color: Colors.grey.shade600,
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: () {
                    // TODO: Implement image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload coming soon!')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Name and Email
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),

        // Verification Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user.isVerified ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.isVerified ? Icons.verified : Icons.pending,
                size: 16,
                color: user.isVerified ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                user.isVerified ? 'Verified' : 'Pending Verification',
                style: TextStyle(
                  color: user.isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/profile/edit');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement change password
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change password coming soon!')),
              );
            },
            icon: const Icon(Icons.lock),
            label: const Text('Change Password'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteAccountDialog(context),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}