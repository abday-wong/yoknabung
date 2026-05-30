import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'neo_card.dart';

class RealtimeClockWidget extends StatefulWidget {
  const RealtimeClockWidget({super.key});

  @override
  State<RealtimeClockWidget> createState() => _RealtimeClockWidgetState();
}

class _RealtimeClockWidgetState extends State<RealtimeClockWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('HH:mm:ss');
    final DateFormat dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    return NeoCard(
      color: const Color(0xFFFFE500),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeFormat.format(_now),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(_now),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
