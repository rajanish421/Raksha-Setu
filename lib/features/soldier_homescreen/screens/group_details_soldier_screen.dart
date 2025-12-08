import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/family_group_model.dart';

class GroupDetailsScreen extends StatefulWidget {
  final FamilyGroupModel group;
  final String soldierId; // current logged-in soldier

  const GroupDetailsScreen({
    super.key,
    required this.group,
    required this.soldierId,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _loading = false;

  // local mutable state (because FamilyGroupModel is immutable)
  late String _groupName;
  late List<String> _memberIds;

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;
    _memberIds = List<String>.from(widget.group.members);
  }

  Future<void> _removeMember(String uid) async {
    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection("groups")
        .doc(widget.group.id)
        .update({
      "members": FieldValue.arrayRemove([uid]),
    });

    _memberIds.remove(uid);

    setState(() => _loading = false);
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text("Delete Group"),
        content: const Text("Are you sure you want to delete this group?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("groups")
          .doc(widget.group.id)
          .delete();

      if (mounted) {
        Navigator.pop(context, true); // go back to previous screen
      }
    }
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text("Rename Group"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Group name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("groups")
          .doc(widget.group.id)
          .update({"name": newName});

      setState(() {
        _groupName = newName;
      });
    }
  }

  Future<void> _addMembers() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _AddMembersDialog(
        soldierId: widget.soldierId,
        existingMembers: _memberIds,
      ),
    );

    if (result == null || result.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("groups")
        .doc(widget.group.id)
        .update({
      "members": FieldValue.arrayUnion(result),
    });

    setState(() {
      _memberIds.addAll(result.where((id) => !_memberIds.contains(id)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Rename group",
            onPressed: _editGroupName,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete group",
            onPressed: _deleteGroup,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Members",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.greenAccent,
                  ),
                  onPressed: _addMembers,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // members list
            Expanded(
              child: _memberIds.isEmpty
                  ? const Center(
                child: Text(
                  "No members in this group yet.",
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where(
                  FieldPath.documentId,
                  whereIn: _memberIds.isEmpty
                      ? ["dummy"] // Firestore can't take []
                      : _memberIds,
                )
                    .snapshots(),
                builder: (_, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Unable to load member details.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final u = docs[index];
                      final uid = u.id;

                      final isSoldierOwner =
                          uid == widget.soldierId;

                      return Card(
                        color: AppColors.surfaceLight,
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            u["fullName"] ?? "-",
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                          subtitle: Text(
                            u["phone"] ?? "",
                            style: const TextStyle(
                                color: Colors.white70),
                          ),
                          trailing: isSoldierOwner
                              ? const SizedBox.shrink()
                              : IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                _removeMember(uid),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMembersDialog extends StatefulWidget {
  final String soldierId;
  final List<String> existingMembers;

  const _AddMembersDialog({
    required this.soldierId,
    required this.existingMembers,
  });

  @override
  State<_AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<_AddMembersDialog> {
  List<String> _selected = [];
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text("Add Family Members"),
      content: SizedBox(
        height: 320,
        width: 340,
        child: FutureBuilder<DocumentSnapshot>(
          // 1️⃣ Get soldier doc to read serviceNumber
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(widget.soldierId)
              .get(),
          builder: (_, soldierSnap) {
            if (!soldierSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final soldierData =
            soldierSnap.data!.data() as Map<String, dynamic>?;
            final serviceNo = soldierData?["serviceNumber"];

            if (serviceNo == null || serviceNo.toString().isEmpty) {
              return const Center(
                child: Text(
                  "No service number found for this soldier.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            // 2️⃣ Get family members: role=family, approved, referenceServiceNumber = soldier.serviceNumber
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "family")
                  .where("status", isEqualTo: "approved")
                  .where("referenceServiceNumber", isEqualTo: serviceNo)
                  .snapshots(),
              builder: (_, familySnap) {
                if (!familySnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = familySnap.data!.docs.where((d) {
                  // Exclude already in group
                  if (widget.existingMembers.contains(d.id)) return false;

                  final name =
                  (d["fullName"] ?? "").toString().toLowerCase();
                  final phone =
                  (d["phone"] ?? "").toString().toLowerCase();

                  if (_search.isEmpty) return true;
                  return name.contains(_search) || phone.contains(_search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No family members available to add.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search by name or phone...",
                      ),
                      onChanged: (v) =>
                          setState(() => _search = v.toLowerCase()),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final u =
                          docs[i].data() as Map<String, dynamic>;
                          final uid = docs[i].id;
                          final selected = _selected.contains(uid);

                          return CheckboxListTile(
                            value: selected,
                            title: Text(u["fullName"] ?? "-"),
                            subtitle: Text(u["phone"] ?? "-"),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selected.add(uid);
                                } else {
                                  _selected.remove(uid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text("Add"),
        ),
      ],
    );
  }
}
