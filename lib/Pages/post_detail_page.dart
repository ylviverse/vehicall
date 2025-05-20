import 'package:flutter/material.dart';
import 'package:VehiCall/model/post.dart';
import 'package:VehiCall/components/post_message_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post.title ?? 'Post Details',
          style: const TextStyle(color: Color(0xFF123458)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF123458)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post image
            Container(
              height: MediaQuery.of(context).size.width * 0.7,
              width: double.infinity,
              color: Colors.grey[200],
              child:
                  widget.post.imageUrl.isNotEmpty
                      ? Image.network(
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
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
            ),

            // Post details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.post.title ?? 'Untitled Post',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        widget.post.price ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF123458),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // User info and post date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF123458),
                        child: Text(
                          widget.post.userName.isNotEmpty
                              ? widget.post.userName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Posted ${timeago.format(widget.post.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 32),

                  // Message input (only show if not the current user's post)
                  if (!_isCurrentUserPost)
                    PostMessageInput(
                      recipientId: widget.post.userId,
                      recipientName: widget.post.userName,
                      postTitle: widget.post.title,
                      onMessageSent: ({String? name}) {
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

                  // Show "This is your post" message if it's the current user's post
                  if (_isCurrentUserPost)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'This is your post. Other users can message you about it.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
