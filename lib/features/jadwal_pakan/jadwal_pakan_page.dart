import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../services/feedikoi_service.dart';
import '../../shared/widgets/cards.dart';

class JadwalPakanPage extends StatefulWidget {
  const JadwalPakanPage({super.key});

  @override
  State<JadwalPakanPage> createState() => _JadwalPakanPageState();
}

class _JadwalPakanPageState extends State<JadwalPakanPage> {
  final FeedikoiService service = MockFeedikoiService();

  bool systemOn = false;
  double weightLimitGrams = 2000.0;
  List<TimeOfDay> feedTimes = [];
  bool isLoading = true;

  late TextEditingController weightController;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController(text: weightLimitGrams.toString());

    service.getSettingsStream().listen((settings) {
      setState(() {
        systemOn = settings.systemOn;
        weightLimitGrams = settings.weightLimitKG * 1000;
        feedTimes = [settings.feedTime];
        isLoading = false;
      });
    });
  }

  void _addFeedTime() {
    setState(() {
      feedTimes.add(TimeOfDay.now());
    });
  }

  void _saveSettings() {
    final updated = FeedSettings(
      feedTime: feedTimes.first,
      weightLimitKG: weightLimitGrams,
      systemOn: systemOn,
    );
    service.updateSettings(updated);
    print("Saved to service.");
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
                      CustomCard(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "System Status",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 80),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Switch(
                                  value: systemOn,
                                  activeTrackColor: Colors.greenAccent[200],
                                  inactiveThumbColor: Colors.white,
                                  trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent),
                                  onChanged: (val) => setState(() => systemOn = val),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
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
                        TimeOfDay time = entry.value;

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
                                              feedTimes[index] = selected;
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
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 32),
                            onPressed: _addFeedTime,
                          ),
                        ),
                      )
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

  const TimeScrollPicker({
    required this.initialTime,
    required this.onTimeSelected,
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
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text("Cancel"),
      ),
    );
  }
}

