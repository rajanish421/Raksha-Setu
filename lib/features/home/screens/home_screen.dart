import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raksha_setu/test.dart';

import '../../../constants/app_colors.dart';
import '../../call/services/call_service.dart';
import '../../chat/screens/groups_list_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int alertCount = 0;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // CallService.instance.initZego();
    // CallService.instance.listenIncomingCalls(uid);
  }


  void _listenAlerts() {
    FirebaseFirestore.instance
        .collection("alerts")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snap) {
      setState(() => alertCount = snap.docs.length);
    });
  }

  final List<Widget> _pages = [
    const Placeholder(), // Home Dashboard UI - Coming Step 8.4
    const GroupsListScreen(),
    const Placeholder(),
    const Placeholder()
    // const CallsScreen(),
    // const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text("Defence Network", style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [

          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceTestScreen(),));
          }, icon: Icon(Icons.ice_skating_outlined)),
          // Alerts Icon with Badge 👇
          Stack(
            children: [
              // IconButton(
              //   icon: const Icon(Icons.notifications),
              //   onPressed: () {
              //     // Navigator.push(
              //     //   context,
              //     //   MaterialPageRoute(builder: (_) => const VoiceTestScreen()),
              //     // );
              //   },
              // ),
              // if (alertCount > 0)
              //   Positioned(
              //     right: 8,
              //     top: 8,
              //     child: Container(
              //       padding: const EdgeInsets.all(4),
              //       decoration: const BoxDecoration(
              //         color: Colors.red,
              //         shape: BoxShape.circle,
              //       ),
              //       child: Text(
              //         alertCount.toString(),
              //         style: const TextStyle(color: Colors.white, fontSize: 10),
              //       ),
              //     ),
              //   ),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _pages[_index],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white60,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,

        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.call),
            label: "Calls",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],

        onTap: (i) async {
          setState(() => _index = i);
        },
      ),
    );
  }
}
