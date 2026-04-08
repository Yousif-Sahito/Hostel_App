import 'package:flutter/material.dart';

import '../models/member_model.dart';

class MemberDetailScreen extends StatelessWidget {
  final MemberModel member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                _item('Full Name', member.fullName),
                _item('Email', member.email ?? '-'),
                _item('CMS ID', member.cmsId ?? '-'),
                _item('Phone', member.phone ?? '-'),
                _item('Role', member.role),
                _item('Status', member.status),
                _item('Room ID', member.roomId?.toString() ?? '-'),
                _item('Joining Date', member.joiningDate ?? '-'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
