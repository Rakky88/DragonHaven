import 'dart:convert';

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _reviewBlue = Color(0xFF1976D2);
const _notesPreference = 'dragon_sprite_sixth_fix_review_notes_v1';
const _completedPreference = 'dragon_sprite_sixth_fix_review_completed_v1';
const _completedAtPreference = 'dragon_sprite_sixth_fix_review_completed_at_v1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('FIX_REVIEW: main');
  runApp(const DragonSpriteReviewApp());
}

class DragonSpriteReviewApp extends StatelessWidget {
  const DragonSpriteReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Review van zesde spritefix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D3F99),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F4FF),
        useMaterial3: true,
      ),
      home: const DragonSpriteReviewScreen(),
    );
  }
}

class _ReviewForm {
  const _ReviewForm({
    required this.id,
    required this.stageKey,
    required this.evolutionPath,
    required this.stageLabel,
  });

  final String id;
  final String stageKey;
  final String evolutionPath;
  final String stageLabel;

  String nameFor(DragonLineage lineage) => switch (id) {
        'hatchling' => '${lineage.nameEn} Hatchling',
        'wyrmling' => '${lineage.nameEn} Wyrmling',
        _ => lineage.formName(evolutionPath, false),
      };
}

const _reviewForms = <_ReviewForm>[
  _ReviewForm(
    id: 'hatchling',
    stageKey: 'spark',
    evolutionPath: 'might',
    stageLabel: 'Hatchling',
  ),
  _ReviewForm(
    id: 'wyrmling',
    stageKey: 'nestDragon',
    evolutionPath: 'might',
    stageLabel: 'Wyrmling',
  ),
  _ReviewForm(
    id: 'might',
    stageKey: 'homeGuardian',
    evolutionPath: 'might',
    stageLabel: 'Might',
  ),
  _ReviewForm(
    id: 'arcana',
    stageKey: 'homeGuardian',
    evolutionPath: 'arcana',
    stageLabel: 'Arcana',
  ),
  _ReviewForm(
    id: 'spirit',
    stageKey: 'homeGuardian',
    evolutionPath: 'spirit',
    stageLabel: 'Spirit',
  ),
  _ReviewForm(
    id: 'mastery',
    stageKey: 'homeGuardian',
    evolutionPath: 'mastery',
    stageLabel: 'Mastery',
  ),
];

const _fixedReviewForms = <String, Set<String>>{
  'everwyrm': {'spirit'},
};

List<_ReviewForm> _formsFor(DragonLineage lineage) {
  final ids = _fixedReviewForms[lineage.id] ?? const <String>{};
  return _reviewForms
      .where((form) => ids.contains(form.id))
      .toList(growable: false);
}

class DragonSpriteReviewScreen extends StatefulWidget {
  const DragonSpriteReviewScreen({super.key});

  @override
  State<DragonSpriteReviewScreen> createState() =>
      _DragonSpriteReviewScreenState();
}

class _DragonSpriteReviewScreenState extends State<DragonSpriteReviewScreen> {
  final _searchController = TextEditingController();
  Map<String, String> _notes = const {};
  bool _loading = true;
  bool _completed = false;
  String _query = '';

