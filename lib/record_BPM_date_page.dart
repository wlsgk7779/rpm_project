import 'package:flutter/material.dart';
import 'goal_detail.dart';
import 'record_dis_page.dart';
import 'record_set_page.dart';
import 'record_BPM_bpm_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'record_detail_page.dart';

class RecordBpDatePage extends StatefulWidget {
  const RecordBpDatePage({super.key});

  @override
  State<RecordBpDatePage> createState() => _RecordBpDatePageState();
}

class _RecordBpDatePageState extends State<RecordBpDatePage> {
  String sortOption = '날짜순';
  List<Map<String, dynamic>> records = []; // 날짜와 bpm 데이터를 담을 리스트

  @override
  void initState() {
    super.initState();
    _fetchRecords();  // 페이지 로드되면 데이터 불러오기
  }

  Future<void> _fetchRecords() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('유저가 로그인하지 않았어요!');
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('runs')
          .orderBy('timestamp', descending: true)
          .get();
      print('🔥22222222222 snapshot.docs.length = ${snapshot.docs.length}');
      List<Map<String, dynamic>> loadedRecords = snapshot.docs.map((doc) {
        return {
          'timestamp': doc['timestamp'],  // 날짜 필드 이름 맞게 바꾸기
          'bpm': doc['bpm'],    // bpm 필드 이름 맞게 바꾸기
          'id': doc.id,         // 필요하면 문서 id도 저장
          'time': doc['time'],               // int (초 단위 달린 시간)
          'kilometers': doc['kilometers'],   // double
          'calories': doc['calories'],       // int
          'pace': doc['pace'],               // String
        };
      }).toList();

      setState(() {
        records = loadedRecords;
      });
    } catch (e) {
      print('Error fetching records: $e');
    }
  }

  void _onTapRecord(int index) {
    if (index < records.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecordDetailPage(record: records[index]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalRowCount = records.length;  // 파이어스토어에서 가져온 만큼만 보여주기

    return Scaffold(
      backgroundColor: const Color(0xFFFF670C),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바, 드롭다운, 헤더 등 기존 코드 유지...
            const SizedBox(height: 12),

            // ✅ 상단 바
            Row(
              children: [
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordPage()),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 35, color: Colors.black),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Row(
                    children: const [
                      Icon(Icons.local_fire_department, size: 27),
                      SizedBox(width: 4),
                      Text(
                        "record (bpm 설정)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Spacer(),
                  DropdownButton<String>(
                    value: sortOption,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: Container(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    dropdownColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        sortOption = value!;
                        if (sortOption == '날짜순') {
                          records.sort((a, b) {
                            final Timestamp aTime = a['timestamp'];
                            final Timestamp bTime = b['timestamp'];
                            return bTime.compareTo(aTime); // 최신순 내림차순
                          });
                        } else if (sortOption == 'bpm순') {
                          records.sort((a, b) {
                            return b['bpm'].compareTo(a['bpm']); // bpm 높은순 내림차순
                          });
                        }
                      });
                    },
                    items: ['날짜순', 'bpm순'].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1.5, color: Colors.black),

            // ✅ 헤더
            Row(
              children: const [
                SizedBox(width: 20),
                Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                VerticalDivider(width: 1, thickness: 1, color: Colors.black),
                SizedBox(width: 20),
                Text('기록', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const Divider(thickness: 1.5, color: Colors.black),


            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    left: 60,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.black),
                  ),

                  ListView.separated(
                    itemCount: totalRowCount,
                    separatorBuilder: (_, __) => const Divider(thickness: 1, color: Colors.black),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      // 날짜랑 bpm을 "2025.03.25 | 120 bpm" 형태로 묶기
                      final Timestamp timestamp = record['timestamp'];
                      final DateTime dateTime = timestamp.toDate();
                      final DateTime dateTime2 = dateTime.add(const Duration(hours: 9));
                      final String formattedDate = DateFormat('yyyy.MM.dd').format(dateTime2);
                      final text = '$formattedDate | ${record['bpm']} bpm';

                      return GestureDetector(
                        onTap: () => _onTapRecord(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 36),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
