import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDateOfBirth;
  String? _selectedDepartment;

  final List<String> _departments = [
    'Computer Science', 'Information Technology', 'Software Engineering', 'Data Science',
    'Cybersecurity', 'Business Administration', 'Marketing', 'Finance', 'Accounting',
    'Economics', 'Psychology', 'Sociology', 'Political Science', 'History', 'English Literature',
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Environmental Science',
    'Mechanical Engineering', 'Electrical Engineering', 'Civil Engineering',
    'Chemical Engineering', 'Architecture', 'Graphic Design', 'Fine Arts', 'Music',
    'Theater Arts', 'Communications', 'Journalism', 'Education', 'Nursing', 'Medicine',
    'Pharmacy', 'Physical Therapy', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProfileAsync = ref.read(userProfileProvider);
    userProfileAsync.whenData((user) {
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phoneNumber ?? '';
        _addressController.text = user.address ?? '';
        _studentIdController.text = user.studentId;
        _departmentController.text = user.department;
        _selectedDepartment = user.department;
        _selectedDateOfBirth = user.dateOfBirth;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'department': _selectedDepartment ?? _departmentController.text.trim(),
        'dateOfBirth': _selectedDateOfBirth,
      };

      await ref.read(userProfileProvider.notifier).updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() => _selectedDateOfBirth = picked);
    }
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
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _showLogoutDialog),
          IconButton(
            tooltip: 'Save',
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(child: Text('Error loading profile: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: user.profileImageUrl?.isNotEmpty ?? false
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl?.isEmpty ?? true
                              ? Icon(Icons.person, size: 50, color: Colors.grey.shade600)
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
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Image upload coming soon!')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Personal Info
                  _sectionHeader('Personal Information'),
                  _formField(_nameController, 'Full Name', Icons.person, validator: _required),
                  _formField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                  _formField(_addressController, 'Address', Icons.location_on, maxLines: 2),

                  _datePickerField(
                    label: 'Date of Birth',
                    icon: Icons.calendar_today,
                    date: _selectedDateOfBirth,
                    onTap: _selectDateOfBirth,
                  ),

                  const SizedBox(height: 24),

                  // Academic Info
                  _sectionHeader('Academic Information'),
                  _formField(_studentIdController, 'Student ID', Icons.badge, validator: _required),

                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: _departments.map((dep) => DropdownMenuItem(value: dep, child: Text(dep))).toList(),
                    onChanged: (value) => setState(() => _selectedDepartment = value),
                    validator: (value) => value == null || value.isEmpty ? 'Please select your department' : null,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const Divider(height: 40),

                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _formField(TextEditingController controller, String label, IconData icon,
      {String? Function(String?)? validator, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          child: Text(
            date != null ? date.toLocal().toString().split(' ')[0] : 'Select date of birth',
            style: TextStyle(
              color: date != null ? Colors.black87 : Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }
}
