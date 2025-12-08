import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../models/alert_model.dart';
import 'alert_details_screen.dart';

class SoldierAlertScreen extends StatefulWidget {
  const SoldierAlertScreen({super.key});

  @override
  State<SoldierAlertScreen> createState() => _SoldierAlertScreenState();
}

class _SoldierAlertScreenState extends State<SoldierAlertScreen> {
  String filterType = "All";
  String filterStatus = "All";
  String selectedGroup = "All Alerts";



  List<Map<String, dynamic>> groups = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("groups")
        .where("members", arrayContains: uid)
        .get();

    groups = snap.docs.map((e) => {"id": e.id, "name": e["name"]}).toList();

    setState(() => loading = false);
  }

  List<String> get filterOptions {
    final base = ["All Alerts", "My Group Alerts", ...groups.map((e) => e["name"] as String)];
    return base.toSet().toList(); // remove duplicates
  }

  void _openAlertDetails(AlertModel alert) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailsScreen(alert: alert)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Alerts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () => _openCreateAlert(context),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ---------- FILTERS ----------
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _dropDownFilter(
                label: "Type",
                value: filterType,
                items: ["All", "SOS", "Threat", "Medical", "Suspicious", "Other"],
                onChanged: (v) => setState(() => filterType = v!),
              ),
              _dropDownFilter(
                label: "Status",
                value: filterStatus,
                items: ["All", "pending", "acknowledged", "resolved"],
                onChanged: (v) => setState(() => filterStatus = v!),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---------- GROUP FILTER ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterOptions.contains(selectedGroup) ? selectedGroup : "All Alerts",
                dropdownColor: Colors.black87,
                items: filterOptions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedGroup = value!);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------- ALERT LIST ----------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("alerts")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allowedGroupIds = groups.map((e) => e["id"]).toList();

                final alerts = snap.data!.docs
                    .map((d) => AlertModel.fromMap(d.id, d.data() as Map<String, dynamic>))
                    .where((alert) {
                  // GROUP FILTER RULE
                  if (selectedGroup == "All Alerts") return true;
                  if (selectedGroup == "My Group Alerts") {
                    return allowedGroupIds.contains(alert.groupId);
                  }
                  return alert.groupName == selectedGroup;
                }).where((alert) {
                  // TYPE + STATUS FILTER
                  if (filterType != "All" && alert.type != filterType) return false;
                  if (filterStatus != "All" && alert.status != filterStatus) return false;
                  return true;
                }).toList();

                if (alerts.isEmpty) {
                  return const Center(
                    child: Text("No alerts found.", style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _alertCard(alerts[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _alertCard(AlertModel alert) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bool isRead = alert.readBy.contains(uid);

    Color badgeColor = alert.status == "pending"
        ? Colors.orange
        : alert.status == "acknowledged"
        ? Colors.blue
        : Colors.green;

    return GestureDetector(
      onTap: () => _openAlertDetails(alert),
      child: Card(
        elevation: isRead ? 1 : 4,
        color: isRead ? Colors.grey.withOpacity(0.08) : Colors.red.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.transparent : Colors.redAccent,
            width: isRead ? 0.5 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 🔥 LEFT ICON
              Icon(
                Icons.campaign_rounded,
                size: 28,
                color: isRead ? Colors.white54 : Colors.redAccent,
              ),

              const SizedBox(width: 12),

              // 🔥 TITLE + SUBTITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${alert.groupName ?? "Global"} • ${alert.type}",
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // 🔥 STATUS CHIP
              Chip(
                label: Text(alert.status.toUpperCase()),
                backgroundColor: badgeColor.withOpacity(.2),
                labelStyle: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),

              // 🔥 UNREAD DOT
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _dropDownFilter({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.black87,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  String _format(dynamic t) {
    if (t == null) return "-";
    final d = t is Timestamp ? t.toDate() : DateTime.parse(t.toString());
    return DateFormat("hh:mm a • dd MMM").format(d);
  }

  // ---------- CREATE ALERT ----------
  Future<void> _openCreateAlert(BuildContext context) async {
    String type = "SOS";
    String? groupId;
    String title = "";
    String message = "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, update) => Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("Create Alert",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: type,
                  items: ["SOS", "Medical", "Threat", "Suspicious", "Other"]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => update(() => type = v!),
                  decoration: const InputDecoration(label: Text("Alert Type")),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: groupId,
                  decoration: const InputDecoration(label: Text("Assign Group")),
                  items: groups
                      .map(
                        (g) => DropdownMenuItem<String>(
                      value: g["id"].toString(),
                      child: Text(g["name"].toString()),
                    ),
                  )
                      .toList(),

                  onChanged: (v) => update(() => groupId = v),

                ),

                const SizedBox(height: 10),

                TextField(
                  decoration: const InputDecoration(label: Text("Title")),
                  onChanged: (v) => title = v,
                ),
                const SizedBox(height: 10),

                TextField(
                  decoration: const InputDecoration(label: Text("Message")),
                  maxLines: 3,
                  onChanged: (v) => message = v,
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Send"),
                  onPressed: () async {
                    if (groupId == null || title.isEmpty || message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠ Please fill all fields")),
                      );
                      return;
                    }

                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final user = await FirebaseFirestore.instance.collection("users").doc(uid).get();

                    await FirebaseFirestore.instance.collection("alerts").add({
                      "title": title,
                      "message": message,
                      "type": type,
                      "groupId": groupId,
                      "groupName": groups.firstWhere((g) => g["id"] == groupId)["name"],
                      "timestamp": FieldValue.serverTimestamp(),
                      "status": "pending",
                      "senderUid": uid,
                      "senderName": user["fullName"],
                      "senderRole": user["role"],
                      "readBy": [],
                    });

                    Navigator.pop(ctx);
                  },
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
