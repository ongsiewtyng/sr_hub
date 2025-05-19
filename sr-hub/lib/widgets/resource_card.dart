// lib/widgets/resource_card.dart
import 'package:flutter/material.dart';
import '../models/resource_model.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool compact;

  const ResourceCard({
    Key? key,
    required this.resource,
    required this.onTap,
    this.onSave,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resource type icon or preview image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getResourceTypeColor(resource.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  image: resource.previewImageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(resource.previewImageUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: resource.previewImageUrl == null
                    ? Icon(
                  _getResourceTypeIcon(resource.type),
                  color: _getResourceTypeColor(resource.type),
                  size: 32,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              // Resource details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Type and subject
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getResourceTypeColor(resource.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource.type.toUpperCase(),
                            style: TextStyle(
                              color: _getResourceTypeColor(resource.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resource.subject,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        resource.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Stats and save button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stats
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resource.viewCount.toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (resource.downloadCount > 0) ...[
                              Icon(
                                Icons.download,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                resource.downloadCount.toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Save button
                        if (onSave != null)
                          IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            onPressed: onSave,
                            color: Theme.of(context).primaryColor,
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResourceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'document':
        return Colors.green;
      case 'dataset':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.video_library;
      case 'document':
        return Icons.description;
      case 'dataset':
        return Icons.data_array;
      default:
        return Icons.file_copy;
    }
  }
}