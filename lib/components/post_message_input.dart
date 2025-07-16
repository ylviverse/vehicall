import 'package:flutter/material.dart';
import 'package:VehiCall/utils/error_handler.dart';
import 'package:VehiCall/utils/validators.dart';
import 'package:VehiCall/config/app_config.dart';
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
  String _senderName = '';

  @override
  void initState() {
    super.initState();
    if (widget.postTitle != null && widget.postTitle!.isNotEmpty) {
      _messageController.text =
          "Hello, is your ${widget.postTitle} still available?";
    } else {
      _messageController.text = "Hello, is this still available?";
    }

    _getCurrentUserName();

    if (widget.recipientName.isEmpty || widget.recipientName == "User") {
      _fetchRecipientName();
    }
  }

  Future<void> _getCurrentUserName() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
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
        return;
      }

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
        } else if (profileData['email'] != null) {
          _senderName = profileData['email'].toString().split('@')[0];
        }
      } else {
        final user = _supabase.auth.currentUser;
        if (user?.email != null) {
          _senderName = user!.email!.split('@')[0];
        } else {
          _senderName = 'User ${currentUserId.substring(0, 4)}';
        }
      }
    } catch (e) {
      _senderName = 'User ${currentUserId.substring(0, 4)}';
    }
  }

  Future<void> _fetchRecipientName() async {
    try {
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

        if (mounted && name != "User") {
          if (widget.onMessageSent != null) {
            widget.onMessageSent!(name: name);
          }
        }
        return;
      }

      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', widget.recipientId)
              .maybeSingle();

      String name = "User";

      if (profileData != null) {
        if (profileData['full_name'] != null &&
            profileData['full_name'].toString().isNotEmpty) {
          name = profileData['full_name'];
        } else if (profileData['email'] != null) {
          name = profileData['email'].toString().split('@')[0];
        }
      }

      if (mounted && name != "User") {
        if (widget.onMessageSent != null) {
          widget.onMessageSent!(name: name);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    // Validate message
    final validationError = Validators.validateMessage(messageText);
    if (validationError != null) {
      ErrorHandler.showErrorSnackBar(context, validationError);
      return;
    }

    if (_isSending) return;

    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'You must be logged in to send messages',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _supabase.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.recipientId,
        'content': messageText,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'sender_name': _senderName,
        'receiver_name': widget.recipientName,
      });

      _messageController.clear();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Message sent to ${widget.recipientName}',
        );
      }

      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to send message');
      }
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFF123458),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  maxLength: AppConfig.maxMessageLength,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
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
