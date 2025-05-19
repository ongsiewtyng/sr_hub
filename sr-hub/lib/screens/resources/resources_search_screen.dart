// lib/screens/resources/resource_search_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/resource_card.dart';
import '../../widgets/search_bar.dart';
import '../../data/sample_data.dart';

class ResourceSearchScreen extends StatefulWidget {
  const ResourceSearchScreen({Key? key}) : super(key: key);

  @override
  State<ResourceSearchScreen> createState() => _ResourceSearchScreenState();
}

class _ResourceSearchScreenState extends State<ResourceSearchScreen> {
  final resources = SampleData.getResources();
  String _selectedResourceType = 'all';
  String _selectedSubject = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Resources',
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          const CustomSearchBar(
            hintText: 'Search for resources',
          ),

          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Resource type filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedResourceType,
                    decoration: const InputDecoration(
                      labelText: 'Resource Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedResourceType = value;
                      });
                    },
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('All Types'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'article',
                        child: Text('Article'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'video',
                        child: Text('Video'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'document',
                        child: Text('Document'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'dataset',
                        child: Text('Dataset'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Subject filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('All Subjects'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Computer Science',
                        child: Text('Computer Science'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Design',
                        child: Text('Design'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Statistics',
                        child: Text('Statistics'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${resources.length} results found',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: ListView.builder(
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return ResourceCard(
                  resource: resource,
                  onTap: () {},
                  onSave: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}