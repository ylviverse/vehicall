import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MessagePage extends StatefulWidget {
  final String? initialMessage;
  final String? recipientId;
  final String? recipientName;
  final String? postTitle;

  const MessagePage({
    super.key,
    this.initialMessage,
    this.recipientId,
    this.recipientName,
    this.postTitle,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final List<MessageItem> _messages = [];
  final List<Conversation> _conversations = [];
  final _supabase = Supabase.instance.client;
  String _recipientName = '';
  String? _recipientId;
  String? _currentUserId;
  String _currentUserName = ''; // Actual user name, not "You"
  bool _isLoading = true;
  bool _isLoadingConversations = true;
  String? _errorMessage;
  RealtimeChannel? _messagesSubscription;
  bool _isSending = false;
  bool _hasValidRecipient = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;

    // Get current user's name
    _getCurrentUserName();

    // Always load conversations first
    _loadConversations();

    // If we have a recipient from widget parameters, initialize that chat too
    if (widget.recipientId != null && widget.recipientId!.isNotEmpty) {
      _recipientId = widget.recipientId;
      _recipientName = widget.recipientName ?? '';
      _hasValidRecipient = true;

      // If recipient name is empty, try to fetch it
      if (_recipientName.isEmpty) {
        _fetchRecipientName();
      }

      _initializeChat();
    }

    print('MessagePage initialized with:');
    print('Current user ID: $_currentUserId');
    print('Current user name: $_currentUserName');
    print('Recipient ID: $_recipientId');
    print('Recipient name: $_recipientName');
    print('Has valid recipient: $_hasValidRecipient');
  }

  // Get current user's name for sending messages
  Future<void> _getCurrentUserName() async {
    if (_currentUserId == null) return;

    try {
      // First try to get name from posts table
      print('Trying to get current user name from posts table');
      final postsData =
          await _supabase
              .from('posts')
              .select('user_name')
              .eq('user_id', _currentUserId)
              .limit(1)
              .maybeSingle();

      if (postsData != null &&
          postsData['user_name'] != null &&
          postsData['user_name'].toString().isNotEmpty) {
        _currentUserName = postsData['user_name'];
        print('Found current user name in posts: $_currentUserName');
        return;
      }

      // If not found in posts, try profiles table
      print('Trying to get current user name from profiles table');
      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', _currentUserId)
              .maybeSingle();

      if (profileData != null) {
        if (profileData['full_name'] != null &&
            profileData['full_name'].toString().isNotEmpty) {
          _currentUserName = profileData['full_name'];
          print('Found current user name in profiles: $_currentUserName');
        } else if (profileData['email'] != null) {
          _currentUserName = profileData['email'].toString().split('@')[0];
          print('Using email from profile: $_currentUserName');
        }
      } else {
        // Try to get email from auth
        final user = _supabase.auth.currentUser;
        if (user?.email != null) {
          _currentUserName = user!.email!.split('@')[0];
          print('Using email from auth: $_currentUserName');
        } else {
          // Last resort - use user ID
          _currentUserName = 'User ${_currentUserId!.substring(0, 4)}';
          print('Using user ID as name: $_currentUserName');
        }
      }
    } catch (e) {
      print('Error getting current user name: $e');
      // Use user ID as fallback
      _currentUserName = 'User ${_currentUserId!.substring(0, 4)}';
    }
  }

  Future<void> _fetchRecipientName() async {
    if (_recipientId == null || _recipientId!.isEmpty) return;

    print('Fetching name for recipient ID: $_recipientId');

    try {
      // First try to get the name from the posts table
      print('Trying to get recipient name from posts table');
      final postsData =
          await _supabase
              .from('posts')
              .select('user_name')
              .eq('user_id', _recipientId)
              .limit(1)
              .maybeSingle();

      if (postsData != null &&
          postsData['user_name'] != null &&
          postsData['user_name'].toString().isNotEmpty) {
        setState(() {
          _recipientName = postsData['user_name'];
        });
        print('Found recipient name in posts: $_recipientName');
        return;
      }

      // If not found in posts, try profiles table
      print('Trying to get recipient name from profiles table');
      final profileData =
          await _supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', _recipientId)
              .maybeSingle();

      if (profileData != null) {
        setState(() {
          if (profileData['full_name'] != null &&
              profileData['full_name'].toString().isNotEmpty) {
            _recipientName = profileData['full_name'];
            print('Found recipient name in profiles: $_recipientName');
          } else if (profileData['email'] != null) {
            _recipientName = profileData['email'].toString().split('@')[0];
            print('Using email from profile: $_recipientName');
          } else {
            _recipientName = 'User ${_recipientId!.substring(0, 4)}';
            print('No name found in profile, using default: $_recipientName');
          }
        });
      } else {
        // If no profile, use a default with part of the ID
        setState(() {
          _recipientName = 'User ${_recipientId!.substring(0, 4)}';
        });
        print('No profile found, using default: $_recipientName');
      }
    } catch (e) {
      print('Error fetching recipient name: $e');
      setState(() {
        _recipientName = 'User ${_recipientId!.substring(0, 4)}';
      });
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify we have the necessary data
      if (_currentUserId == null) {
        throw Exception('You must be logged in to send messages');
      }

      if (_recipientId == null) {
        throw Exception('Recipient not specified');
      }

      // Load existing messages
      await _loadExistingMessages();

      // Set up real-time subscription for new messages
      _setupMessageSubscription();

      // If there's an initial message, send it
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        await _sendMessage(widget.initialMessage!, false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoadingConversations = false;
        _errorMessage = 'You must be logged in to view messages';
      });
      return;
    }

    setState(() {
      _isLoadingConversations = true;
      _errorMessage = null;
    });

    try {
      // Get all messages where the current user is either sender or receiver
      final response = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.${_currentUserId},receiver_id.eq.${_currentUserId}')
          .order('created_at', ascending: false);

      print('Loaded ${response.length} messages for conversations');

      // Process the messages to create a list of unique conversations
      final Map<String, Conversation> conversationsMap = {};

      for (final message in response) {
        final bool isFromUser = message['sender_id'] == _currentUserId;
        final String otherUserId =
            isFromUser ? message['receiver_id'] : message['sender_id'];

        // Skip if we already processed this conversation
        if (conversationsMap.containsKey(otherUserId)) continue;

        // Get the other user's name from the message
        String userName;
        if (isFromUser) {
          // This is a message we sent, so use receiver_name
          userName =
              message['receiver_name'] ?? 'User ${otherUserId.substring(0, 4)}';
        } else {
          // This is a message we received, so use sender_name
          userName =
              message['sender_name'] ?? 'User ${otherUserId.substring(0, 4)}';
        }

        // Add the conversation
        conversationsMap[otherUserId] = Conversation(
          userId: otherUserId,
          userName: userName,
          lastMessage: message['content'],
          lastMessageTime: DateTime.parse(message['created_at']),
          unread: !isFromUser && message['is_read'] == false,
        );
      }

      setState(() {
        _conversations.clear();
        _conversations.addAll(conversationsMap.values.toList());
        _isLoadingConversations = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _errorMessage = 'Failed to load conversations: ${e.toString()}';
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _loadExistingMessages() async {
    try {
      // Query messages between the current user and recipient
      final response = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.${_currentUserId},receiver_id.eq.${_currentUserId}')
          .or('sender_id.eq.${_recipientId},receiver_id.eq.${_recipientId}')
          .order('created_at', ascending: true);

      print('Loaded ${response.length} messages for current chat');

      // Convert to MessageItem objects
      final messages =
          response.map<MessageItem>((message) {
            final senderId = message['sender_id'];
            final isFromUser = senderId == _currentUserId;

            // Get sender name from the message
            String senderName;
            if (isFromUser) {
              // For messages from the current user, display "You" in the UI
              senderName = "You";
            } else {
              // For messages from the other user, use sender_name from the message
              senderName = message['sender_name'] ?? _recipientName;
              if (senderName.isEmpty) {
                senderName = 'User ${senderId.substring(0, 4)}';
              }
            }

            return MessageItem(
              id: message['id'],
              message: message['content'],
              isFromUser: isFromUser,
              timestamp: DateTime.parse(message['created_at']),
              senderName: senderName,
            );
          }).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } catch (e) {
      print('Error loading messages: $e');
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  void _setupMessageSubscription() {
    // Remove any existing subscription
    if (_messagesSubscription != null) {
      _supabase.removeChannel(_messagesSubscription!);
      _messagesSubscription = null;
    }

    // Create a unique channel name for this chat
    final channelName = 'messages_${_currentUserId}_${_recipientId}';

    try {
      // Subscribe to the messages table for real-time updates
      final channel = _supabase.channel(channelName);

      channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages'),
        (payload, [ref]) async {
          // Check if the message is relevant to this chat
          final senderId = payload['new']['sender_id'];
          final receiverId = payload['new']['receiver_id'];

          if ((senderId == _currentUserId && receiverId == _recipientId) ||
              (senderId == _recipientId && receiverId == _currentUserId)) {
            // Get sender name from the message
            String senderName;
            if (senderId == _currentUserId) {
              // For messages from the current user, display "You" in the UI
              senderName = "You";
            } else {
              // For messages from the other user, use sender_name from the message
              senderName = payload['new']['sender_name'] ?? _recipientName;
              if (senderName.isEmpty) {
                senderName = 'User ${senderId.substring(0, 4)}';
              }
            }

            // Add the new message to the list
            final newMessage = MessageItem(
              id: payload['new']['id'],
              message: payload['new']['content'],
              isFromUser: senderId == _currentUserId,
              timestamp: DateTime.parse(payload['new']['created_at']),
              senderName: senderName,
            );

            if (mounted) {
              setState(() {
                _messages.add(newMessage);
              });

              // Scroll to the bottom
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          }
        },
      );

      channel.subscribe();
      _messagesSubscription = channel;
    } catch (e) {
      print('Error setting up subscription: $e');
      // Don't throw an exception here, just log the error
    }
  }

  Future<void> _sendMessage(String message, bool scrollToBottom) async {
    if (message.trim().isEmpty) return;

    try {
      // Insert the message into the database with actual sender and receiver names
      // NOT using "You" in the database
      final response =
          await _supabase.from('messages').insert({
            'sender_id': _currentUserId,
            'receiver_id': _recipientId,
            'content': message,
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
            'sender_name': _currentUserName, // Store actual name, not "You"
            'receiver_name': _recipientName,
          }).select();

      print(
        'Message sent with sender_name: $_currentUserName and receiver_name: $_recipientName',
      );

      // The message will be added to the UI via the real-time subscription

      if (scrollToBottom) {
        // Scroll to the bottom after the message is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openConversation(Conversation conversation) {
    // Clean up any active chat subscriptions
    if (_messagesSubscription != null) {
      _supabase.removeChannel(_messagesSubscription!);
      _messagesSubscription = null;
    }

    setState(() {
      _recipientId = conversation.userId;
      _recipientName = conversation.userName;
      _hasValidRecipient = true;
      _messages.clear();
      _isLoading = true;
    });

    _initializeChat();
  }

  void _handleSendPressed() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text;
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await _sendMessage(messageText, true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _hasValidRecipient
                ? Text(
                  _recipientName,
                  style: const TextStyle(color: Color(0xFF123458)),
                )
                : const Text(
                  'Messages',
                  style: TextStyle(color: Color(0xFF123458)),
                ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF123458)),
        // Add back button when in a conversation, but not on the main message page
        leading:
            _hasValidRecipient
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Return to conversation list
                    setState(() {
                      _hasValidRecipient = false;
                      _recipientId = null;
                      _recipientName = '';
                      if (_messagesSubscription != null) {
                        _supabase.removeChannel(_messagesSubscription!);
                        _messagesSubscription = null;
                      }
                    });
                  },
                )
                : null,
        automaticallyImplyLeading: false, // Never show the default back button
      ),
      body: Column(
        children: [
          // Error message if any
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),

          // Main content area
          Expanded(
            child:
                _hasValidRecipient
                    ? _buildChatView()
                    : _buildConversationList(),
          ),

          // Message input - only show if we have a valid recipient
          if (_hasValidRecipient)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSendPressed(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF123458),
                    child: IconButton(
                      icon:
                          _isSending
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.send, color: Colors.white),
                      onPressed: _handleSendPressed,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Widget to display the list of conversations
  Widget _buildConversationList() {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Start a conversation by messaging a post owner',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF123458),
            child: Text(
              conversation.userName.isNotEmpty
                  ? conversation.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.userName,
                  style: TextStyle(
                    fontWeight:
                        conversation.unread
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                _formatTimestamp(conversation.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight:
                      conversation.unread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Text(
            conversation.lastMessage ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight:
                  conversation.unread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing:
              conversation.unread
                  ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF123458),
                      shape: BoxShape.circle,
                    ),
                  )
                  : const Icon(Icons.chevron_right),
          onTap: () => _openConversation(conversation),
        );
      },
    );
  }

  // Update the _buildChatView method to pass sender name to MessageBubble
  Widget _buildChatView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No messages yet with $_recipientName',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      reverse:
          false, // Keep normal order since we're already sorting by ascending time
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(
          message: message.message,
          isFromUser: message.isFromUser,
          timestamp: message.timestamp,
          senderName: message.senderName,
        );
      },
    );
  }

  // Helper method to format timestamps
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // Return day of week for dates within the last week
      switch (timestamp.weekday) {
        case 1:
          return 'Monday';
        case 2:
          return 'Tuesday';
        case 3:
          return 'Wednesday';
        case 4:
          return 'Thursday';
        case 5:
          return 'Friday';
        case 6:
          return 'Saturday';
        case 7:
          return 'Sunday';
        default:
          return '';
      }
    } else {
      // Return date for older messages
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_messagesSubscription != null) {
      print('Removing message subscription');
      _supabase.removeChannel(_messagesSubscription!);
      _messagesSubscription = null;
    }
    _scrollController.dispose();
    super.dispose();
  }
}

// Update the MessageItem class to include sender name
class MessageItem {
  final int? id;
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final String senderName;

  MessageItem({
    this.id,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    this.senderName = '',
  });
}

class Conversation {
  final String userId;
  final String userName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? postTitle;
  final bool unread;

  Conversation({
    required this.userId,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.postTitle,
    this.unread = false,
  });
}

// Update the MessageBubble widget to display sender name
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final String senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    this.senderName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Show sender name for all messages
        if (senderName.isNotEmpty)
          Align(
            alignment:
                isFromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: isFromUser ? 0 : 8.0,
                right: isFromUser ? 8.0 : 0,
                bottom: 2.0,
              ),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        Align(
          alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isFromUser ? const Color(0xFF123458) : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isFromUser ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isFromUser ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
