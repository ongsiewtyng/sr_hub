import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, _) => ErrorDisplay(
          message: 'Failed to load profile',
          onRetry: () => ref.read(userProfileProvider.notifier).loadUserProfile(),
        ),
        data: (user) {
          if (user == null) return _emptyState();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _profileHeader(context, user),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Personal Info'),
              _infoTile(Icons.person, 'Name', user.name),
              _infoTile(Icons.email, 'Email', user.email),
              _infoTile(Icons.phone, 'Phone', user.phoneNumber ?? 'Not provided'),
              _infoTile(Icons.cake, 'DOB', user.dateOfBirth != null ? dateFormat.format(user.dateOfBirth!) : 'Not provided'),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Academic Info'),
              _infoTile(Icons.badge, 'Student ID', user.studentId),
              _infoTile(Icons.school, 'Department', user.department),
              _infoTile(Icons.work_outline, 'Role', user.role.toUpperCase()),
              _infoTile(Icons.calendar_month, 'Member Since', user.memberSince != null ? dateFormat.format(user.memberSince!) : '—'),

              const SizedBox(height: 24),
              _sectionTitle(context, 'System Info'),
              _infoTile(Icons.date_range, 'Created', user.createdAt != null ? dateFormat.format(user.createdAt!) : '—'),
              _infoTile(Icons.update, 'Last Updated', user.updatedAt != null ? dateFormat.format(user.updatedAt!) : '—'),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline, size: 72, color: Colors.grey),
        SizedBox(height: 16),
        Text('No profile data', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    ),
  );

  Widget _profileHeader(BuildContext context, dynamic user) {
    final hasImage = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

    return Column(
      children: [
        ClipOval(
          child: Container(
            color: Colors.grey.shade300,
            width: 104,
            height: 104,
            child: hasImage
                ? SvgPicture.network(
              user.profileImageUrl!,
              fit: BoxFit.cover,
              placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
            )
                : Icon(Icons.person, size: 52, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.blueGrey),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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
}
