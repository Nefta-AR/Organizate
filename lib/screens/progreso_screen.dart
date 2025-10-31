// lib/screens/progreso_screen.dart
// --- CÓDIGO 100% CORREGIDO (AHORA SÍ) ---

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';
import 'package:fl_chart/fl_chart.dart'; // <-- ¡PAQUETE DE GRÁFICOS!

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  // Referencias a Firestore
  final DocumentReference userDocRef =
      FirebaseFirestore.instance.collection('users').doc('neftali_user');
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('users').doc('neftali_user').collection('tasks');

  @override
  Widget build(BuildContext context) {
    const int screenIndex = 5; // Índice 5 para "Progreso"

    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: screenIndex),
      appBar: AppBar(
        title: const Text('Progreso'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          // AppBar con Puntos/Racha/Avatar
          StreamBuilder<DocumentSnapshot>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final userData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
              final String? avatarName = userData['avatar'] as String?;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(children: [
                      Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 4),
                      Text('$streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ]),
                  ),
                  if (avatarName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage: AssetImage('assets/avatars/$avatarName.png'),
                        onBackgroundImageError: (e, s) {},
                      ),
                    ),
                  if (avatarName == null)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(radius: 15, backgroundColor: Colors.grey),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      // --- CUERPO CON EL GRÁFICO ---
      body: StreamBuilder<QuerySnapshot>(
        // 1. Obtenemos TODAS las tareas que estén COMPLETADAS (done == true)
        stream: tasksCollection.where('done', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // ¡¡¡AQUÍ IMPRIMIMOS EL ERROR DE FIREBASE!!!
            print('¡¡¡ERROR EN FIREBASE (PROGRESO): ${snapshot.error}!!!');
            return const Center(child: Text('Error al cargar datos del progreso'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes tareas completadas.\n¡Completa algunas para ver tu progreso!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 2. Procesamos los datos para el gráfico
          final tasks = snapshot.data!.docs;
          
          // Creamos un mapa para contar
          Map<String, double> categoryCounts = {
            'Estudios': 0.0,
            'Hogar': 0.0,
            'Meds': 0.0,
            'Foco': 0.0,
            'General': 0.0,
          };

          // Contamos las tareas completadas por categoría
          for (var task in tasks) {
            final data = task.data() as Map<String, dynamic>;
            final category = data['category'] as String?;
            if (category != null && categoryCounts.containsKey(category)) {
              categoryCounts[category] = categoryCounts[category]! + 1.0;
            } else {
              categoryCounts['General'] = categoryCounts['General']! + 1.0;
            }
          }

          // 3. Creamos el Gráfico de Barras
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tareas Completadas por Categoría',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Usamos AspectRatio para darle un tamaño al gráfico
                AspectRatio(
                  aspectRatio: 1.5, // Ancho 1.5 veces el alto
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (categoryCounts.values.reduce((a, b) => a > b ? a : b)) + 2, // El valor Y más alto + 2 de margen
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Etiquetas del eje X (Categorías)
                              String text = '';
                              switch (value.toInt()) {
                                case 0: text = 'Estudios'; break;
                                case 1: text = 'Hogar'; break;
                                case 2: text = 'Meds'; break;
                                case 3: text = 'Foco'; break;
                                case 4: text = 'General'; break;
                              }
                              // ¡¡¡ESTA ES LA LÍNEA 100% CORREGIDA!!!
                              return SideTitleWidget(meta: meta, child: Text(text, style: const TextStyle(fontSize: 10)));
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                      barGroups: [
                        // Creamos una barra para cada categoría
                        _buildBar(0, categoryCounts['Estudios']!, Colors.orange),
                        _buildBar(1, categoryCounts['Hogar']!, Colors.green),
                        _buildBar(2, categoryCounts['Meds']!, Colors.red),
                        _buildBar(3, categoryCounts['Foco']!, Colors.purple),
                        _buildBar(4, categoryCounts['General']!, Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Función de ayuda para crear una barra
  BarChartGroupData _buildBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x, // Posición en el eje X
      barRods: [
        BarChartRodData(
          toY: y, // Valor (altura de la barra)
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