import 'package:flutter/material.dart';
import 'package:VehiCall/model/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:VehiCall/model/fav.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:VehiCall/Pages/message_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:VehiCall/components/post_message_input.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final Function? onDelete;
  final VoidCallback? onMessageTap; // Add this new callback

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onDelete,
    this.onMessageTap, // Add this parameter
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _supabase = Supabase.instance.client;
  bool _isCurrentUserPost = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null && currentUser.id == widget.post.userId) {
      setState(() {
        _isCurrentUserPost = true;
      });
    }
  }

  void _contactPoster() {
    // Check if we have the necessary information
    if (widget.post.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot contact this user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show a bottom sheet with the message input
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message ${widget.post.userName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PostMessageInput(
                    recipientId: widget.post.userId,
                    recipientName: widget.post.userName,
                    postTitle: widget.post.title,
                    onMessageSent: ({String? name}) {
                      // Close the bottom sheet
                      Navigator.pop(context);

                      // If we got an updated name, show a snackbar with the correct name
                      if (name != null && name != widget.post.userName) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message sent to $name'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width:
            MediaQuery.of(context).size.width *
            0.85, // Change from fixed 300 to responsive width
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with user info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF123458),
                    child: Text(
                      widget.post.userName.isNotEmpty
                          ? widget.post.userName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeago.format(widget.post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isCurrentUserPost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Your Post',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Post image
            Container(
              height:
                  MediaQuery.of(context).size.width *
                  0.4, // Responsive height based on screen width
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: _buildImageWidget(),
            ),

            // Post description
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.post.description,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // Car title and price row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title (styled like Vios)
                  Expanded(
                    child: Text(
                      widget.post.title ?? widget.post.userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      // Message button
                      if (!_isCurrentUserPost)
                        IconButton(
                          icon: const Icon(Icons.message_outlined),
                          onPressed: _contactPoster,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                      const SizedBox(width: 8),

                      // Delete button (only for user's own posts)
                      if (_isCurrentUserPost && widget.onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => widget.onDelete!(),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                      if (_isCurrentUserPost) const SizedBox(width: 8),

                      // Favorite button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white),
                          onPressed: () {},
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price (styled like 1400 / day)
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                bottom: 12.0,
              ),
              child: Text(
                widget.post.price ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build the image widget with proper error handling
  Widget _buildImageWidget() {
    // Print the image URL for debugging
    print('Loading image from URL: ${widget.post.imageUrl}');

    // Check if the URL is empty
    if (widget.post.imageUrl.isEmpty) {
      return _buildPlaceholderImage('No image available');
    }

    // Try to load the image directly with Image.network for simplicity
    return Image.network(
      widget.post.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
            color: const Color(0xFF123458),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return _buildPlaceholderImage('Image not available');
      },
    );
  }

  // Helper method for placeholder images
  Widget _buildPlaceholderImage(String message) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
