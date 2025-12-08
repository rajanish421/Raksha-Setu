import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/family_group_model.dart';
import '../../../providers/user_provider.dart';
import '../screens/group_details_soldier_screen.dart';

class FamilyGroupTile extends StatelessWidget {
  final FamilyGroupModel group;

  const FamilyGroupTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final soldierId = userProvider.user?.userId ?? ""; // prevent null crash

    return Hero(
      tag: "group_${group.id}", // smooth animation
      child: Card(
        color: Colors.white.withOpacity(0.1),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            group.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: Text(
            "${group.members.length} Members",
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                  group: group,
                  soldierId: soldierId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