  int get _totalForms =>
      _fixedReviewForms.values.fold(0, (total, forms) => total + forms.length);
  int get _noteCount =>
      _notes.values.where((note) => note.trim().isNotEmpty).length;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    debugPrint('FIX_REVIEW: loading preferences');
    final preferences = await SharedPreferences.getInstance();
    final rawNotes = preferences.getString(_notesPreference);
    final decoded = rawNotes == null
        ? const <String, dynamic>{}
        : jsonDecode(rawNotes) as Map<String, dynamic>;
    if (!mounted) return;
    debugPrint('FIX_REVIEW: preferences loaded');
    setState(() {
      _notes = decoded.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      _completed = preferences.getBool(_completedPreference) ?? false;
      _loading = false;
    });
  }

  List<DragonLineage> get _visibleLineages {
    final query = _query.trim().toLowerCase();
    final fixedLineages = dragonLineages
        .where((lineage) => _fixedReviewForms.containsKey(lineage.id));
    if (query.isEmpty) return fixedLineages.toList(growable: false);
    return fixedLineages.where((lineage) {
      if (lineage.id.toLowerCase().contains(query) ||
          lineage.nameEn.toLowerCase().contains(query) ||
          lineage.nameNl.toLowerCase().contains(query)) {
        return true;
      }
      return _formsFor(lineage).any(
        (form) =>
            form.stageLabel.toLowerCase().contains(query) ||
            form.nameFor(lineage).toLowerCase().contains(query),
      );
    }).toList(growable: false);
  }

  Future<void> _saveNote(String key, String note) async {
    final updated = Map<String, String>.from(_notes);
    final clean = note.trim();
    if (clean.isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = clean;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_notesPreference, jsonEncode(updated));
    await preferences.setBool(_completedPreference, false);
    await preferences.remove(_completedAtPreference);
    if (!mounted) return;
    setState(() {
      _notes = updated;
      _completed = false;
    });
  }

  Future<void> _openEditor(
    DragonLineage lineage,
    _ReviewForm form,
  ) async {
    final key = '${lineage.id}:${form.id}';
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SpriteNoteEditor(
        lineage: lineage,
        form: form,
        initialNote: _notes[key] ?? '',
      ),
    );
    if (note != null) await _saveNote(key, note);
  }

  Future<void> _finishReview() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Beoordeling afronden?'),
            content: Text(
              'Je hebt $_noteCount afbeeldingen met een opmerking. '
              'Je kunt de beoordeling later altijd opnieuw openen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nog niet'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ja, ik ben klaar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedPreference, true);
    await preferences.setString(
      _completedAtPreference,
      DateTime.now().toUtc().toIso8601String(),
    );
    if (!mounted) return;
    setState(() => _completed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opgeslagen. Zeg nu in Codex dat je klaar bent met beoordelen.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lineages = _visibleLineages;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zesde correctieronde',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$_noteCount opmerkingen',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fixedReviewForms.length} familie · $_totalForms aangepaste vorm',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF34245F),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hier staan alleen de sprites die naar aanleiding van je '
                  'vijfde review zijn aangepast. Tik om een nieuwe opmerking '
                  'op te slaan.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Zoek familie, vorm of naam',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_completed) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Beoordeling is gemarkeerd als klaar.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: lineages.isEmpty
                ? const Center(child: Text('Geen draken gevonden.'))
                : ListView.builder(
                    key: const PageStorageKey('dragon-sprite-review-list'),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
                    itemCount: lineages.length,
                    itemBuilder: (context, index) => _FamilyReviewCard(
                      lineage: lineages[index],
                      forms: _formsFor(lineages[index]),
                      notes: _notes,
                      onOpen: _openEditor,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          key: const Key('finish-sprite-review'),
          onPressed: _finishReview,
          icon: Icon(
            _completed ? Icons.check_circle_rounded : Icons.flag_rounded,
          ),
          label: Text(
            _completed
                ? 'Beoordeling opnieuw afronden'
                : 'Klaar met beoordelen',
          ),
        ),
      ),
    );
  }
}

class _SpriteNoteEditor extends StatefulWidget {
  const _SpriteNoteEditor({
    required this.lineage,
    required this.form,
    required this.initialNote,
  });

  final DragonLineage lineage;
  final _ReviewForm form;
  final String initialNote;

  @override
  State<_SpriteNoteEditor> createState() => _SpriteNoteEditorState();
}

class _SpriteNoteEditorState extends State<_SpriteNoteEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.form.nameFor(widget.lineage),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              '${widget.lineage.nameEn} · ${widget.form.stageLabel} · '
              '${widget.lineage.id}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  color: _reviewBlue,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: DragonArt(
                  height: 324,
                  animate: false,
                  stageKey: widget.form.stageKey,
                  lineageId: widget.lineage.id,
                  evolutionPath: widget.form.evolutionPath,
                  prismatic: false,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('sprite-review-note-field'),
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Wat is er niet goed?',
                hintText:
                    'Bijvoorbeeld: wit stukje tussen staart en been, of kijkt de verkeerde kant op.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuleren'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Opmerking opslaan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyReviewCard extends StatelessWidget {
  const _FamilyReviewCard({
    required this.lineage,
    required this.forms,
    required this.notes,
    required this.onOpen,
  });

  final DragonLineage lineage;
  final List<_ReviewForm> forms;
  final Map<String, String> notes;
  final Future<void> Function(DragonLineage, _ReviewForm) onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lineage.nameEn,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (lineage.secret)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Secret'),
                  ),
                const SizedBox(width: 6),
                Text(
                  lineage.rarityName(false),
                  style: const TextStyle(
                    color: Color(0xFF6B519C),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              lineage.id,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .78,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final form = forms[index];
                final note = notes['${lineage.id}:${form.id}'];
                return _FormReviewTile(
                  lineage: lineage,
                  form: form,
                  hasNote: note != null && note.trim().isNotEmpty,
                  onTap: () => onOpen(lineage, form),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FormReviewTile extends StatelessWidget {
  const _FormReviewTile({
    required this.lineage,
    required this.form,
    required this.hasNote,
    required this.onTap,
  });

  final DragonLineage lineage;
  final _ReviewForm form;
  final bool hasNote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _reviewBlue,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('review-${lineage.id}-${form.id}'),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 50,
              child: LayoutBuilder(
                builder: (context, constraints) => DragonArt(
                  height: constraints.biggest.shortestSide,
                  animate: false,
                  stageKey: form.stageKey,
                  lineageId: lineage.id,
                  evolutionPath: form.evolutionPath,
                  prismatic: false,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 50,
              child: ColoredBox(
                color: const Color(0xEFFFFFFF),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        form.stageLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        form.nameFor(lineage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: hasNote ? const Color(0xFFFFD54F) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 5),
                  ],
                ),
                child: Icon(
                  hasNote ? Icons.edit_note_rounded : Icons.edit_rounded,
                  size: 18,
                  color: const Color(0xFF3E2A6F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
