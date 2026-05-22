import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/touch_reader.dart';

class TopicList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const TopicList({super.key, required this.categoryId, required this.categoryName});

  @override
  State<TopicList> createState() => _TopicListState();
}

class _TopicListState extends State<TopicList> {
  final FlutterTts _flutterTts = FlutterTts();
  final PageController _pageController = PageController();
  bool _isReading = false;
  bool _ttsReady = false;
  bool _initialized = false;
  int _currentModule = 0;
  List<Map<String, dynamic>> _modules = [];
  List<String> _chunks = [];
  int _chunkIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    _flutterTts.setCompletionHandler(() {
      _speakNextChunk();
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isReading = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
  }

  void _speakNextChunk() {
    if (!_isReading || _chunks.isEmpty) {
      if (mounted) setState(() => _isReading = false);
      return;
    }
    _chunkIndex++;
    if (_chunkIndex < _chunks.length) {
      _flutterTts.speak(_chunks[_chunkIndex]);
    } else {
      if (mounted) setState(() => _isReading = false);
    }
  }

  void _announceCurrentModule() {
    if (_modules.isEmpty) return;
    _flutterTts.stop();
    final mod = _modules[_currentModule];
    _flutterTts.speak(
      'Module ${_currentModule + 1} of ${_modules.length}: ${mod['title']}. '
      'Use Previous and Next to navigate. Tap Read Aloud to hear content.',
    );
  }

  void _readCurrentModule() {
    if (_modules.isEmpty) return;
    if (_isReading) {
      _flutterTts.stop();
      setState(() => _isReading = false);
      return;
    }

    final content = _modules[_currentModule]['content'] as String? ?? '';
    final title = _modules[_currentModule]['title'] as String? ?? '';

    if (content.isEmpty) {
      _flutterTts.speak('No content available for this module.');
      return;
    }

    _flutterTts.stop();
    setState(() => _isReading = true);

    // Split content into chunks of ~500 chars to avoid TTS limits
    final fullText = '$title. $content';
    _chunks = [];
    _chunkIndex = -1;
    for (var i = 0; i < fullText.length; i += 500) {
      final end = (i + 500 < fullText.length) ? i + 500 : fullText.length;
      _chunks.add(fullText.substring(i, end));
    }
    // Start speaking first chunk
    _flutterTts.speak(_chunks[0]);
  }

  void _goToModule(int index) {
    if (index < 0 || index >= _modules.length) return;
    HapticFeedback.lightImpact();
    _flutterTts.stop();
    _isReading = false;
    _currentModule = index;
    setState(() {});
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final mod = _modules[_currentModule];
      _flutterTts.speak('Module ${_currentModule + 1} of ${_modules.length}: ${mod['title']}');
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: Icon(_isReading ? Icons.stop : Icons.volume_up),
            tooltip: _isReading ? 'Stop reading' : 'Read module aloud',
            onPressed: _readCurrentModule,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Repeat info',
            onPressed: _announceCurrentModule,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gyan_topics')
            .where('category', isEqualTo: widget.categoryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4A6CF7)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final oA = (a.data() as Map<String, dynamic>)['order'] ?? 0;
            final oB = (b.data() as Map<String, dynamic>)['order'] ?? 0;
            return (oA as num).compareTo(oB as num);
          });

          _modules = docs.map((d) => d.data() as Map<String, dynamic>).toList();

          if (_currentModule >= _modules.length) _currentModule = 0;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_initialized) {
              _initialized = true;
              _announceCurrentModule();
            }
          });

          return Column(children: [
            // Progress bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: const Color(0xFFE8ECFF),
              child: Column(children: [
                Row(children: [
                  Text('Module ${_currentModule + 1} of ${_modules.length}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2A3F8F))),
                  const Spacer(),
                  Text(_modules[_currentModule]['title'] as String? ?? '',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4A6CF7), fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_currentModule + 1) / _modules.length,
                  backgroundColor: Colors.grey.shade300,
                  color: const Color(0xFF4A6CF7),
                  minHeight: 4,
                ),
              ]),
            ),
            // Module content
            Expanded(
              child: TouchReader(
                tts: _flutterTts,
                child: Container(
                  color: Colors.white,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentModule = index;
                        _isReading = false;
                      });
                    },
                    itemCount: _modules.length,
                    itemBuilder: (context, index) {
                      final mod = _modules[index];
                      final title = mod['title'] as String? ?? '';
                      final content = mod['content'] as String? ?? '';
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7), height: 1.3)),
                          const SizedBox(height: 20),
                          Text(content.isNotEmpty ? content : 'No content for this module.',
                              style: const TextStyle(fontSize: 17, height: 1.8, color: Color(0xFF212121))),
                        ]),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Navigation buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECFF),
                border: Border(top: BorderSide(color: Color(0xFF4A6CF7), width: 1)),
              ),
              child: Row(children: [
                // Previous
                Expanded(
                  child: TouchableZone(
                    label: _currentModule > 0 ? 'Previous module' : 'No previous module',
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentModule > 0 ? const Color(0xFF4A6CF7) : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _currentModule > 0 ? () => _goToModule(_currentModule - 1) : null,
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          SizedBox(width: 2),
                          Text('PREV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Read Aloud
                Expanded(
                  child: TouchableZone(
                    label: _isReading ? 'Stop reading' : 'Read current module aloud',
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isReading ? Colors.red : const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _readCurrentModule,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_isReading ? Icons.stop : Icons.volume_up, color: Colors.white, size: 18),
                          const SizedBox(width: 2),
                          Text(_isReading ? 'STOP' : 'READ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Next
                Expanded(
                  child: TouchableZone(
                    label: _currentModule < _modules.length - 1
                        ? 'Next module: ${_modules.isNotEmpty && _currentModule < _modules.length - 1 ? _modules[_currentModule + 1]['title'] : ''}'
                        : 'No more modules',
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentModule < _modules.length - 1 ? const Color(0xFF4A6CF7) : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: _currentModule < _modules.length - 1 ? () => _goToModule(_currentModule + 1) : null,
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('NEXT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]);
        },
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
          const Text('No modules available yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add topics in the gyan_topics Firestore collection\nusing the Admin Portal',
              style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
