import 'package:flutter/material.dart';
import 'package:VehiCall/model/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:VehiCall/components/post_message_input.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final Function? onDelete;

  const PostCard({super.key, required this.post, this.onTap, this.onDelete});

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
    if (widget.post.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot contact this user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
                      Navigator.pop(context);
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
        width: MediaQuery.of(context).size.width * 0.85,
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
          mainAxisSize: MainAxisSize.min,
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
              height: MediaQuery.of(context).size.width * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: _buildImageWidget(),
            ),

            // Post description
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.post.description ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

  

            // Car title and price row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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

                  Row(
                    children: [
                      if (!_isCurrentUserPost)
                        IconButton(
                          icon: const Icon(Icons.message_outlined),
                          onPressed: _contactPoster,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                      const SizedBox(width: 8),

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
                    ],
                  ),
                ],
              ),
            ),

            // Price
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

  Widget _buildImageWidget() {
    if (widget.post.imageUrl.isEmpty) {
      return _buildPlaceholderImage('No image available');
    }

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
        return _buildPlaceholderImage('Image not available');
      },
    );
  }

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
