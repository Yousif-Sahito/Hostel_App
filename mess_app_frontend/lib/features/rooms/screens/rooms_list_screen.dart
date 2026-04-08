import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../providers/room_provider.dart';
import '../services/room_service.dart';
import '../widgets/room_card.dart';
import 'room_form_screen.dart';

class RoomsListScreen extends StatelessWidget {
  const RoomsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoomProvider()..fetchRooms(),
      child: const _RoomsListView(),
    );
  }
}

class _RoomsListView extends StatelessWidget {
  const _RoomsListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchRooms,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredRooms.isEmpty
                  ? const Center(child: Text('No rooms found'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchRooms,
                      child: ListView.builder(
                        itemCount: provider.filteredRooms.length,
                        itemBuilder: (context, index) {
                          final room = provider.filteredRooms[index];

                          return RoomCard(
                            room: room,
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomFormScreen(room: room),
                                ),
                              );

                              if (updated == true && context.mounted) {
                                await context.read<RoomProvider>().fetchRooms();
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Room'),
                                  content: Text(
                                    'Are you sure you want to delete Room ${room.roomNumber}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  await RoomService.deleteRoom(room.id);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Room deleted successfully',
                                        ),
                                      ),
                                    );
                                  }

                                  if (context.mounted) {
                                    await context
                                        .read<RoomProvider>()
                                        .fetchRooms();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomFormScreen()),
          );

          if (created == true && context.mounted) {
            await context.read<RoomProvider>().fetchRooms();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
    );
  }
}
