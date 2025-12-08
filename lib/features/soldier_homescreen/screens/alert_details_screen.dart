import 'package:flutter/material.dart';
import '../../../models/alert_model.dart';

class AlertDetailsScreen extends StatelessWidget {
  final AlertModel alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alert Information")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.type.toUpperCase(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const SizedBox(height: 10),

            Text(alert.title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            _info("Group", alert.groupName),
            _info("Message", alert.message),
            _info("Status", alert.status.toUpperCase()),
            _info("Sender", "${alert.senderName} (${alert.senderRole})"),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text("$label:")),
          Expanded(
            child: Text(
              value ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
