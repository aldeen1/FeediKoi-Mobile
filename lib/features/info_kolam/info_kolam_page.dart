import 'package:feedikoi/shared/widgets/fish_card.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pills.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart';
import 'package:feedikoi/services/feedikoi_service.dart';

class InfoKolamPage extends StatelessWidget {
  final FeedikoiService service;
  const InfoKolamPage({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomCard(
              backgroundColor: Colors.grey[100],
              margin: EdgeInsets.symmetric(horizontal: 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomCard(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                      "20.00",
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
                                "Sunday, 18th May 2025",
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

                Row(
                  children: [
                    Expanded(
                      child: InfoPill(
                        label: "System Status",
                        statusText: "ON",
                        isSystem: true,
                      ),
                    )
                  ],
                )
              ],
            ),
            FishCameraCard(appKey: '4670d7f3851a4f64931bd0078570427f', appSecret: 'a85ee950af884889a2ca179b5b48ac82', cameraSerial: 'BB9582723', averageLengthCm: 10,),
            CustomCard(
              margin: EdgeInsetsGeometry.symmetric(horizontal: 16),
              backgroundColor: Colors.grey[200],
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Fish Growth Over Time", style: TextStyle(fontSize: 16)),
                      Column(
                        children: [
                          SizedBox(
                            height: 260,
                            child: FishGrowthLineChart(
                              stream: service.getGrowthStream(),
                              xLabel: "Day",
                              yLabel: "Length (cm)",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
