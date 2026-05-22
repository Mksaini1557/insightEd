import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/touch_reader.dart';

class TopicDetail extends StatefulWidget {
  final Map<String, dynamic> topicData;
  final String title;

  const TopicDetail({super.key, required this.topicData, required this.title});

  @override
  State<TopicDetail> createState() => _TopicDetailState();
}

class _TopicDetailState extends State<TopicDetail> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;
  bool _isSpeaking = false;

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
    final content = widget.topicData['content'] as String? ?? '';
    final hasContent = content.isNotEmpty;
    final hasPdf = widget.topicData['pdfUrl'] != null && (widget.topicData['pdfUrl'] as String).isNotEmpty;
    _flutterTts.speak(
      '${widget.title}. '
      '${hasContent ? "Content is available. Tap Read Aloud to listen." : ""} '
      '${hasPdf ? "A PDF document is available for this topic." : ""} '
    );
  }

  Future<void> _readContent() async {
    final content = widget.topicData['content'] as String? ?? '';
    if (content.isEmpty) {
      _flutterTts.speak('No content available for this topic.');
      return;
    }
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(content);
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _openPdf() async {
    final pdfUrl = widget.topicData['pdfUrl'] as String? ?? '';
    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available for this topic')),
      );
      return;
    }
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF link')),
        );
      }
    }
  }

  Future<void> _openTextFile() async {
    final fileUrl = widget.topicData['fileUrl'] as String? ?? '';
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text file available for this topic')),
      );
      return;
    }
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    final content = widget.topicData['content'] as String? ?? '';
    final pdfUrl = widget.topicData['pdfUrl'] as String? ?? '';
    final fileUrl = widget.topicData['fileUrl'] as String? ?? '';
    final hasContent = content.isNotEmpty;
    final hasPdf = pdfUrl.isNotEmpty;
    final hasFile = fileUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (hasContent)
            IconButton(
              icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
              tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
              onPressed: _readContent,
            ),
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
          child: Column(children: [
            // Content area
            Expanded(
              child: hasContent
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        content,
                        style: const TextStyle(fontSize: 17, height: 1.7, color: Color(0xFF212121)),
                      ),
                    )
                  : Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.description, size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
                        const SizedBox(height: 8),
                        const Text('Topic content will appear here', style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
            ),
            // Action buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECFF),
                border: Border(top: BorderSide(color: Color(0xFF4A6CF7), width: 1)),
              ),
              child: Row(children: [
                // Read Aloud button
                Expanded(
                  child: TouchableZone(
                    label: _isSpeaking ? 'Stop reading' : 'Read aloud',
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeaking ? Colors.red : const Color(0xFF4A6CF7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _readContent();
                        },
                        icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up, color: Colors.white, size: 20),
                        label: Text(_isSpeaking ? 'STOP' : 'READ ALOUD',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                // PDF button
                if (hasPdf) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TouchableZone(
                      label: 'Open PDF document',
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _openPdf();
                          },
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                          label: const Text('OPEN PDF',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
                // TXT file button
                if (hasFile && !hasPdf) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TouchableZone(
                      label: 'Open text file',
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _openTextFile();
                          },
                          icon: const Icon(Icons.text_snippet, color: Colors.white, size: 20),
                          label: const Text('OPEN FILE',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
