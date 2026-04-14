import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordDetailPage extends StatelessWidget {
  final Map<String, dynamic> record;

  const RecordDetailPage({super.key, required this.record});

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분 ${seconds}초';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final Timestamp timestamp = record['timestamp'];

    final DateTime dateTime = timestamp.toDate();
    final DateTime dateTime2 = dateTime.add(const Duration(hours: 9));
    final String formattedDate = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(dateTime2);

    final int bpm = record['bpm'];
    final int runningTime = record['time']; // ⏱️
    final String runningTimeFormatted = _formatDuration(runningTime);
    final double distance = record['kilometers'];       // 📏
    final int calories = record['calories'];          // 🔥
    final String pace = record['pace']; // 🏃
    print("record['time']: ${record['time']}");

    return Scaffold(
      backgroundColor: const Color(0xFFFF670C),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF670C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('기록 상세', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.directions_run, size: 60, color: Color(0xFFFF670C)),
                ),
                const SizedBox(height: 20),
                Text('📅 날짜', style: _labelStyle()),
                Text(formattedDate, style: _valueStyle()),
                const SizedBox(height: 16),
                Text('🎵 BPM', style: _labelStyle()),
                Text('$bpm bpm', style: _valueStyle()),
                const SizedBox(height: 16),
                Text('⏱️ 달린 시간', style: _labelStyle()),
                Text(runningTimeFormatted, style: _valueStyle()),
                const SizedBox(height: 16),
                Text('📏 달린 거리', style: _labelStyle()),
                Text('${distance.toStringAsFixed(2)} km', style: _valueStyle()),
                const SizedBox(height: 16),
                Text('🔥 소모 칼로리', style: _labelStyle()),
                Text('$calories kcal', style: _valueStyle()),
                const SizedBox(height: 16),
                Text('🏃 평균 페이스', style: _labelStyle()),
                Text(pace, style: _valueStyle()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black54,
  );

  TextStyle _valueStyle() => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
}
