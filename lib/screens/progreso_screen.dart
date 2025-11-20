// lib/screens/progreso_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:organizate/widgets/custom_nav_bar.dart';

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  DocumentReference<Map<String, dynamic>>? _userDocRef;
  CollectionReference<Map<String, dynamic>>? _tasksCollection;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      _tasksCollection = _userDocRef!.collection('tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    const int screenIndex = 5;

    if (_userDocRef == null || _tasksCollection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: screenIndex),
      appBar: AppBar(
        title: const Text('Progreso'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _userDocRef!.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final userData = snapshot.data?.data() ?? {};
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
              final String? avatarName = userData['avatar'] as String?;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (avatarName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            AssetImage('assets/avatars/$avatarName.png'),
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                  if (avatarName == null)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tasksCollection!.where('done', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Error al cargar progreso: ${snapshot.error}');
            return const Center(child: Text('Error al cargar datos'));
          }
          final tasks = snapshot.data?.docs ?? [];
          final Map<String, double> categoryCounts = {
            'Estudios': 0.0,
            'Hogar': 0.0,
            'Meds': 0.0,
            'Foco': 0.0,
            'General': 0.0,
          };

          for (final task in tasks) {
            final data = task.data();
            final category = data['category'] as String?;
            if (category != null && categoryCounts.containsKey(category)) {
              categoryCounts[category] =
                  (categoryCounts[category] ?? 0.0) + 1.0;
            } else {
              categoryCounts['General'] =
                  (categoryCounts['General'] ?? 0.0) + 1.0;
            }
          }

          final double maxY = categoryCounts.values.fold<double>(
            0,
            (previous, value) => value > previous ? value : previous,
          );
          final bool hasCompleted = tasks.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tareas completadas por categoría',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY + 2,
                      barTouchData: const BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              switch (value.toInt()) {
                                case 0:
                                  text = 'Estudios';
                                  break;
                                case 1:
                                  text = 'Hogar';
                                  break;
                                case 2:
                                  text = 'Meds';
                                  break;
                                case 3:
                                  text = 'Foco';
                                  break;
                                case 4:
                                  text = 'General';
                                  break;
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(text, style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                      ),
                      barGroups: [
                        _buildBar(0, categoryCounts['Estudios'] ?? 0, Colors.orange),
                        _buildBar(1, categoryCounts['Hogar'] ?? 0, Colors.green),
                        _buildBar(2, categoryCounts['Meds'] ?? 0, Colors.red),
                        _buildBar(3, categoryCounts['Foco'] ?? 0, Colors.purple),
                        _buildBar(4, categoryCounts['General'] ?? 0, Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (!hasCompleted) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Completa algunas tareas para ver más progreso 💪',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
