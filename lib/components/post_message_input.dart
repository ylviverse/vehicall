import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostMessageInput extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? postTitle;
  final Function? onMessageSent;

  const PostMessageInput({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.postTitle,
    this.onMessageSent,
  });

  @override
  State<PostMessageInput> createState() => _PostMessageInputState();
}

class _PostMessageInputState extends State<PostMessageInput> {
  final TextEditingController _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isSending = false;
  String? _errorMessage;
  String _senderName = 'You'; // Default sender name

  @override
  void initState() {
    super.initState();
    // Pre-fill with a default message if post title is available
    if (widget.postTitle != null && widget.postTitle!.isNotEmpty) {
      _messageController.text =
          "Hello, is your ${widget.postTitle} still available?";
    } else {
      _messageController.text = "Hello, is this still available?";
    }

    // Get current user's name
    _getCurrentUserName();

    // Fetch recipient name if it's empty or just "User"
    if (widget.recipientName.isEmpty || widget.recipientName == "User") {
      _fetchRecipientName();
    }
  }

  // Get current user's name
  Future<void> _getCurrentUserName() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // First try to get name from posts table
      print('Trying to get current user name from posts table');
      final postsData =
          await _supabase
              .from('posts')
              .select('user_name')
              .eq('user_id', currentUserId)
              .limit(1)
              .maybeSingle();

      if (postsData != null &&
          postsData['user_name'] != null &&
          postsData['user_name'].toString().isNotEmpty) {
        _senderName = postsData['user_name'];
        print('Found current user name in posts: $_senderName');
        return;
      }

      // If not found in posts, try profiles table
      print('Trying to get current user name from profiles table');
      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', currentUserId)
              .maybeSingle();

      if (profileData != null) {
        if (profileData['full_name'] != null &&
            profileData['full_name'].toString().isNotEmpty) {
          _senderName = profileData['full_name'];
          print('Found current user name in profiles: $_senderName');
        } else if (profileData['email'] != null) {
          _senderName = profileData['email'].toString().split('@')[0];
          print('Using email from profile: $_senderName');
        }
      } else {
        // Try to get email from auth
        final user = _supabase.auth.currentUser;
        if (user?.email != null) {
          _senderName = user!.email!.split('@')[0];
          print('Using email from auth: $_senderName');
        }
      }
    } catch (e) {
      print('Error getting sender name: $e');
      // Keep default name
    }
  }

  // Add a method to fetch the recipient's name
  Future<void> _fetchRecipientName() async {
    try {
      // First try posts table
      print('Trying to get recipient name from posts table');
      final postsData =
          await _supabase
              .from('posts')
              .select('user_name')
              .eq('user_id', widget.recipientId)
              .limit(1)
              .maybeSingle();

      if (postsData != null &&
          postsData['user_name'] != null &&
          postsData['user_name'].toString().isNotEmpty) {
        String name = postsData['user_name'];
        print('Found recipient name in posts: $name');

        // Update the UI with the fetched name
        if (mounted && name != "User") {
          // Use a callback to update the parent widget with the new name
          if (widget.onMessageSent != null) {
            widget.onMessageSent!(name: name);
          }
        }
        return;
      }

      // If not found in posts, try profiles table
      print('Trying to get recipient name from profiles table');
      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', widget.recipientId)
              .maybeSingle();

      // Default name if profile info is missing
      String name = "User";

      if (profileData != null) {
        // Use full name if available, otherwise use email or a default
        if (profileData['full_name'] != null &&
            profileData['full_name'].toString().isNotEmpty) {
          name = profileData['full_name'];
          print('Found recipient name in profiles: $name');
        } else if (profileData['email'] != null) {
          // Extract username part from email
          name = profileData['email'].toString().split('@')[0];
          print('Using email from profile: $name');
        }
      }

      // Update the UI with the fetched name
      if (mounted && name != "User") {
        // Use a callback to update the parent widget with the new name
        if (widget.onMessageSent != null) {
          widget.onMessageSent!(name: name);
        }
      }
    } catch (e) {
      print('Error fetching recipient name: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text;
    final currentUserId = _supabase.auth.currentUser?.id;

    // Validate user is logged in
    if (currentUserId == null) {
      setState(() {
        _errorMessage = 'You must be logged in to send messages';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // Insert the message into the database with sender and receiver names
      await _supabase.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.recipientId,
        'content': messageText,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'sender_name': _senderName,
        'receiver_name': widget.recipientName,
      });

      print(
        'Message sent with sender_name: $_senderName and receiver_name: ${widget.recipientName}',
      );

      // Clear the message field after successful send
      _messageController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to ${widget.recipientName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call the callback if provided
      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.message, color: Color(0xFF123458)),
              const SizedBox(width: 8),
              Text(
                'Send ${widget.recipientName} a message',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Error message if any
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Message input and send button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              ElevatedButton(
                onPressed: _isSending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123458),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child:
                    _isSending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
