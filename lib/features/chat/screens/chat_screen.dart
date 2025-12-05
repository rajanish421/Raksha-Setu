// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../constants/app_colors.dart';
// import '../../../models/message_model.dart';
// import '../../../models/user_model.dart';
// import '../../../providers/user_provider.dart';
// import '../services/message_service.dart';
//


                       // working code text / doc send but voice not yet
//

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:raksha_setu/features/chat/screens/viewer_screen.dart';
import '../../../constants/app_colors.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../call/screens/voice_call_screen.dart';
import '../../call/services/call_service.dart';
import '../services/message_service.dart';
import '../services/chat_media_service.dart';
import '../services/voice_service.dart';
import '../widgets/voice_player_widget.dart';

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
  final ImagePicker _picker = ImagePicker();

  bool _sending = false;
  bool isRecording = false;
  String? recordedPath;
  String? _lastPeerId;
  String? _lastPeerName;

  String? _lastOpenedCall;




  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }


  // init
  // @override
  // void initState() {
  //   super.initState();
  //
  //   print("----------------------------------------   calling ----------------------------------------------------------------------");
  //
  //   FirebaseFirestore.instance
  //       .collection("active_calls")
  //       .where("groupId", isEqualTo: widget.groupId)
  //       .where("active", isEqualTo: true)
  //       .snapshots()
  //       .listen((event) {
  //     //
  //     // final startedBy = event.docs.first["startedBy"];
  //     // if (startedBy == user.uid) return; // don't popup for own call
  //
  //
  //     if (event.docs.isNotEmpty) {
  //       final callId = event.docs.first["callId"];
  //
  //       // 👇 do not auto join if YOU are the caller
  //       if (mounted && _lastOpenedCall != callId) {
  //         _lastOpenedCall = callId;
  //         _showIncomingCallPopup(callId);
  //       }
  //     }
  //   });
  // }


  // above function
  void _showIncomingCallPopup(String callId) {



    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text("Incoming Secure Call", style: TextStyle(color: Colors.white)),
        content: Text("A group call is active. Join?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Decline", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceCallScreen(callId: callId, isGroup: true),
                ),
              );
            },
            child: Text("Join", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }





  // ---------------- TEXT MESSAGE ----------------
  Future<void> _sendMessage(UserModel user) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    await MessageService.instance.sendTextMessage(
      groupId: widget.groupId,
      text: text,
      senderName: user.fullName,
      senderRole: user.role,
    );

    _controller.clear();
    setState(() => _sending = false);

    await Future.delayed(const Duration(milliseconds: 120));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  bool _isMine(MessageModel msg, String uid) => msg.senderId == uid;

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  // ---------------- ATTACHMENT SHEET ----------------
  void _openAttachmentSheet(UserModel user) {
    final isOfficer = user.role == "officer";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text("Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text("Gallery", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(user);
              },
            ),
            if (isOfficer)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                title: const Text("PDF (Orders / Circulars)",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf(user);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ---------------- PICKERS ----------------
  Future<void> _pickFromCamera(UserModel user) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    await _uploadImage(file, user);
  }

  Future<void> _pickFromGallery(UserModel user) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    await _uploadImage(file, user);
  }

  Future<void> _pickPdf(UserModel user) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    await _uploadDocument(file, user);
  }

  // ---------------- UPLOAD & SEND ATTACHMENTS ----------------
  Future<void> _uploadImage(File file, UserModel user) async {
    try {
      setState(() => _sending = true);

      final url = await ChatMediaService.instance.uploadImage(
        file: file,
        groupId: widget.groupId,
        senderId: user.userId,
      );

      await MessageService.instance.sendImageMessage(
        groupId: widget.groupId,
        imageUrl: url,
        senderName: user.fullName,
        senderRole: user.role,
        fileName: file.uri.pathSegments.last,
        fileSize: await file.length(),
      );
    } catch (e) {
      _showError("Image send failed: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _uploadDocument(File file, UserModel user) async {
    try {
      setState(() => _sending = true);

      final url = await ChatMediaService.instance.uploadDocument(
        file: file,
        groupId: widget.groupId,
        senderId: user.userId,
      );

      await MessageService.instance.sendDocumentMessage(
        groupId: widget.groupId,
        docUrl: url,
        senderName: user.fullName,
        senderRole: user.role,
        fileName: file.uri.pathSegments.last,
        fileSize: await file.length(),
      );
    } catch (e) {
      _showError("Document send failed: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

 // ---------------- BUBBLE UI ----------------
  Widget _buildMessageContent(MessageModel msg, bool mine) {
    switch (msg.type) {
      case MessageType.image:
        if (msg.fileUrl == null) {
          return const Text(
            "[Image unavailable]",
            style: TextStyle(color: Colors.white70),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            msg.fileUrl!,
            width: 230,
            height: 230,
            fit: BoxFit.cover,
          ),
        );

      case MessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.fileName ?? "Secure Document",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 14, color: Colors.white70),
          ],
        );

      // case MessageType.voice:
      //   return GestureDetector(
      //     onTap: () {
      //       // later: voice player
      //     },
      //     child: Row(
      //       mainAxisSize: MainAxisSize.min,
      //       children: const [
      //         Icon(Icons.play_arrow, color: Colors.white, size: 28),
      //         SizedBox(width: 6),
      //         Text("Voice message", style: TextStyle(color: Colors.white)),
      //       ],
      //     ),
      //   );


      case MessageType.voice:
        return VoicePlayerWidget(url: msg.fileUrl!);


      default:
        return Text(
          msg.text ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 15),
        );
    }
  }


  // added
  String? _getReceiverId(List<MessageModel> messages, String myId) {
    for (var m in messages.reversed) { // check latest message first
      if (m.senderId != myId) return m.senderId;
    }
    return null; // if not found yet
  }

  String? _getReceiverName(List<MessageModel> messages, String myId) {
    for (var m in messages.reversed) {
      if (m.senderId != myId) return m.senderName;
    }
    return null;
  }

  Future<void> _openCallSheet({required bool isVideo}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. get group members
    final groupDoc = await FirebaseFirestore.instance
        .collection("groups")
        .doc(widget.groupId)
        .get();

    final groupData = groupDoc.data() ?? {};
    final List<dynamic> membersRaw = groupData["members"] ?? [];
    final List<String> memberIds =
    membersRaw.map((e) => e.toString()).toList();

    final otherIds = memberIds.where((m) => m != uid).toList();

    // 2. get users info for 1-1 list
    QuerySnapshot userSnap = otherIds.isEmpty
        ? await FirebaseFirestore.instance
        .collection("users")
        .where("userId", isEqualTo: "__dummy__") // no result
        .get()
        : await FirebaseFirestore.instance
        .collection("users")
        .where("userId", whereIn: otherIds)
        .get();

    final users =
    userSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  isVideo ? Icons.groups_2 : Icons.group,
                  color: Colors.white,
                ),
                title: Text(
                  isVideo ? "Group video call" : "Group voice call",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isVideo) {
                    CallService.instance.startGroupVideoCall(
                      context: context,
                      groupId: widget.groupId,
                    );
                  } else {
                    CallService.instance.startGroupVoiceCall(
                      context: context,
                      groupId: widget.groupId,
                    );
                  }
                },
              ),
              const Divider(color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  "Call member",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "No other members.",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];
                      final id = u["userId"] as String;
                      final name = (u["fullName"] ?? "Member") as String;

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (isVideo) {
                            CallService.instance.startP2PVideoCall(
                              context: context,
                              groupId: widget.groupId,
                              peerId: id,
                            );
                          } else {
                            CallService.instance.startP2PVoiceCall(
                              context: context,
                              groupId: widget.groupId,
                              peerId: id,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      userProvider.loadUser();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _openCallSheet(isVideo: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _openCallSheet(isVideo: true),
          ),
        ],
      ),



      body: Column(
        children: [
          // -------- MESSAGE LIST --------
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessageService.instance.streamMessages(widget.groupId),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      "Starting Secure Channel...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final messages = snapshot.data!;
                // keep track of last peer for quick 1-1 call
                _lastPeerId = _getReceiverId(messages, user.userId);
                _lastPeerName = _getReceiverName(messages, user.userId);


                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet.",
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final mine = _isMine(msg, user.userId);

                    // 🔹 Mark Seen
                    if (!mine && !msg.seenBy.contains(user.userId)) {
                      MessageService.instance.markSeen(widget.groupId, msg.id);
                    }

                    // 🔹 Mark Delivered
                    if (!msg.deliveredTo.contains(user.userId)) {
                      MessageService.instance.markDelivered(widget.groupId, msg.id);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                        mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.accent.withOpacity(0.18)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: mine
                                    ? AppColors.accent
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    msg.senderName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),

                                const SizedBox(height: 2),




                                GestureDetector(
                                  onTap: () {
                                    if (msg.type == MessageType.image || msg.type == MessageType.document) {

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SecureViewerScreen(
                                            url: msg.fileUrl!,
                                            isImage: msg.type == MessageType.image,
                                            senderName: msg.senderName,
                                            time: msg.createdAt,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: mine ? AppColors.accent.withOpacity(0.25) : Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildMessageContent(msg, mine),
                                  ),
                                ),







                                // _buildMessageContent(msg, mine),

                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(msg.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    if (mine)
                                      Icon(
                                        msg.seenBy.length > 1
                                            ? Icons.done_all
                                            : msg.deliveredTo.length > 1
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 14,
                                        color: msg.seenBy.length > 1
                                            ? Colors.blueAccent
                                            : msg.deliveredTo.length > 1
                                            ? Colors.white70
                                            : Colors.white38,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // -------- INPUT FIELD --------
          // -------- INPUT FIELD + VOICE NOTE --------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white70),
                  onPressed: _sending ? null : () => _openAttachmentSheet(user),
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() {}), // 👈 detects typing
                    decoration: InputDecoration(
                      hintText: isRecording ? "Recording..." : "Type secure message...",
                      hintStyle: TextStyle(
                        color: isRecording ? Colors.red : Colors.white38,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // --- MIC / SEND BUTTON BEHAVIOR 👇 ---
                // GestureDetector(
                //   onLongPressStart: (_) async {
                //     if (_controller.text.isEmpty && !isRecording) {
                //       final ok = await VoiceService.instance.startRecording();
                //       if (ok) {
                //         setState(() => isRecording = true);
                //       }
                //     }
                //   },
                //   onLongPressEnd: (_) async {
                //     if (isRecording) {
                //       setState(() => isRecording = false);
                //       final file = await VoiceService.instance.stopRecording();
                //
                //       if (file != null) {
                //         final url = await ChatMediaService.instance.uploadDocument(
                //           file: file,
                //           groupId: widget.groupId,
                //           senderId: user.userId,
                //         );
                //
                //         await MessageService.instance.sendVoiceMessage(
                //           groupId: widget.groupId,
                //           fileUrl: url,
                //           senderName: user.fullName,
                //           senderRole: user.role,
                //         );
                //       }
                //     }
                //   },
                //
                //   child: CircleAvatar(
                //     radius: 23,
                //     backgroundColor:
                //     isRecording ? Colors.red : AppColors.accent.withOpacity(0.9),
                //     child: Icon(
                //       // Logic: typing → send icon | recording → stop | otherwise mic
                //       _controller.text.isNotEmpty
                //           ? Icons.send
                //           : (isRecording ? Icons.stop : Icons.mic),
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
                //
                // const SizedBox(width: 6),
                //
                // // ======= TAP SEND (if typing) =======
                // if (_controller.text.isNotEmpty)
                //   IconButton(
                //     icon: const Icon(Icons.send, color: Colors.lightBlue),
                //     onPressed: () => _sendMessage(user),
                //   ),

                GestureDetector(
                  onLongPressStart: (_) async {
                    if (_controller.text.isEmpty && !isRecording) {
                      final ok = await VoiceService.instance.startRecording();
                      if (ok) setState(() => isRecording = true);
                    }
                  },

                  onLongPressEnd: (_) async {
                    if (isRecording) {
                      setState(() => isRecording = false);
                      final file = await VoiceService.instance.stopRecording();

                      if (file != null) {
                        final url = await ChatMediaService.instance.uploadDocument(
                          file: file,
                          groupId: widget.groupId,
                          senderId: user.userId,
                        );

                        await MessageService.instance.sendVoiceMessage(
                          groupId: widget.groupId,
                          fileUrl: url,
                          senderName: user.fullName,
                          senderRole: user.role,
                        );
                      }
                    }
                  },

                  onTap: () async {
                    // 👇 If typing → send message
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(user);
                      return;
                    }

                    // 👇 If not typing → treat tap as "quick record"
                    if (!isRecording) {
                      final ok = await VoiceService.instance.startRecording();
                      if (ok) setState(() => isRecording = true);

                      // Auto stop after ~1 sec tap release
                      await Future.delayed(const Duration(milliseconds: 900));
                      if (isRecording) {
                        setState(() => isRecording = false);
                        final file = await VoiceService.instance.stopRecording();

                        if (file != null) {
                          final url = await ChatMediaService.instance.uploadDocument(
                            file: file,
                            groupId: widget.groupId,
                            senderId: user.userId,
                          );

                          await MessageService.instance.sendVoiceMessage(
                            groupId: widget.groupId,
                            fileUrl: url,
                            senderName: user.fullName,
                            senderRole: user.role,
                          );
                        }
                      }
                    }
                  },

                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: isRecording ? Colors.red : AppColors.accent,
                    child: Icon(
                      _controller.text.isNotEmpty
                          ? Icons.send     // 🟡 typing → send
                          : (isRecording ? Icons.stop : Icons.mic),  // 🔴 record | 🎤 mic
                      color: Colors.white,
                    ),
                  ),
                ),



              ],
            ),
          ),


        ],
      ),
    );
  }
}










