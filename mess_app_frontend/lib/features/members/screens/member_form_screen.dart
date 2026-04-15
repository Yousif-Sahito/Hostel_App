import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  String status = 'ACTIVE';
  bool isLoading = false;
  bool isRoomsLoading = true;

  List<RoomModel> rooms = [];
  int? selectedRoomId;

  bool get isEdit => widget.member != null;
  bool _isRoomSelectable(RoomModel room) {
    final isCurrentRoom = widget.member?.roomId == room.id;
    return room.occupiedCount < room.capacity || isCurrentRoom;
  }

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
      text: _normalizeJoiningDateForInput(widget.member?.joiningDate),
    );

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
      final selectedRoom = selectedRoomId == null
          ? null
          : rooms.cast<RoomModel?>().firstWhere(
              (room) => room?.id == selectedRoomId,
              orElse: () => null,
            );

      if (selectedRoom != null && !_isRoomSelectable(selectedRoom)) {
        throw Exception('Room ${selectedRoom.roomNumber} is full');
      }

      if (isEdit) {
        await MemberService.updateMember(
          id: widget.member!.id,
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          cmsId: cmsIdController.text.trim(),
          phone: phoneController.text.trim(),
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

  String _normalizeJoiningDateForInput(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    final value = rawDate.trim();
    final maskedPattern = RegExp(r'^\d{2}/\d{2}/\d{2}$');
    if (maskedPattern.hasMatch(value)) return value;

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    final yy = (parsed.year % 100).toString().padLeft(2, '0');
    final mm = parsed.month.toString().padLeft(2, '0');
    final dd = parsed.day.toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
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
                  _textField('Email', emailController),
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
                                (room) {
                                  final isCurrentRoom = widget.member?.roomId == room.id;
                                  final isFull = room.occupiedCount >= room.capacity;
                                  final isSelectable = _isRoomSelectable(room);
                                  final suffix = isCurrentRoom
                                      ? ' - Current'
                                      : isFull
                                      ? ' - Full'
                                      : '';

                                  return DropdownMenuItem<int?>(
                                    value: room.id,
                                    enabled: isSelectable,
                                    child: Text(
                                      'Room ${room.roomNumber} (${room.occupiedCount}/${room.capacity})$suffix',
                                    ),
                                  );
                                },
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedRoomId = value);
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: joiningDateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        JoiningDateInputFormatter(),
                      ],
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) return null;
                        if (!RegExp(r'^\d{2}/\d{2}/\d{2}$').hasMatch(raw)) {
                          return 'Use DD/MM/YY format';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Joining Date',
                        hintText: 'DD/MM/YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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

class JoiningDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clamped = digits.length > 6 ? digits.substring(0, 6) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < clamped.length; i++) {
      buffer.write(clamped[i]);
      if ((i == 1 || i == 3) && i != clamped.length - 1) {
        buffer.write('/');
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
