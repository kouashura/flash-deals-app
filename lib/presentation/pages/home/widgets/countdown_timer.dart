import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final Color color;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.color = Colors.white,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.endTime.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(_two(_remaining.inHours)),
        const Text(' : '),
        _box(_two(_remaining.inMinutes % 60)),
        const Text(' : '),
        _box(_two(_remaining.inSeconds % 60)),
      ],
    );
  }

  Widget _box(String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          v,
          style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
}
