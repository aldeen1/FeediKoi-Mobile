import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedikoi/shared/widgets/pills.dart';
import 'package:feedikoi/shared/widgets/rtsp_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/cards.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/utils/feeding_time_util.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';

class DashboardPage extends StatefulWidget {
  final FeedikoiService service;
  const DashboardPage({super.key, required this.service});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  List<String> _feedTimes = [];
  bool _systemOn = false;
  int _currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    // Update time every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    widget.service.getSettingsStream().listen((settings) {
      setState(() {
        _feedTimes = settings.feedTime;
      });
    });

    widget.service.getCurrentDataStream().listen((data) {
      setState(() {
        _systemOn = data.systemOn;
        if(data.timeStamp != null){
          DateTime deviceStartDate;
          if(data.timeStamp is Timestamp){
            deviceStartDate = (data.timeStamp as Timestamp).toDate();
          }else if (data.timeStamp is DateTime){
            deviceStartDate = data.timeStamp as DateTime;
          }else{
            deviceStartDate = DateTime.now();
            print("data.timeStamp is in a different format");
          }
          _currentMonth = ((DateTime.now().year - deviceStartDate.year) * 12) + DateTime.now().month - deviceStartDate.month + 1;
        }
      });
    });

  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH.mm');
    final dateFormat = DateFormat('EEEE, d MMM y');
    final nextFeedingDuration = FeedingTimeUtil.getTimeUntilNextFeeding(_feedTimes);

    return SingleChildScrollView(
      child: Column(
        children: [
          CustomCard(
            backgroundColor: Colors.grey[100],
            margin: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Kolam - 1",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          mainAxisAlignment: MainAxisAlignment.center,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Bulan ke -",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "1",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 64,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomCard(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "System Time",
                              style: TextStyle(fontSize: 16),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    timeFormat.format(_currentTime),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                    ),
                                  ),
                                  Text(
                                    "WIB",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              dateFormat.format(_currentTime),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              /*Row(
                children: [
                  Expanded(
                    child: InfoPill(
                      label: "System Status",
                      statusText: _systemOn ? "ON" : "OFF",
                      isSystem: true,
                      colorOverride: _systemOn ? Colors.greenAccent[100] : Colors.redAccent[100],
                    ),
                  )
                ],
              )*/
            ],
          ),
          CustomCard(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            backgroundColor: Colors.grey[100],
            padding: EdgeInsets.all(10),
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InfoPill(
                          label: "Waktu Pemberian Makan",
                          statusText: FeedingTimeUtil.formatDuration(nextFeedingDuration),
                          subtitle: "Jadwal berikutnya",
                          isSystem: false,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<double>(
                          stream: widget.service.getCurrentWeightStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              print('Weight stream error: ${snapshot.error}');
                              return InfoPill(
                                label: "Berat Pakan",
                                statusText: "Error",
                                subtitle: "Gagal mengambil data",
                                isSystem: false,
                              );
                            }
                            
                            if (!snapshot.hasData) {
                              return InfoPill(
                                label: "Berat Pakan",
                                statusText: "Loading...",
                                subtitle: "Mengambil data",
                                isSystem: false,
                              );
                            }
                            
                            final weight = snapshot.data!;
                            print('Received weight: $weight'); // Debug print
                            final weightText = "${weight.toStringAsFixed(1)}g";
                            
                            return InfoPill(
                              label: "Berat Pakan",
                              statusText: weightText,
                              subtitle: "Updated",
                              isSystem: false,
                            );
                          },
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
          StreamBuilder<List<FeedHistoryEntry>>(
            stream: widget.service.getHistoryStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final history = snapshot.data!;

              if (history.isEmpty){
                return CustomCard(
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  padding: EdgeInsets.all(10),
                  backgroundColor: Colors.grey[100],
                  children: [
                    Column(
                      children: [
                        Row(
                          children: const [
                            Text("Aktivitas")
                          ],
                        ),
                        Column(
                          children: const [
                            Text("Alat belum melakukan logging")
                          ]
                            
                        )
                      ],
                    )
                  ],
                );
              }

              final dateFormatter = DateFormat('dd/MM/yyyy');

              return CustomCard(
                margin: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                padding: EdgeInsets.all(10),
                children: [
                  Column(
                    children: [
                      Row(
                        children: const [
                          Text("Aktivitas")
                        ],
                      ),
                      Column(
                        children: history.take(2).map((entry) {
                          return Row(
                            children: [
                              Expanded(
                                child: InfoPill(
                                  label: "Pemberian Makan",
                                  statusText: dateFormatter.format(entry.time),
                                  subtitle: entry.success ? "Berhasil" : "Gagal",
                                  colorOverride: entry.success ? Colors.greenAccent[100] : Colors.redAccent[100],
                                  isSystem: false,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    ],
                  )
                ],
              );
            }
          ),
          RTSPCard()
        ],
      ),
    );
  }
}