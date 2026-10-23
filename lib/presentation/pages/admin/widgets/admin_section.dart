import 'package:flutter/material.dart';

const adminBorder = Color(0xFFE9E9EE);
const adminInk = Color(0xFF1B1B1F);
const adminMuted = Color(0xFF6E6E78);

class AdminSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AdminSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Divider(height: 1, indent: 66, color: adminBorder));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: adminInk,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminBorder),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}
