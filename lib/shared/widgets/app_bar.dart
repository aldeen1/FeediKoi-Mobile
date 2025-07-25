import 'package:flutter/material.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:intl/intl.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FeedikoiService service;
  final bool hasUnreadNotifs;

  const CustomAppBar({
    super.key,
    required this.service,
    this.hasUnreadNotifs = false
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StreamBuilder<List<FeedHistoryEntry>>(
                          stream: service.getHistoryStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text(
                                "Menunggu aktivitas...",
                                style: TextStyle(fontSize: 14, color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              );
                            }

                            final latestEntry = snapshot.data!.first;
                            final timeFormat = DateFormat('HH:mm');
                            final statusText = latestEntry.success ? "Berhasil" : "Gagal";
                            
                            return Text(
                              "Pemberian pakan ${timeFormat.format(latestEntry.time)} - $statusText",
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Stack(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                    )
                  ),

                  // Red Dot
                  if (hasUnreadNotifs)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);


}