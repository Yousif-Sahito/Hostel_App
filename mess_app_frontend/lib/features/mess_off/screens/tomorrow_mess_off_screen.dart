import 'package:flutter/material.dart';

import '../models/mess_off_model.dart';
import '../services/mess_off_service.dart';

class TomorrowMessOffScreen extends StatefulWidget {
  const TomorrowMessOffScreen({super.key});

  @override
  State<TomorrowMessOffScreen> createState() => _TomorrowMessOffScreenState();
}

class _TomorrowMessOffScreenState extends State<TomorrowMessOffScreen> {
  bool _isLoading = true;
  List<MessOffModel> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await MessOffService.getTomorrowMessOffList();
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tomorrow's Mess Off"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _entries.isEmpty
                  ? const Center(child: Text("No mess off for tomorrow"))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_off),
                            ),
                            title: Text(entry.userName ?? 'Unknown Member'),
                            subtitle: Text('CMS ID: ${entry.cmsId ?? 'N/A'}'),
                            trailing: Text(
                              entry.createdAt != null
                                  ? 'Off at: ${entry.createdAt!.substring(11, 16)}'
                                  : '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
