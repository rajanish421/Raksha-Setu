import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../models/alert_model.dart';
import '../services/alert_service.dart';
import 'alert_details_screen.dart';

class SoldierAlertScreen extends StatefulWidget {
  const SoldierAlertScreen({super.key});

  @override
  State<SoldierAlertScreen> createState() => _SoldierAlertScreenState();
}

class _SoldierAlertScreenState extends State<SoldierAlertScreen> {
  String filterType = "All";
  String filterStatus = "All";
  String selectedGroup = "All Groups";

  List<Map<String, dynamic>> groups = [];
  bool loadingGroups = true;

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

    setState(() {
      groups = snap.docs.map((e) => {"id": e.id, "name": e["name"]}).toList();
      loadingGroups = false;
    });
  }


  void _openAlertDetails(AlertModel alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertDetailsScreen(alert: alert),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (loadingGroups) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Alerts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () => _openCreateAlert(context),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FILTERS
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
                const SizedBox(width: 12),
                _dropDownFilter(
                  label: "Status",
                  value: filterStatus,
                  items: ["All", "pending", "acknowledged", "resolved"],
                  onChanged: (v) => setState(() => filterStatus = v!),
                ),
                const SizedBox(width: 12),
                _dropDownFilter(
                  label: "Group",
                  value: selectedGroup,
                  items: ["All Groups", ...groups.map((e) => e["name"]).toList()],
                  onChanged: (v) => setState(() => selectedGroup = v!),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("alerts")
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  final allowedGroupIds = groups.map((e) => e["id"]).toList();

                  final alerts = snap.data!.docs
                      .map((e) => AlertModel.fromMap(e.id, e.data() as Map<String, dynamic>))
                      .where((alert) {

                    // SHOW alerts from groups soldier belongs to OR GLOBAL alerts
                    if (alert.groupId == null || alert.groupId!.isEmpty) return true;

                    return allowedGroupIds.contains(alert.groupId);
                  })
                      .where((alert) {
                    if (filterType != "All" && alert.type != filterType) return false;
                    if (filterStatus != "All" && alert.status != filterStatus) return false;
                    if (selectedGroup != "All Groups" && alert.groupName != selectedGroup) return false;
                    return true;
                  })
                      .toList();

                  if (alerts.isEmpty) {
                    return const Center(
                      child: Text("No alerts found.", style: TextStyle(color: Colors.white54)),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      dataTextStyle: const TextStyle(color: Colors.white70),

                      columns: const [
                        DataColumn(label: Text("Type")),
                        DataColumn(label: Text("Title")),
                        DataColumn(label: Text("Group")),
                        DataColumn(label: Text("Time")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],

                      rows: alerts.map((alert) {
                        return DataRow(
                          cells: [
                            DataCell(_typeBadge(alert.type)),
                            DataCell(Text(alert.title)),
                            DataCell(Text(alert.groupName ?? "-")),
                            DataCell(Text(_format(alert.timestamp))),
                            DataCell(_statusBadge(alert.status)),
                            DataCell(
                              TextButton(
                                child: const Text("View"),
                                onPressed:  () => _openAlertDetails(alert),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(dynamic t) {
    if (t == null) return "-";
    DateTime d = t is Timestamp ? t.toDate() : DateTime.parse(t.toString());
    return DateFormat("hh:mm a • dd MMM").format(d);
  }

  Widget _typeBadge(String type) {
    final colors = {
      "SOS": Colors.redAccent,
      "Threat": Colors.deepOrange,
      "Medical": Colors.purpleAccent,
      "Suspicious": Colors.orangeAccent,
      "Other": Colors.blue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[type]!.withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type, style: TextStyle(color: colors[type]!, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      "pending": Colors.yellow,
      "acknowledged": Colors.blueAccent,
      "resolved": Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: colors[status], fontWeight: FontWeight.bold)),
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
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.black,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  // ---------- CREATE ALERT ----------
  Future<void> _openCreateAlert(BuildContext context) async {
    String type = "SOS";
    String? groupId;
    String title = "";
    String message = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create Alert",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(label: Text("Alert Type")),
                    items: ["SOS", "Medical", "Threat", "Suspicious", "Other"]
                        .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Select Group"),
                    value: groupId,
                    items: groups
                        .map(
                          (g) => DropdownMenuItem<String>(
                        value: g["id"],
                        child: Text(g["name"]),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => groupId = v),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    decoration: const InputDecoration(labelText: "Alert Title"),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Message"),
                    onChanged: (v) => message = v,
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Send Alert"),
                    onPressed: () async {
                      if (groupId == null || title.isEmpty || message.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("⚠ Please fill all fields"),
                          ),
                        );
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final userSnap = await FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .get();

                      await FirebaseFirestore.instance.collection("alerts").add({
                        "type": type,
                        "title": title,
                        "message": message,
                        "groupId": groupId,
                        "groupName": groups.firstWhere((g) => g["id"] == groupId)["name"],
                        "timestamp": FieldValue.serverTimestamp(),
                        "status": "pending",
                        "senderUid": uid,
                        "senderName": userSnap["fullName"],
                        "senderRole": userSnap["role"],
                        "receiverId": null, // optional
                      });

                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