// class ChatScreen extends StatefulWidget {
//   final String groupId;
//   final String groupName;
//
//   const ChatScreen({
//     super.key,
//     required this.groupId,
//     required this.groupName,
//   });
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scroll = ScrollController();
//
//   bool _sending = false;
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _scroll.dispose();
//     super.dispose();
//   }
//
//   Future<void> _sendMessage(UserModel user) async {
//     if (_controller.text.trim().isEmpty) return;
//
//     setState(() => _sending = true);
//
//     await MessageService.instance.sendTextMessage(
//       groupId: widget.groupId,
//       text: _controller.text.trim(),
//       senderName: user.fullName,
//       senderRole: user.role,
//     );
//
//     _controller.clear();
//     setState(() => _sending = false);
//
//     await Future.delayed(const Duration(milliseconds: 150));
//     _scrollToBottom();
//   }
//
//   void _scrollToBottom() {
//     if (_scroll.hasClients) {
//       _scroll.jumpTo(_scroll.position.maxScrollExtent);
//     }
//   }
//
//   bool _isMine(MessageModel msg, String uid) => msg.senderId == uid;
//
//   String _formatTime(DateTime time) {
//     return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final user = userProvider.user;
//
//     if (user == null) {
//       userProvider.loadUser();
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         title: Text(widget.groupName),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () {},
//           ),
//         ],
//       ),
//
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<List<MessageModel>>(
//               stream: MessageService.instance.streamMessages(widget.groupId),
//               builder: (context, snapshot) {
//
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text(
//                       "Error: ${snapshot.error}",
//                       style: const TextStyle(color: Colors.redAccent),
//                     ),
//                   );
//                 }
//
//                 if (!snapshot.hasData) {
//                   return const Center(
//                     child: Text("Starting Secure Channel...", style: TextStyle(color: Colors.white70)),
//                   );
//                 }
//
//                 final messages = snapshot.data!;
//
//                 if (messages.isEmpty) {
//                   return const Center(
//                     child: Text("No messages yet.", style: TextStyle(color: Colors.white60)),
//                   );
//                 }
//
//                 return ListView.builder(
//                   controller: _scroll,
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   itemCount: messages.length,
//                   itemBuilder: (_, i) {
//                     final msg = messages[i];
//                     final mine = _isMine(msg, user.userId);
//
//                     /// 🔹 Mark Seen
//                     if (!mine && !msg.seenBy.contains(user.userId)) {
//                       MessageService.instance.markSeen(widget.groupId, msg.id);
//                     }
//
//                     /// 🔹 Mark Delivered
//                     if (!msg.deliveredTo.contains(user.userId)) {
//                       MessageService.instance.markDelivered(widget.groupId, msg.id);
//                     }
//
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 4),
//                       child: Row(
//                         mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             constraints: BoxConstraints(
//                                 maxWidth: MediaQuery.of(context).size.width * 0.75),
//                             decoration: BoxDecoration(
//                               color: mine ? AppColors.accent.withOpacity(0.25) : Colors.white12,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: mine ? AppColors.accent : Colors.white24,
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment:
//                               mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                               children: [
//                                 if (!mine)
//                                   Text(
//                                     msg.senderName,
//                                     style: const TextStyle(fontSize: 11, color: Colors.white54),
//                                   ),
//
//                                 if (msg.text != null)
//                                   Text(
//                                     msg.text!,
//                                     style: const TextStyle(color: Colors.white, fontSize: 15),
//                                   ),
//
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       _formatTime(msg.createdAt),
//                                       style: const TextStyle(fontSize: 10, color: Colors.white54),
//                                     ),
//                                     const SizedBox(width: 6),
//
//                                     // 🟣 Seen / Delivered ticks
//                                     if (mine)
//                                       Icon(
//                                         msg.seenBy.length > 1
//                                             ? Icons.done_all
//                                             : msg.deliveredTo.length > 1
//                                             ? Icons.done_all
//                                             : Icons.done,
//                                         size: 14,
//                                         color: msg.seenBy.length > 1
//                                             ? Colors.blueAccent
//                                             : msg.deliveredTo.length > 1
//                                             ? Colors.white70
//                                             : Colors.white38,
//                                       ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//
//           /// ------- INPUT FIELD -------
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.black26,
//               border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: "Message...",
//                       hintStyle: const TextStyle(color: Colors.white38),
//                       filled: true,
//                       fillColor: Colors.black45,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 _sending
//                     ? const CircularProgressIndicator(strokeWidth: 2)
//                     : IconButton(
//                   icon: const Icon(Icons.send, color: AppColors.accent),
//                   onPressed: () => _sendMessage(user),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
