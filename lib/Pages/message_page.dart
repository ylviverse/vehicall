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
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _currentUserId;
  String _currentUserName = '';
  String? _recipientId;
  String _recipientName = '';
  bool _hasValidRecipient = false;

  bool _isLoading = true;
  bool _isLoadingConversations = true;
  String? _errorMessage;
  bool _isSending = false;

  List<Conversation> _conversations = [];
  List<MessageItem> _messages = [];
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _recipientId = widget.recipientId;
    _recipientName = widget.recipientName ?? '';

    _fetchCurrentUserName();
    _loadConversations();

    if (_recipientId != null && _recipientId!.isNotEmpty) {
      _hasValidRecipient = true;
      if (_recipientName.isEmpty) _fetchRecipientName();
      _initializeChat();
    }
  }

  Future<void> _fetchCurrentUserName() async {
    if (_currentUserId == null) return;
    try {
      final post = await _supabase
          .from('posts')
          .select('user_name')
          .eq('user_id', _currentUserId!)
          .limit(1)
          .maybeSingle();
      if (post != null && post['user_name'] != null) {
        _currentUserName = post['user_name'];
        return;
      }
      final profile = await _supabase
          .from('profiles')
          .select('full_name, email')
          .eq('id', _currentUserId!)
          .maybeSingle();
      if (profile != null) {
        if ((profile['full_name'] as String?)?.isNotEmpty == true) {
          _currentUserName = profile['full_name'];
        } else if (profile['email'] != null) {
          _currentUserName = (profile['email'] as String).split('@')[0];
        }
      }
    } catch (_) {
      _currentUserName = 'User ${_currentUserId!.substring(0, 4)}';
    }
  }

  Future<void> _fetchRecipientName() async {
    if (_recipientId == null) return;
    try {
      final post = await _supabase
          .from('posts')
          .select('user_name')
          .eq('user_id', _recipientId!)
          .limit(1)
          .maybeSingle();
      if (post != null && post['user_name'] != null) {
        setState(() => _recipientName = post['user_name']);
        return;
      }
      final profile = await _supabase
          .from('profiles')
          .select('full_name, email')
          .eq('id', _recipientId!)
          .maybeSingle();
      if (profile != null) {
        setState(() {
          if ((profile['full_name'] as String?)?.isNotEmpty == true) {
            _recipientName = profile['full_name'];
          } else if (profile['email'] != null) {
            _recipientName = (profile['email'] as String).split('@')[0];
          } else {
            _recipientName = 'User ${_recipientId!.substring(0, 4)}';
          }
        });
      }
    } catch (_) {
      setState(() => _recipientName = 'User ${_recipientId!.substring(0, 4)}');
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() {
        _errorMessage = 'Not authenticated';
        _isLoadingConversations = false;
      });
      return;
    }
    setState(() {
      _isLoadingConversations = true;
      _errorMessage = null;
    });
    try {
      final raw = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId')
          .order('created_at', ascending: false);
      final rows = (raw as List).cast<Map<String, dynamic>>();
      final map = <String, Conversation>{};
      for (var msg in rows) {
        final fromMe = msg['sender_id'] == _currentUserId;
        final other = fromMe ? msg['receiver_id'] : msg['sender_id'];
        if (map.containsKey(other)) continue;
        final nameField = fromMe ? msg['receiver_name'] : msg['sender_name'];
        map[other] = Conversation(
          userId: other,
          userName: nameField ?? 'User ${other.substring(0,4)}',
          lastMessage: msg['content'] ?? '',
          lastMessageTime: DateTime.parse(msg['created_at']),
          unread: !fromMe && msg['is_read'] == false,
        );
      }
      setState(() {
        _conversations = map.values.toList();
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_currentUserId == null || _recipientId == null) {
        throw Exception('Missing chat participants');
      }
      await _loadExistingMessages();
      _subscribeRealtime();
      if (widget.initialMessage?.isNotEmpty == true) {
        await _sendMessage(widget.initialMessage!, false);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingMessages() async {
    final raw = await _supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$_currentUserId,receiver_id.eq.$_recipientId)'
          ',and(sender_id.eq.$_recipientId,receiver_id.eq.$_currentUserId)'
        )
        .order('created_at', ascending: true);
    final rows = (raw as List).cast<Map<String, dynamic>>();
    final msgs = rows.map((m) {
      final fromMe = m['sender_id'] == _currentUserId;
      return MessageItem(
        id: m['id'],
        message: m['content'] ?? '',
        isFromUser: fromMe,
        timestamp: DateTime.parse(m['created_at']),
        senderName: fromMe ? 'You' : (m['sender_name'] ?? _recipientName),
      );
    }).toList();
    setState(() => _messages = msgs);
  }

  void _subscribeRealtime() {
  if (_subscription != null) {
    _supabase.removeChannel(_subscription!);
    _subscription = null;
  }
  
  final name = 'chat_${_currentUserId}_${_recipientId}';
  final channel = _supabase.channel(name);
  
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    callback: (payload) {
      try {
        final m = payload.newRecord;
        final fromMe = m['sender_id'] == _currentUserId;
        final rec = m['receiver_id'];
        
        if ((fromMe && rec == _recipientId) ||
            (!fromMe && m['sender_id'] == _recipientId)) {
          final item = MessageItem(
            id: m['id'],
            message: m['content'] ?? '',
            isFromUser: fromMe,
            timestamp: DateTime.parse(m['created_at']),
            senderName: fromMe ? 'You' : (m['sender_name'] ?? _recipientName),
          );
          
          if (mounted) {
            setState(() => _messages.add(item));
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
        }
      } catch (e) {
        print('Error processing real-time message: $e');
      }
    },
  );
  
  channel.subscribe();
  _subscription = channel;
}

  Future<void> _sendMessage(String text, bool scroll) async {
    if (text.trim().isEmpty) return;
    if (_currentUserId == null || _recipientId == null) return;
    
    setState(() => _isSending = true);
    
    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': _recipientId,
        'content': text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'sender_name': _currentUserName,
        'receiver_name': _recipientName,
      });
      
      // Clear the message input after successful send
      _messageController.clear();
      
      if (scroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _openConversation(Conversation c) {
    // Clean up existing subscription
    if (_subscription != null) {
      _supabase.removeChannel(_subscription!);
      _subscription = null;
    }
    
    setState(() {
      _recipientId = c.userId;
      _recipientName = c.userName;
      _hasValidRecipient = true;
      _messages.clear();
      _isLoading = true;
    });
    _initializeChat();
  }

  void _handleSendMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty && !_isSending) {
      _sendMessage(text, true);
    }
  }

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_subscription != null) {
      _supabase.removeChannel(_subscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF123458)),
        title: Text(
          _hasValidRecipient ? _recipientName : 'Messages',
          style: const TextStyle(color: Color(0xFF123458)),
        ),
        leading: _hasValidRecipient
            ? BackButton(
                color: const Color(0xFF123458),
                onPressed: () {
                  if (_subscription != null) {
                    _supabase.removeChannel(_subscription!);
                    _subscription = null;
                  }
                  setState(() {
                    _hasValidRecipient = false;
                    _messages.clear();
                  });
                },
              )
            : null,
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _hasValidRecipient ? _buildChatView() : _buildConvoList(),
          ),
          if (_hasValidRecipient) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildConvoList() {
    if (_isLoadingConversations) return const Center(child: CircularProgressIndicator());
    if (_conversations.isEmpty) {
      return const Center(child: Text('No conversations yet'));
    }
    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final c = _conversations[i];
        return ListTile(
          title: Text(c.userName),
          subtitle: Text(c.lastMessage ?? ''),
          trailing: Text(_formatTime(c.lastMessageTime)),
          onTap: () => _openConversation(c),
        );
      },
    );
  }

  Widget _buildChatView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) return Center(child: Text('No messages with $_recipientName'));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => MessageBubble(item: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF123458),
              child: IconButton(
                icon: _isSending 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2,'0');
    final m = dt.minute.toString().padLeft(2,'0');
    return '$h:$m';
  }
}

// Models & Bubble

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
  final bool unread;

  Conversation({
    required this.userId,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.unread = false,
  });
}

class MessageBubble extends StatelessWidget {
  final MessageItem item;
  const MessageBubble({super.key, required this.item});

  @override
  Widget build(BuildContext c) {
    return Align(
      alignment: item.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isFromUser ? const Color(0xFF123458) : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              item.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!item.isFromUser)
              Text(item.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(item.message,
                style: TextStyle(color: item.isFromUser ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(_formatTime(item.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: item.isFromUser ? Colors.white70 : Colors.black54,
                )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime ts) {
    final h = ts.hour.toString().padLeft(2,'0');
    final m = ts.minute.toString().padLeft(2,'0');
    return '$h:$m';
  }
}