import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/cards.dart';
import 'package:feedikoi/shared/widgets/pills.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticPakanPage extends StatelessWidget {
  StatisticPakanPage({super.key, required this.service});

  final FeedikoiService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedHistoryEntry>>(
        stream: service.getHistoryStream(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data!;

          if(history.isEmpty){
            return const Center(child: Text("Tidak ada data"));
          }

          final grouped = <String, List<FeedHistoryEntry>>{};
          for (var entry in history){
            final date = DateFormat('yyyy-MM-dd').format(entry.time);
            grouped.putIfAbsent(date, () => []).add(entry);
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: grouped.entries.map((entry){
              final date = entry.key;
              final entries = entry.value;

              return CustomCard(
                backgroundColor: Colors.grey[200],
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(date)),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400
                      ),
                    ),
                  ),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Times fed : "),
                        SizedBox(width: 8,),
                        Text(entries.length.toString(),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                          ),
                        )
                      ],
                    )
                  ]),
                  ...entries.map((e){
                    return InfoPill(
                        labelWidget: Text(
                          DateFormat('hh:mm a').format(e.time),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        colorOverride: e.success ? Colors.green[100] : Colors.red[100],
                        statusText: e.success ? "Berhasil" : "Gagal",
                    );
                  }).toList(),
                ]
              );
            }).toList(),
          );
        }
    );
  }
}
