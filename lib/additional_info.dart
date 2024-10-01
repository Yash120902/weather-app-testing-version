import 'package:flutter/material.dart';

class AdditionalInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const AdditionalInfo(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        Text(label),
        Text(value),
      ],
    );
  }
}
