import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';

class CreateFamilyGroupDialog extends StatefulWidget {
  final String soldierId;
  final List<String> familyUIDs;

  const CreateFamilyGroupDialog({
    super.key,
    required this.soldierId,
    required this.familyUIDs,
  });

  @override
  State<CreateFamilyGroupDialog> createState() => _CreateFamilyGroupDialogState();
}

class _CreateFamilyGroupDialogState extends State<CreateFamilyGroupDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedMembers = [];
  bool _saving = false;
  String search = "";

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      _toast("Group name required");
      return;
    }

    if (_selectedMembers.isEmpty) {
      _toast("Select at least 1 family member");
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection("groups").add({
        "name": name,
        "members": [widget.soldierId, ..._selectedMembers],
        "officers": [widget.soldierId],
        "createdBy": widget.soldierId,
        "createdAt": DateTime.now().toString(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast("Error: $e");
    }

    setState(() => _saving = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(18),
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Family Group",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                prefixIcon: Icon(Icons.group),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Select Family Members",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search member...",
              ),
              onChanged: (v) => setState(() => search = v.toLowerCase()),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.familyUIDs.isEmpty
                    ? const Stream.empty()
                    : FirebaseFirestore.instance
                    .collection("users")
                    .where(FieldPath.documentId, whereIn: widget.familyUIDs)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    final name = (d["fullName"] ?? "").toLowerCase();
                    return search.isEmpty || name.contains(search);
                  }).toList();

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final user = docs[i];
                      final uid = user.id;
                      final selected = _selectedMembers.contains(uid);

                      return CheckboxListTile(
                        title: Text(user["fullName"] ?? "-"),
                        subtitle: Text(user["phone"] ?? "-"),
                        value: selected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedMembers.add(uid);
                            } else {
                              _selectedMembers.remove(uid);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saving ? null : _createGroup,
                child: Text(_saving ? "Creating..." : "Create"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
