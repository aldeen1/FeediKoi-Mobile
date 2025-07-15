import 'package:feedikoi/shared/widgets/fish_card.dart';
import 'package:feedikoi/shared/widgets/pills.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/cards.dart';
import 'package:feedikoi/services/feedikoi_service.dart';

class DashboardPage extends StatelessWidget {
  final FeedikoiService service;
  const DashboardPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          CustomCard(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            backgroundColor: Colors.grey[100],
            padding: EdgeInsets.all(10),
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: InfoPill(label: "Waktu Pemberian Makan", statusText: "180 menit", subtitle: "Good", isSystem: false,)),
                    ],
                  ),
                  Row(
                      children: [
                        Expanded(child: InfoPill(label: "Berat Pakan", statusText: "90%", subtitle: "Good", isSystem: false,))
                      ],
                  )
                ],
              )
            ]
          ),
          CustomCard(
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            padding: EdgeInsets.all(10),
            children: [
            Column(
              children: [
                Row(
                  children: [
                  Text("Aktivitas")
                ],),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: InfoPill(label: "Pemberian Makan", statusText: "19/05/2025", subtitle: "Berhasil", isSystem: false,)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: InfoPill(label: "Pemberian Makan", statusText: "18/05/2025", subtitle: "Berhasil", isSystem: false,)),
                      ],
                    )
                  ],
                )
              ],
            )
          ]),
          FishCameraCard(cameraSerial: '1', appKey: 'appKey', appSecret: '', accessToken: '', averageLengthCm: 10)
        ],
      ),
    );
  }
}