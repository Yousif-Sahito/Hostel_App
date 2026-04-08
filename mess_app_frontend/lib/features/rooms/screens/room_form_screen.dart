import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomFormScreen extends StatefulWidget {
  final RoomModel? room;

  const RoomFormScreen({super.key, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController roomNumberController;
  late final TextEditingController capacityController;
  late final TextEditingController occupiedCountController;

  String status = 'AVAILABLE';
  bool isLoading = false;

  bool get isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();

    roomNumberController = TextEditingController(
      text: widget.room?.roomNumber ?? '',
    );
    capacityController = TextEditingController(
      text: widget.room?.capacity.toString() ?? '',
    );
    occupiedCountController = TextEditingController(
      text: isEdit ? widget.room?.occupiedCount.toString() : '',
    );

    status = widget.room?.status ?? 'AVAILABLE';

    // Auto-update status when occupied count or capacity changes
    occupiedCountController.addListener(_updateStatus);
    capacityController.addListener(_updateStatus);
  }

  @override
  void dispose() {
    roomNumberController.dispose();
    capacityController.dispose();
    occupiedCountController.dispose();
    super.dispose();
  }

  void _updateStatus() {
    try {
      final occupied = int.tryParse(occupiedCountController.text.trim()) ?? 0;
      final capacity = int.tryParse(capacityController.text.trim()) ?? 0;

      if (capacity > 0 && occupied >= capacity) {
        setState(() => status = 'FULL');
      } else if (occupied >= 0) {
        setState(() => status = 'AVAILABLE');
      }
    } catch (e) {
      // Keep current status if parsing fails
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final capacity = int.parse(capacityController.text.trim());
      final occupiedCount = int.parse(occupiedCountController.text.trim());

      if (occupiedCount > capacity) {
        throw Exception('Occupied count cannot be greater than capacity');
      }

      if (isEdit) {
        await RoomService.updateRoom(
          id: widget.room!.id,
          roomNumber: roomNumberController.text.trim(),
          capacity: capacity,
          occupiedCount: occupiedCount,
          status: status,
        );
      } else {
        await RoomService.addRoom(
          roomNumber: roomNumberController.text.trim(),
          capacity: capacity,
          occupiedCount: occupiedCount,
          status: status,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Room updated successfully' : 'Room created successfully',
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
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Room' : 'Add Room')),
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
                  _textField(
                    'Room Number',
                    roomNumberController,
                    hintText: 'e.g. A-01 or 101',
                  ),
                  _textField(
                    'Capacity',
                    capacityController,
                    keyboardType: TextInputType.number,
                    hintText: 'e.g. 4',
                  ),
                  _textField(
                    'Occupied Count',
                    occupiedCountController,
                    keyboardType: TextInputType.number,
                    hintText: 'e.g. 0',
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
                      DropdownMenuItem(
                        value: 'AVAILABLE',
                        child: Text('AVAILABLE'),
                      ),
                      DropdownMenuItem(value: 'FULL', child: Text('FULL')),
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
                          : Text(isEdit ? 'Update Room' : 'Create Room'),
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
