import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/feedikoi_service.dart';
import '../../shared/widgets/cards.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';

class JadwalPakanPage extends StatefulWidget {
  final FeedikoiService service;
  const JadwalPakanPage({super.key, required this.service});

  @override
  State<JadwalPakanPage> createState() => _JadwalPakanPageState();
}

class _JadwalPakanPageState extends State<JadwalPakanPage> {
  late final FeedikoiService service;

  bool systemOn = false;
  double weightLimitGrams = 2000.0;
  List<String> feedTimes = [];
  bool isLoading = true;

  late TextEditingController weightController;
  late TextEditingController _ipController;
  bool _isEditingIp = false;

  @override
  void initState() {
    super.initState();
    service = widget.service;
    weightController = TextEditingController(text: weightLimitGrams.toString());
    _ipController = TextEditingController();
    _loadCameraIp();

    service.getSettingsStream().listen((settings) {
      setState(() {
        weightLimitGrams = settings.weightLimitKG;
        feedTimes = settings.feedTime;
        isLoading = false;
      });
    });

    service.getCurrentDataStream().listen((data) {
      setState(() {
        systemOn = data.systemOn;
      });
    });
  }

  Future<void> _loadCameraIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('camera_ip') ?? '192.168.33.234';
    setState(() {
      _ipController.text = savedIp;
    });
  }

  Future<void> _saveCameraIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_ip', _ipController.text);
    setState(() {
      _isEditingIp = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera IP saved')));
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    _ipController.dispose();
    super.dispose();
  }



  void _addFeedTime() {
    setState(() {
      final now = TimeOfDay.now();
      feedTimes.add('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    });
  }

  void _saveSettings() {
    final updated = FeedSettings(
      feedTime: feedTimes,
      weightLimitKG: weightLimitGrams,
    );
    service.updateSettings(updated);
    print("Saved to service.");
  }

  void _updateSystemStatus(bool val) {
    service.updateSystemStatus(val);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    backgroundColor: Colors.grey[200],
                    children: [
                      CustomCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: const [
                          Row(
                            children: [
                              Text("Kolam 1",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  )),
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomCard(
                              padding: const EdgeInsets.all(12),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Camera IP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(_isEditingIp ? Icons.save : Icons.edit),
                                      onPressed: () {
                                        if (_isEditingIp) {
                                          _saveCameraIp();
                                        } else {
                                          setState(() => _isEditingIp = true);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _ipController,
                                  enabled: _isEditingIp,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.videocam),
                                    hintText: 'Enter camera IP',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    backgroundColor: Colors.grey[200],
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          "Jadwal Pemberian Pakan",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...feedTimes.asMap().entries.map((entry) {
                        int index = entry.key;
                        TimeOfDay time;
                        try {
                          final dt = DateTime.parse(entry.value);
                          time = TimeOfDay.fromDateTime(dt);
                        } catch (e) {
                          try {
                            final parts = entry.value.split(':');
                            time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                          } catch (e2) {
                            time = TimeOfDay.now();
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: CustomCard(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            backgroundColor: Colors.white,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jadwal ${index + 1}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) => TimeScrollPicker(
                                          initialTime: time,
                                          onTimeSelected: (selected) {
                                            setState(() {
                                              feedTimes[index] = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                                            });
                                          },
                                          onTimeDeleted: (selected) {
                                            setState(() {
                                              feedTimes.removeAt(index);
                                            });
                                          },
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          time.hour.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          ' : ',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          time.minute.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                      feedTimes.length < 2 ?
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 32),
                            onPressed: _addFeedTime,
                          ),
                        ),
                      ) : SizedBox.square(dimension: 32,)
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.save),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.grey[800],
          onPressed: _saveSettings,
          label: const Text("Simpan")),
    );
  }
}


class TimeScrollPicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final Function(TimeOfDay) onTimeDeleted;

  const TimeScrollPicker({
    required this.initialTime,
    required this.onTimeSelected,
    required this.onTimeDeleted,
    super.key,
  });

  @override
  State<TimeScrollPicker> createState() => _TimeScrollPickerState();
}

class _TimeScrollPickerState extends State<TimeScrollPicker> {
  int selectedHour = 0;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  void _onConfirm() {
    widget.onTimeSelected(TimeOfDay(hour: selectedHour, minute: selectedMinute));
    Navigator.pop(context);
  }

  void _onDelete(){
    widget.onTimeDeleted(TimeOfDay(hour: selectedHour, minute: selectedMinute));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Pilih Jam'),
      message: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: selectedHour),
                itemExtent: 32,
                onSelectedItemChanged: (index) => setState(() => selectedHour = index),
                children: List.generate(24, (index) => Center(child: Text('$index'))),
              ),
            ),
            const Text(':'),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: selectedMinute),
                itemExtent: 32,
                onSelectedItemChanged: (index) => setState(() => selectedMinute = index),
                children: List.generate(60, (index) => Center(child: Text(index.toString().padLeft(2, '0')))),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: _onConfirm,
          child: const Text("Set"),
        ),
        CupertinoActionSheetAction(
            onPressed: _onDelete,
            child: const Text("Delete")
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text("Cancel"),
      ),
    );
  }
}

