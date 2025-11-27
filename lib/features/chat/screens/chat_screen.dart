import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(UserModel user) async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _sending = true);

    await MessageService.instance.sendTextMessage(
      groupId: widget.groupId,
      text: _controller.text.trim(),
      senderName: user.fullName,
      senderRole: user.role,
    );

    _controller.clear();
    setState(() => _sending = false);

    // Scroll to bottom after sending
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  bool _isMyMessage(MessageModel msg, String uid) => msg.senderId == uid;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      // try loading once
      Provider.of<UserProvider>(context, listen: false).loadUser();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    // if (user == null) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user.role == "officer")
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () {
                // Broadcast UI later
              },
            ),

          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show Group Details UI later
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessageService.instance.streamGroupMessages(widget.groupId),
              builder: (context, snapshot) {

                if (snapshot.hasError) {

                  print("Error: ${snapshot.error}",);

                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Text(
                      "Starting secure channel...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }


                // if (!snapshot.hasData) {
                //   return const Center(child: Text("Starting secure channel..."));
                // }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text("No messages yet.", style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final bool mine = _isMyMessage(msg, user.userId);

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.accent.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: mine
                              ? Border.all(color: AppColors.accent)
                              : Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                msg.senderName,
                                style: const TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                            Text(
                              msg.content ?? "",
                              style: const TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.9),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.accent),
                  onPressed: () => _sendMessage(user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
