import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/touch_reader.dart';
import 'story_reader.dart';

class StoryTelling extends StatefulWidget {
  const StoryTelling({super.key});

  @override
  State<StoryTelling> createState() => _StoryTellingState();
}

class _StoryTellingState extends State<StoryTelling> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;
  bool _ttsReady = false;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

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
    _flutterTts.speak('Story Telling. ${_categories.length - 1} categories available. Tap any story to listen, or use the chips at the top to filter by category.');
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
        title: const Text('Story Telling'),
        actions: [
          IconButton(icon: const Icon(Icons.volume_up), tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('stories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4A6CF7)));
              }

              if (snapshot.hasError) {
                return _buildError('Permission denied. Check Firestore rules for stories collection.');
              }

              // Always start with fallback stories
              List<Map<String, dynamic>> allStories = _getFallbackStories();

              // Merge in Firestore stories (they override fallbacks by id)
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final dbStories = snapshot.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {'id': d.id, ...data};
                }).toList();
                // Add all DB stories (deduplicate by title)
                for (final dbStory in dbStories) {
                  final dbTitle = (dbStory['title'] as String?)?.trim().toLowerCase() ?? '';
                  allStories.removeWhere((s) => (s['title'] as String?)?.trim().toLowerCase() == dbTitle);
                  allStories.add(dbStory);
                }
              }

              allStories.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));

              // Build category list
              final cats = <String>{'All'};
              for (final s in allStories) {
                final cat = (s['category'] as String?)?.trim() ?? 'Moral';
                if (cat.isNotEmpty) cats.add(cat);
              }
              _categories = cats.toList();

              // Filter by selected category
              final displayStories = _selectedCategory == 'All'
                  ? allStories
                  : allStories.where((s) => ((s['category'] as String?)?.trim() ?? 'Moral') == _selectedCategory).toList();

              return Column(children: [
                // Category filter chips
                Container(
                  width: double.infinity,
                  color: const Color(0xFFE8ECFF),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TouchableZone(
                            label: 'Filter: $cat stories',
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _flutterTts.speak('Showing $cat stories');
                                setState(() => _selectedCategory = cat);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF4A6CF7) : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFF4A6CF7), width: 1.5),
                                ),
                                child: Text(
                                  '$cat (${cat == 'All' ? allStories.length : allStories.where((s) => (s['category'] as String?)?.trim() == cat).length})',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF4A6CF7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Stories grid
                Expanded(
                  child: displayStories.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.auto_stories, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No $_selectedCategory stories yet', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 4),
                            const Text('Add stories via the Admin Portal', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ]),
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(14),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                          children: displayStories.map((story) {
                            final title = (story['title'] as String?) ?? 'Untitled';
                            final category = (story['category'] as String?) ?? 'Moral';
                            final color = _parseColor(story['color'] as String?);
                            return _StoryCard(
                              title: title,
                              category: category,
                              color: color,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _flutterTts.stop();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => StoryReader(storyData: story),
                                ));
                              },
                            );
                          }).toList(),
                        ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFallbackStories() {
    return [
      {'id': '1', 'title': 'The Lion and the Mouse', 'category': 'Moral', 'color': '#FFC107', 'content': 'Once upon a time, a mighty lion was sleeping in the forest. A little mouse accidentally ran across the lion\'s nose, waking him up. The lion caught the mouse and was about to eat him. "Please let me go!" begged the mouse. "One day I will repay your kindness." The lion laughed at the idea of a tiny mouse helping him, but let the mouse go. Some days later, the lion was caught in a hunter\'s net. He roared for help. The little mouse heard him and came running. The mouse gnawed through the ropes and set the lion free. "You laughed at me once," said the mouse, "but now you see that even a little mouse can help a big lion." Moral: Kindness is never wasted.'},
      {'id': '2', 'title': 'The Milkmaid and Her Pail', 'category': 'Fable', 'color': '#4CAF50', 'content': 'A milkmaid was walking to the market carrying a pail of milk on her head. As she walked, she began to daydream. "I will sell this milk and buy some eggs. The eggs will hatch into chickens. I will sell the chickens and buy a beautiful dress." As she tossed her head imagining, the pail of milk fell and spilled all over the ground. Her dreams vanished with the spilled milk. Moral: Do not count your chickens before they hatch.'},
      {'id': '3', 'title': 'Two Frogs', 'category': 'Moral', 'color': '#E53935', 'content': 'Two frogs fell into a deep pit. The other frogs gathered around and said there was no way out. One frog gave up and died. The other kept jumping with all his might and finally leaped out. He was deaf and thought the crowd was cheering for him. Moral: Words have power. Encouragement lifts people up, discouragement destroys them.'},
      {'id': '4', 'title': 'The Elephant and the Ant', 'category': 'Fable', 'color': '#2196F3', 'content': 'A proud elephant always bullied smaller animals. One day, he got a thorn stuck in his foot. He cried in pain but could not pull it out. A tiny ant crawled into his foot and removed the thorn. The elephant thanked the ant and apologized. Moral: Never underestimate anyone based on their size.'},
      {'id': '5', 'title': 'The Hare and the Tortoise', 'category': 'Fable', 'color': '#FF9800', 'content': 'A hare made fun of a tortoise for being slow. The tortoise challenged him to a race. The hare sprinted ahead and, confident of winning, took a nap. The tortoise kept walking steadily and crossed the finish line while the hare slept. Moral: Slow and steady wins the race.'},
    ];
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.red)),
        ]),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF4A6CF7);
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF4A6CF7); }
  }
}

class _StoryCard extends StatelessWidget {
  final String title;
  final String category;
  final Color color;
  final VoidCallback onTap;

  const _StoryCard({required this.title, required this.category, required this.color, required this.onTap});

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
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_stories, size: 24, color: Colors.white70),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(category, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ]),
            const Spacer(),
            Text(title.replaceAll('\n', ' '), textAlign: TextAlign.left,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}
