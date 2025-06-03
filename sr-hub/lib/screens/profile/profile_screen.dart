// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../data/sample_data.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = SampleData.getUser();
    final reservations = SampleData.getReservations();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePictureUrl!),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Edit profile button
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),

            // Stats section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    context,
                    Icons.event_seat,
                    reservations.length.toString(),
                    'Reservations',
                  ),
                  _buildStatCard(
                    context,
                    Icons.book,
                    '5',
                    'Books',
                  ),
                  _buildStatCard(
                    context,
                    Icons.file_copy,
                    '23',
                    'Resources',
                  ),
                ],
              ),
            ),

            // Activity section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                final types = ['reservation', 'book', 'resource', 'reservation'];
                final titles = [
                  'Reserved Seat 101',
                  'Checked out "Flutter in Action"',
                  'Accessed "Flutter State Management Tutorial"',
                  'Reserved Study Room 3',
                ];
                final timestamps = ['2 hours ago', '1 day ago', '3 days ago', '1 week ago'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActivityColor(types[index]),
                    child: Icon(
                      _getActivityIcon(types[index]),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(titles[index]),
                  subtitle: Text(timestamps[index]),
                  onTap: () {},
                );
              },
            ),

            // Saved items section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final titles = [
                    'Flutter in Action',
                    'Flutter State Management Tutorial',
                    'Seat 101',
                    'Mobile App Design Principles',
                  ];
                  final types = ['Book', 'Resource', 'Seat', 'Resource'];

                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == 3 ? 16 : 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item thumbnail
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: _getSavedItemColor(types[index]),
                          ),
                          child: Center(
                            child: Icon(
                              _getSavedItemIcon(types[index]),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Item title
                        Text(
                          titles[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        // Item type
                        Text(
                          types[index],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'reservation':
        return Colors.blue;
      case 'book':
        return Colors.green;
      case 'resource':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'reservation':
        return Icons.event_seat;
      case 'book':
        return Icons.book;
      case 'resource':
        return Icons.file_copy;
      default:
        return Icons.history;
    }
  }

  Color _getSavedItemColor(String type) {
    switch (type) {
      case 'Book':
        return Colors.green;
      case 'Resource':
        return Colors.purple;
      case 'Seat':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSavedItemIcon(String type) {
    switch (type) {
      case 'Book':
        return Icons.book;
      case 'Resource':
        return Icons.file_copy;
      case 'Seat':
        return Icons.event_seat;
      default:
        return Icons.bookmark;
    }
  }
}