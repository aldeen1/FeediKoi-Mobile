import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/shared/widgets/rtsp_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/cards.dart';
import 'package:feedikoi/services/feedikoi_service.dart';

class InfoKolamPage extends StatefulWidget {
  final FeedikoiService service;
  const InfoKolamPage({super.key, required this.service});

  @override
  State<InfoKolamPage> createState() => _InfoKolamPageState();
}

class _InfoKolamPageState extends State<InfoKolamPage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
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
                              StreamBuilder<CurrentData>(
                                stream: widget.service.getCurrentDataStream(),
                                builder: (context, snapshot) {
                                  int month = 1;
                                  if (snapshot.hasData) {
                                    final data = snapshot.data!;
                                    if (data.timeStamp != null) {
                                      DateTime deviceStartDate;
                                      if (data.timeStamp is Timestamp) {
                                        deviceStartDate = (data.timeStamp as Timestamp).toDate();
                                      } else if (data.timeStamp is DateTime) {
                                        deviceStartDate = data.timeStamp as DateTime;
                                      } else {
                                        deviceStartDate = DateTime.now();
                                      }
                                      month = ((DateTime.now().year - deviceStartDate.year) * 12) + 
                                             DateTime.now().month - deviceStartDate.month + 1;
                                    }
                                  }
                                  return Text(
                                    month.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 64,
                                    ),
                                  );
                                }
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
              ],
            ),
            CustomCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.all(10),
              children: [
                RTSPCard(),
              ],
            ),
            CustomCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.all(10),
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Fish Growth Over Time", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: Center(
                        child: Text(
                          "Growth data will be shown here",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
