import 'package:flutter/material.dart';

import '../../rooms/models/room_model.dart';
import '../../rooms/services/room_service.dart';
import '../models/member_model.dart';
import '../services/member_service.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController fullNameController;
  late final TextEditingController emailController;
  late final TextEditingController cmsIdController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController joiningDateController;

  String role = 'MEMBER';
  String status = 'ACTIVE';
  bool isLoading = false;
  bool isRoomsLoading = true;

  List<RoomModel> rooms = [];
  int? selectedRoomId;

  bool get isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: widget.member?.fullName ?? '',
    );
    emailController = TextEditingController(text: widget.member?.email ?? '');
    cmsIdController = TextEditingController(text: widget.member?.cmsId ?? '');
    phoneController = TextEditingController(text: widget.member?.phone ?? '');
    passwordController = TextEditingController();
    joiningDateController = TextEditingController(
      text: widget.member?.joiningDate ?? '',
    );

    role = widget.member?.role ?? 'MEMBER';
    status = widget.member?.status ?? 'ACTIVE';
    selectedRoomId = widget.member?.roomId;

    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final fetchedRooms = await RoomService.getRooms();
      if (!mounted) return;

      setState(() {
        rooms = fetchedRooms;
        isRoomsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isRoomsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    cmsIdController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    joiningDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final joiningDate = joiningDateController.text.trim().isEmpty
          ? null
          : joiningDateController.text.trim();

      if (isEdit) {
        await MemberService.updateMember(
          id: widget.member!.id,
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          cmsId: cmsIdController.text.trim(),
          phone: phoneController.text.trim(),
          role: role,
          status: status,
          roomId: selectedRoomId,
          joiningDate: joiningDate,
        );
      } else {
        await MemberService.addMember(
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          cmsId: cmsIdController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text.trim(),
          role: role,
          status: status,
          roomId: selectedRoomId,
          joiningDate: joiningDate,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Member updated successfully'
                : 'Member created successfully',
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
    bool obscureText = false,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Member' : 'Add Member')),
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
                  _textField('Full Name', fullNameController),
                  _textField('Email', emailController, requiredField: false),
                  _textField('CMS ID', cmsIdController),
                  _textField('Phone', phoneController),
                  if (!isEdit)
                    _textField(
                      'Password',
                      passwordController,
                      obscureText: true,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: isRoomsLoading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int?>(
                            initialValue: selectedRoomId,
                            decoration: InputDecoration(
                              labelText: 'Room',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Room'),
                              ),
                              ...rooms.map(
                                (room) => DropdownMenuItem<int?>(
                                  value: room.id,
                                  child: Text(
                                    'Room ${room.roomNumber} (${room.occupiedCount}/${room.capacity})',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedRoomId = value);
                            },
                          ),
                  ),
                  _textField(
                    'Joining Date',
                    joiningDateController,
                    requiredField: false,
                    hintText: 'yyyy-mm-dd',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MEMBER', child: Text('MEMBER')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => role = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
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
                        value: 'INACTIVE',
                        child: Text('INACTIVE'),
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
                          : Text(isEdit ? 'Update Member' : 'Create Member'),
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
