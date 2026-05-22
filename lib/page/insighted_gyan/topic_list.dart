import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/touch_reader.dart';
import 'topic_detail.dart';

class TopicList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const TopicList({super.key, required this.categoryId, required this.categoryName});

  @override
  State<TopicList> createState() => _TopicListState();
}

class _TopicListState extends State<TopicList> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
  }

  void _announcePage() {
    if (_hasSpoken) return;
    _hasSpoken = true;
    _flutterTts.speak('${widget.categoryName} topics. Slide your finger to explore. Tap any topic to read it.');
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
        title: Text(widget.categoryName),
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
                .collection('gyan_topics')
                .where('category', isEqualTo: widget.categoryId)
                .orderBy('order', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4A6CF7)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final topics = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final doc = topics[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'Untitled Topic';
                  final description = data['description'] as String? ?? '';
                  final hasPdf = data['pdfUrl'] != null && (data['pdfUrl'] as String).isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TopicCard(
                      label: title,
                      description: description,
                      hasPdf: hasPdf,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _flutterTts.stop();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => TopicDetail(
                            topicData: data,
                            title: title,
                          ),
                        ));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No topics available yet',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add topics in the gyan_topics Firestore collection',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String label;
  final String description;
  final bool hasPdf;
  final VoidCallback onTap;

  const _TopicCard({
    required this.label,
    required this.description,
    required this.hasPdf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4A6CF7),
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.article, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 13, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (hasPdf) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    const Text('PDF available', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ]),
                ],
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ]),
        ),
      ),
    );
  }
}
