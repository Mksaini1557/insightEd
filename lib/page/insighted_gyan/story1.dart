import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/touch_reader.dart';
import 'topic_list.dart';

class InsightEdGyan extends StatefulWidget {
  const InsightEdGyan({super.key});

  @override
  State<InsightEdGyan> createState() => _InsightEdGyanState();
}

class _InsightEdGyanState extends State<InsightEdGyan> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    if (mounted) setState(() => _ttsReady = true);
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    _flutterTts.speak(
      'insightED Gyan. Browse courses organized by category. Slide your finger to explore.',
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('insightED Gyan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gyan_categories')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4A6CF7)));
              }

              List<Map<String, dynamic>> categories;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final orderA = (a.data() as Map<String, dynamic>)['order'] ?? 0;
                  final orderB = (b.data() as Map<String, dynamic>)['order'] ?? 0;
                  return (orderA as num).compareTo(orderB as num);
                });
                categories = docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': d['name'] ?? 'Unnamed',
                    'icon': d['icon'] ?? 'menu_book',
                    'color': d['color'] ?? '#4A6CF7',
                  };
                }).toList();
              } else {
                // Fallback hardcoded categories
                categories = [
                  {'id': 'technical', 'name': 'Technical Courses', 'icon': 'code', 'color': '#4A6CF7'},
                  {'id': 'science', 'name': 'Science', 'icon': 'science', 'color': '#009688'},
                  {'id': 'history', 'name': 'History', 'icon': 'history_edu', 'color': '#FF5722'},
                  {'id': 'language', 'name': 'Language & Arts', 'icon': 'translate', 'color': '#7C4DFF'},
                  {'id': 'general', 'name': 'General Knowledge', 'icon': 'lightbulb', 'color': '#FFC107'},
                ];
              }

              return GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: categories.map((cat) {
                  final color = _parseColor(cat['color'] as String? ?? '#4A6CF7');
                  final icon = _parseIcon(cat['icon'] as String? ?? 'menu_book');
                  final name = cat['name'] as String;
                  final id = cat['id'] as String;

                  return _CategoryCard(
                    label: name,
                    icon: icon,
                    color: color,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _flutterTts.speak(name);
                      _flutterTts.stop();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => TopicList(categoryId: id, categoryName: name),
                      ));
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4A6CF7);
    }
  }

  IconData _parseIcon(String name) {
    switch (name) {
      case 'code': return Icons.code;
      case 'science': return Icons.science;
      case 'history_edu': return Icons.history_edu;
      case 'translate': return Icons.translate;
      case 'lightbulb': return Icons.lightbulb;
      case 'school': return Icons.school;
      case 'psychology': return Icons.psychology;
      case 'computer': return Icons.computer;
      default: return Icons.menu_book;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label, required this.icon, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 44, color: Colors.white),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}
