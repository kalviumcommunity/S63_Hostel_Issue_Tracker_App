import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';

class IssueChatScreen extends StatefulWidget {
  final String issueId;
  const IssueChatScreen({super.key, required this.issueId});

  @override
  State<IssueChatScreen> createState() => _IssueChatScreenState();
}

class _IssueChatScreenState extends State<IssueChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late Stream<List<MessageModel>> _messageStream;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.getMessagesStream(widget.issueId);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String currentUserId, String currentUserName, bool isAdmin) async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() => _isSending = true);
    
    await _chatService.sendMessage(
      issueId: widget.issueId,
      text: text,
      senderId: currentUserId,
      senderName: currentUserName,
      isAdmin: isAdmin,
    );

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    // Select only specific fields to avoid rebuilds when 'updatedAt' changes
    final user = context.select<AuthProvider, UserModel?>((auth) => auth.userModel);
    final issueTitle = context.select<IssueProvider, String?>((p) => p.getById(widget.issueId)?.title);
    final issueStatus = context.select<IssueProvider, String?>((p) => p.getById(widget.issueId)?.status);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issueTitle ?? 'Chat', 
              style: const TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (issueStatus != null) 
              Text(
                'Status: ${issueStatus.toUpperCase()}',
                style: TextStyle(
                  color: issueStatus == statusResolved ? const Color(0xFF10B981) : const Color(0xFF6B7280), 
                  fontSize: 12, 
                  fontWeight: FontWeight.w700
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat List
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _messageStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Color(0xFF6B7280))));
                  }
                  
                  final messages = snapshot.data ?? [];
                  
                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_rounded, size: 60, color: Color(0xFFE5E7EB)),
                          SizedBox(height: 16),
                          Text('No messages yet', style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Text('Start the conversation about this issue.', style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    reverse: true, // Auto scroll to bottom
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = user?.uid == message.senderId;
                      // Determine if it was sent by admin but I am not admin, or vice versa
                      
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) {
                          if (user != null) {
                            _sendMessage(user.uid, user.name, user.role == 'admin');
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (user != null && !_isSending) {
                        _sendMessage(user.uid, user.name, user.role == 'admin');
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: _isSending 
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isAdmin ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF3ECFCF).withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: message.isAdmin ? const Color(0xFFEF4444) : const Color(0xFF3ECFCF),
                  fontWeight: FontWeight.w800,
                  fontSize: 14
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: isMe ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [
                  BoxShadow(
                    color: const Color(0xFF111827).withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName, 
                      style: TextStyle(
                        color: message.isAdmin ? const Color(0xFFEF4444) : const Color(0xFF6B7280), 
                        fontWeight: FontWeight.w800, 
                        fontSize: 12,
                        letterSpacing: message.isAdmin ? 0.5 : 0,
                      )
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF111827),
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 32), // Spacer to avoid filling full width if me
          if (!isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }
}
