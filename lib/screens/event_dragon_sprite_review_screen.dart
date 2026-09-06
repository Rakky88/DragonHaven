import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const eventDragonReviewFamilies = <EventDragonReviewFamily>[
  EventDragonReviewFamily('halloween', 'Halloween', 'gloamgourd', 'Gloamgourd'),
  EventDragonReviewFamily('christmas', 'Christmas', 'hollyfrost', 'Hollyfrost'),
  EventDragonReviewFamily(
      'new_year', "New Year's Day", 'dawnchime', 'Dawnchime'),
  EventDragonReviewFamily(
      'valentines', "Valentine's Day", 'rosevow', 'Rosevow'),
  EventDragonReviewFamily(
      'pridefest', 'Pridefest', 'spectrumplume', 'Spectrumplume'),
];

const _forms = <(String, String)>[
  ('hatchling', 'Hatchling'),
  ('wyrmling', 'Wyrmling'),
  ('might', 'Ascended · Might'),
  ('arcana', 'Ascended · Arcana'),
  ('spirit', 'Ascended · Spirit'),
  ('mastery', 'Ascended · Mastery'),
];

const _notesKey = 'dragonhaven_event_dragon_review_notes_v1';
const _pageKey = 'dragonhaven_event_dragon_review_page_v1';
const _blue = Color(0xFF1976D2);

class EventDragonReviewFamily {
  const EventDragonReviewFamily(
      this.eventId, this.eventName, this.id, this.name);
  final String eventId;
  final String eventName;
  final String id;
  final String name;

  String asset(String form) =>
      'future_event_art/dragon_families/$eventId/sprites/${id}_$form.webp';
}

class EventDragonSpriteReviewApp extends StatelessWidget {
  const EventDragonSpriteReviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Event dragon review',
        theme: buildAppTheme(),
        home: const EventDragonSpriteReviewScreen(),
      );
}

class EventDragonSpriteReviewScreen extends StatefulWidget {
  const EventDragonSpriteReviewScreen({super.key});

  @override
  State<EventDragonSpriteReviewScreen> createState() =>
      _EventDragonSpriteReviewScreenState();
}

class _EventDragonSpriteReviewScreenState
    extends State<EventDragonSpriteReviewScreen> {
  SharedPreferences? _preferences;
  final Map<String, String> _notes = {};
  var _page = 0;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_notesKey);
    final stored = encoded == null
        ? const <String, dynamic>{}
        : jsonDecode(encoded) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _notes.addAll(stored.map((key, value) => MapEntry(key, '$value')));
      _page = (preferences.getInt(_pageKey) ?? 0)
          .clamp(0, eventDragonReviewFamilies.length - 1);
      _ready = true;
    });
  }

  Future<void> _inspect(
      EventDragonReviewFamily family, (String, String) form) async {
    final id = '${family.id}-${form.$1}';
    final controller = TextEditingController(text: _notes[id] ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF17112F),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${family.name} · ${form.$2}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ),
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(builder: (_, constraints) {
                    final size =
                        math.min(constraints.maxWidth, constraints.maxHeight);
                    return Center(
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFFFFD86E), width: 3),
                        ),
                        child: InteractiveViewer(
                          maxScale: 5,
                          child: Image.asset(family.asset(form.$1),
                              fit: BoxFit.contain),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('event-review-note'),
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Describe what should be fixed…',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, ''),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Looks good'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('event-review-save'),
                      onPressed: () => Navigator.pop(context, controller.text),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save note'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() {
      if (result.trim().isEmpty) {
        _notes.remove(id);
      } else {
        _notes[id] = result.trim();
      }
    });
    await _preferences?.setString(_notesKey, jsonEncode(_notes));
  }

  Future<void> _move(int delta) async {
    setState(() =>
        _page = (_page + delta).clamp(0, eventDragonReviewFamilies.length - 1));
    await _preferences?.setInt(_pageKey, _page);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final family = eventDragonReviewFamilies[_page];
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event dragon review'),
            Text('Tap a sprite to zoom or add a note',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              isLabelVisible: _notes.isNotEmpty,
              label: Text('${_notes.length}'),
              child: const Icon(Icons.rate_review_rounded),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF25164D), Color(0xFF67449A)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  Text(family.eventName,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Text('${_page + 1}/${eventDragonReviewFamilies.length}',
                style: const TextStyle(
                    color: Color(0xFFFFD86E), fontWeight: FontWeight.w900)),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .82,
            ),
            itemCount: _forms.length,
            itemBuilder: (_, index) {
              final form = _forms[index];
              final note = _notes['${family.id}-${form.$1}'];
              return Material(
                color: note == null ? Colors.white : const Color(0xFFFFE1DF),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('event-review-${family.id}-${form.$1}'),
                  onTap: () => _inspect(family, form),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(family.asset(form.$1),
                              fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(form.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      Text(note == null ? 'Tap to inspect' : 'NOTE SAVED',
                          style: TextStyle(
                              color: note == null
                                  ? AppColors.muted
                                  : AppColors.coral,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(children: [
            IconButton.outlined(
              key: const Key('event-review-previous'),
              onPressed: _page == 0 ? null : () => _move(-1),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('event-review-next'),
                onPressed: _page == eventDragonReviewFamilies.length - 1
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next family'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
