import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../screens/family_member_details_screen.dart';

class FamilyMemberCard extends StatelessWidget {
  final UserModel user;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  const FamilyMemberCard({
    super.key,
    required this.user,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (user.status) {
      case "approved":
        statusColor = Colors.green;
        break;
      case "pending":
        statusColor = Colors.orange;
        break;
      case "rejected":
      case "suspended":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyMemberDetailsScreen(user: user),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
          user.selfieUrl.isNotEmpty ? NetworkImage(user.selfieUrl) : null,
          child: user.selfieUrl.isEmpty
              ? const Icon(Icons.person, size: 30)
              : null,
        ),

        title: Text(user.fullName),
        subtitle: Row(
          children: [
            Text("${user.relationship ?? ''} • "),
            Text(
              user.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            )
          ],
        ),

        trailing: _buildActionButtons(context),
      ),
    );
  }

  /// 🔥 ACTIONS BASED ON STATUS
  Widget _buildActionButtons(BuildContext context) {
    if (user.status == "pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: onApprove,
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: onReject,
          ),
        ],
      );
    }

    if (user.status == "approved") {
      return TextButton(
        onPressed: onReject,
        child: const Text(
          "Suspend",
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    // 👇 This handles `rejected` or `suspended` → give option to approve again
    if (user.status == "rejected" || user.status == "suspended") {
      return TextButton(
        onPressed: onApprove,
        child: const Text(
          "Approve Again",
          style: TextStyle(color: Colors.green),
        ),
      );
    }

    return const SizedBox();
  }
}
