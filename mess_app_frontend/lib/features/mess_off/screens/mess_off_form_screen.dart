import 'package:flutter/material.dart';

import '../../members/models/member_model.dart';
import '../../members/services/member_service.dart';
import '../models/mess_off_model.dart';
import '../services/mess_off_service.dart';

class MessOffFormScreen extends StatefulWidget {
  final MessOffModel? entry;

  const MessOffFormScreen({super.key, this.entry});

  @override
  State<MessOffFormScreen> createState() => _MessOffFormScreenState();
}

class _MessOffFormScreenState extends State<MessOffFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final reasonController = TextEditingController();

  bool isLoading = false;
  bool isMembersLoading = true;

  List<MemberModel> members = [];
  int? selectedMemberId;

  String status = 'ACTIVE';

  bool get isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();

    fromDateController.text = widget.entry?.fromDate ?? _todayDate();
    toDateController.text = widget.entry?.toDate ?? _todayDate();
    reasonController.text = widget.entry?.reason ?? '';
    selectedMemberId = widget.entry?.userId;

    final incomingStatus = (widget.entry?.status ?? 'ACTIVE').toUpperCase();
    if (incomingStatus == 'ACTIVE' ||
        incomingStatus == 'CANCELLED' ||
        incomingStatus == 'COMPLETED') {
      status = incomingStatus;
    } else {
      status = 'ACTIVE';
    }

    _loadMembers();
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMembers() async {
    try {
      final fetchedMembers = await MemberService.getMembers();

      if (!mounted) return;

      setState(() {
        members = fetchedMembers
            .where((m) => m.role.toUpperCase() == 'MEMBER')
            .toList();
        isMembersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isMembersLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a member')));
      return;
    }

    if (DateTime.tryParse(fromDateController.text.trim()) == null ||
        DateTime.tryParse(toDateController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use date format yyyy-mm-dd')),
      );
      return;
    }

    final fromDate = DateTime.parse(fromDateController.text.trim());
    final toDate = DateTime.parse(toDateController.text.trim());

    if (toDate.isBefore(fromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To Date cannot be earlier than From Date'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isEdit) {
        await MessOffService.updateMessOff(
          id: widget.entry!.id!,
          userId: selectedMemberId!,
          fromDate: fromDateController.text.trim(),
          toDate: toDateController.text.trim(),
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
          status: status,
        );
      } else {
        await MessOffService.addMessOff(
          userId: selectedMemberId!,
          fromDate: fromDateController.text.trim(),
          toDate: toDateController.text.trim(),
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
          status: status,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Mess off entry updated successfully'
                : 'Mess off entry created successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool requiredField = true,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Mess Off' : 'Add Mess Off')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (isMembersLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMemberId,
                        decoration: InputDecoration(
                          labelText: 'Member',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: members
                            .map(
                              (member) => DropdownMenuItem<int>(
                                value: member.id,
                                child: Text(
                                  '${member.fullName} (${member.cmsId ?? '-'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedMemberId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a member' : null,
                      ),
                    ),
                  _textField(
                    'From Date',
                    fromDateController,
                    hintText: 'yyyy-mm-dd',
                  ),
                  _textField(
                    'To Date',
                    toDateController,
                    hintText: 'yyyy-mm-dd',
                  ),
                  _textField(
                    'Reason',
                    reasonController,
                    requiredField: false,
                    hintText: 'Optional',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('CANCELLED'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('COMPLETED'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'Update Mess Off' : 'Create Mess Off',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
