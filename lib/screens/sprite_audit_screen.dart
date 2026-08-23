import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';

const _auditForms = <_AuditForm>[
  _AuditForm(
    id: 'hatchling',
    label: 'Hatchling',
    stageKey: 'spark',
    path: 'might',
  ),
  _AuditForm(
    id: 'wyrmling',
    label: 'Wyrmling',
    stageKey: 'nestDragon',
    path: 'might',
  ),
  _AuditForm(
    id: 'ascended-might',
    label: 'Ascended · Might',
    stageKey: 'homeGuardian',
    path: 'might',
  ),
  _AuditForm(
    id: 'ascended-arcana',
    label: 'Ascended · Arcana',
    stageKey: 'homeGuardian',
    path: 'arcana',
  ),
  _AuditForm(
    id: 'ascended-spirit',
    label: 'Ascended · Spirit',
    stageKey: 'homeGuardian',
    path: 'spirit',
  ),
];

const _marksKey = 'dragonhaven_sprite_audit_marks';
const _pageKey = 'dragonhaven_sprite_audit_page';
const _startWithMarkedOnly = bool.fromEnvironment(
  'DRAGONHAVEN_SPRITE_AUDIT_MARKED_ONLY',
);
const _startFamily = String.fromEnvironment(
  'DRAGONHAVEN_SPRITE_AUDIT_START_FAMILY',
);

/// Every runtime rendering of the 77 source forms repaired for this release.
/// Four variants are included per form: normal/spectral, each in color/black.
Set<String> releaseRepairAuditEntryIds() {
  final entries = <String>{};
  for (final family in DragonArtwork.safeStandaloneForms.entries) {
    for (final sourceForm in family.value) {
      final auditForm = switch (sourceForm) {
        'wyrmling' => 'wyrmling',
        'might' => 'ascended-might',
        'arcana' => 'ascended-arcana',
        'spirit' => 'ascended-spirit',
        _ => throw StateError('Unknown repaired form: $sourceForm'),
      };
      for (final spectral in [false, true]) {
        for (final silhouette in [false, true]) {
          entries.add(
            '${family.key}-${spectral ? 'spectral' : 'normal'}-'
            '${silhouette ? 'black' : 'color'}-$auditForm',
          );
        }
      }
    }
  }
  return entries;
}

class SpriteAuditApp extends StatelessWidget {
  const SpriteAuditApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DragonHaven Sprite Audit',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SpriteAuditScreen(),
      );
}

class SpriteAuditScreen extends StatefulWidget {
  const SpriteAuditScreen({super.key});

  @override
  State<SpriteAuditScreen> createState() => _SpriteAuditScreenState();
}

class _SpriteAuditScreenState extends State<SpriteAuditScreen> {
  final Set<String> _marked = {};
  SharedPreferences? _preferences;
  bool _ready = false;
  bool _markedOnly = false;
  bool _finished = false;
  int _pageIndex = 0;

  static final List<_AuditPage> _allPages = [
    for (final lineage in dragonLineages) ...[
      _AuditPage(lineage: lineage, spectral: false, silhouette: true),
      _AuditPage(lineage: lineage, spectral: false, silhouette: false),
      _AuditPage(lineage: lineage, spectral: true, silhouette: true),
      _AuditPage(lineage: lineage, spectral: true, silhouette: false),
    ],
  ];

  List<_AuditPage> get _visiblePages => !_markedOnly
      ? _allPages
      : _allPages
          .where((page) => _auditForms.any(
                (form) => _marked.contains(page.entryId(form)),
              ))
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final page = preferences.getInt(_pageKey) ?? 0;
    setState(() {
      _preferences = preferences;
      _marked.addAll(preferences.getStringList(_marksKey) ?? const []);
      if (_startWithMarkedOnly && _marked.isEmpty) {
        _marked.addAll(releaseRepairAuditEntryIds());
      }
      _markedOnly = _startWithMarkedOnly && _marked.isNotEmpty;
      if (_markedOnly) {
        final requestedPage = _startFamily.isEmpty
            ? -1
            : _visiblePages.indexWhere(
                (auditPage) => auditPage.lineage.id == _startFamily,
              );
        _pageIndex = math.max(0, requestedPage);
      } else {
        _pageIndex = page.clamp(0, _allPages.length - 1);
      }
      _ready = true;
    });
  }

  Future<void> _saveMarks() async {
    final values = _marked.toList()..sort();
    await _preferences?.setStringList(_marksKey, values);
  }

  Future<void> _setMarked(
    _AuditPage page,
    _AuditForm form,
    bool marked,
  ) async {
    final entryId = page.entryId(form);
    setState(() {
      marked ? _marked.add(entryId) : _marked.remove(entryId);
      if (_markedOnly) {
        final pages = _visiblePages;
        if (pages.isEmpty) {
          _finished = true;
          _markedOnly = false;
          _pageIndex = 0;
        } else {
          _pageIndex = math.min(_pageIndex, pages.length - 1);
        }
      }
    });
    await _saveMarks();
  }

  Future<void> _inspect(_AuditPage page, _AuditForm form) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _SpriteInspectionDialog(
        page: page,
        form: form,
        marked: _marked.contains(page.entryId(form)),
      ),
    );
    if (result != null && mounted) await _setMarked(page, form, result);
  }

  Future<void> _move(int direction) async {
    final pages = _visiblePages;
    if (pages.isEmpty) return;
    final next = _pageIndex + direction;
    if (next < 0) return;
    if (next >= pages.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() => _pageIndex = next);
    if (!_markedOnly) await _preferences?.setInt(_pageKey, next);
  }

  void _startMarkedReview() {
    if (_marked.isEmpty) return;
    setState(() {
      _markedOnly = true;
      _finished = false;
      _pageIndex = 0;
    });
  }

  void _startAll({bool fromBeginning = false}) {
    setState(() {
      _markedOnly = false;
      _finished = false;
      if (fromBeginning) _pageIndex = 0;
    });
    if (fromBeginning) _preferences?.setInt(_pageKey, 0);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset the sprite audit?'),
            content: const Text(
              'This clears every selected problem sprite and returns to the first family.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() {
      _marked.clear();
      _markedOnly = false;
      _finished = false;
      _pageIndex = 0;
    });
    await _preferences?.remove(_marksKey);
    await _preferences?.setInt(_pageKey, 0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages;
    final safeIndex =
        pages.isEmpty ? 0 : math.min(_pageIndex, pages.length - 1);
    final page = pages.isEmpty ? null : pages[safeIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sprite audit'),
            Text(
              'Tap a form to inspect or flag it',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('audit-marked-only'),
            tooltip: 'Review selected only',
            onPressed: _marked.isEmpty ? null : _startMarkedReview,
            icon: Badge(
              isLabelVisible: _marked.isNotEmpty,
              label: Text('${_marked.length}'),
              child: const Icon(Icons.flag_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Reset audit',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _finished || page == null
              ? _AuditSummary(
                  markedCount: _marked.length,
                  onReviewMarked: _startMarkedReview,
                  onReviewAll: () => _startAll(fromBeginning: true),
                )
              : _AuditPageView(
                  key: ValueKey(page.id),
                  page: page,
                  marked: _marked,
                  pageNumber: safeIndex + 1,
                  pageCount: pages.length,
                  markedOnly: _markedOnly,
                  onInspect: (form) => _inspect(page, form),
                ),
      bottomNavigationBar: !_ready || _finished || page == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.mist)),
                ),
                child: Row(
                  children: [
                    IconButton.outlined(
                      key: const Key('audit-previous'),
                      onPressed: safeIndex == 0 ? null : () => _move(-1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('audit-next'),
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(safeIndex == pages.length - 1
                            ? 'Finish this review'
                            : 'Inspected · next'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AuditPageView extends StatelessWidget {
  const _AuditPageView({
    super.key,
    required this.page,
    required this.marked,
    required this.pageNumber,
    required this.pageCount,
    required this.markedOnly,
    required this.onInspect,
  });

  final _AuditPage page;
  final Set<String> marked;
  final int pageNumber;
  final int pageCount;
  final bool markedOnly;
  final ValueChanged<_AuditForm> onInspect;

  @override
  Widget build(BuildContext context) {
    final familyIndex = dragonLineages.indexOf(page.lineage) + 1;
    final forms = markedOnly
        ? _auditForms
            .where((form) => marked.contains(page.entryId(form)))
            .toList(growable: false)
        : _auditForms;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25164D), Color(0xFF67449A)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      page.lineage.nameEn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '$familyIndex/${dragonLineages.length}',
                    style: const TextStyle(
                      color: Color(0xFFFFD86E),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                page.variantLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              LinearProgressIndicator(
                value: pageNumber / pageCount,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white24,
                color: const Color(0xFFFFD86E),
              ),
              const SizedBox(height: 7),
              Text(
                'Review page $pageNumber of $pageCount · ${marked.length} selected',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: Key('audit-grid-${page.id}'),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              childAspectRatio: .82,
            ),
            itemCount: forms.length,
            itemBuilder: (_, index) {
              final form = forms[index];
              final isMarked = marked.contains(page.entryId(form));
              return _AuditFormCard(
                page: page,
                form: form,
                marked: isMarked,
                onTap: () => onInspect(form),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditFormCard extends StatelessWidget {
  const _AuditFormCard({
    required this.page,
    required this.form,
    required this.marked,
    required this.onTap,
  });

  final _AuditPage page;
  final _AuditForm form;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: marked ? const Color(0xFFFFE1DF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: marked ? AppColors.coral : AppColors.mist,
            width: marked ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('audit-form-${page.entryId(form)}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final size = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F0FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD4C8EA)),
                          ),
                          child: DragonArt(
                            height: size,
                            animate: false,
                            stageKey: form.stageKey,
                            lineageId: page.lineage.id,
                            evolutionPath: form.path,
                            fit: BoxFit.contain,
                            prismatic: page.spectral,
                            silhouette: page.silhouette,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  form.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
                Text(
                  marked ? 'SELECTED FOR FIX' : 'Tap to inspect',
                  style: TextStyle(
                    color: marked ? const Color(0xFFB63F3A) : AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SpriteInspectionDialog extends StatelessWidget {
  const _SpriteInspectionDialog({
    required this.page,
    required this.form,
    required this.marked,
  });

  final _AuditPage page;
  final _AuditForm form;
  final bool marked;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF17112F),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.lineage.nameEn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${form.label} · ${page.variantLabel}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final size = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F0FA),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFFFD86E),
                              width: 3,
                            ),
                          ),
                          child: DragonArt(
                            key: const Key('audit-inspection-art'),
                            height: size,
                            animate: false,
                            stageKey: form.stageKey,
                            lineageId: page.lineage.id,
                            evolutionPath: form.path,
                            fit: BoxFit.contain,
                            prismatic: page.spectral,
                            silhouette: page.silhouette,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Check every edge of the square. Is the complete dragon visible with the correct aspect ratio?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('audit-looks-good'),
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Looks good'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('audit-needs-fix'),
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: marked
                              ? const Color(0xFFB63F3A)
                              : AppColors.coral,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.flag_rounded),
                        label: Text(marked ? 'Keep selected' : 'Needs fix'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({
    required this.markedCount,
    required this.onReviewMarked,
    required this.onReviewAll,
  });

  final int markedCount;
  final VoidCallback onReviewMarked;
  final VoidCallback onReviewAll;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                markedCount == 0
                    ? Icons.verified_rounded
                    : Icons.fact_check_rounded,
                size: 104,
                color: markedCount == 0 ? AppColors.mint : AppColors.coral,
              ),
              const SizedBox(height: 20),
              Text(
                markedCount == 0 ? 'Everything looks good' : 'Audit complete',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                markedCount == 0
                    ? 'No dragon forms are currently selected for adjustment.'
                    : '$markedCount dragon form${markedCount == 1 ? '' : 's'} selected. The next review can show only these forms.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (markedCount > 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReviewMarked,
                    icon: const Icon(Icons.flag_rounded),
                    label: Text('Review selected only ($markedCount)'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReviewAll,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Review every family again'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _AuditForm {
  const _AuditForm({
    required this.id,
    required this.label,
    required this.stageKey,
    required this.path,
  });

  final String id;
  final String label;
  final String stageKey;
  final String path;
}

class _AuditPage {
  const _AuditPage({
    required this.lineage,
    required this.spectral,
    required this.silhouette,
  });

  final DragonLineage lineage;
  final bool spectral;
  final bool silhouette;

  String get id =>
      '${lineage.id}-${spectral ? 'spectral' : 'normal'}-${silhouette ? 'black' : 'color'}';

  String get variantLabel => switch ((spectral, silhouette)) {
        (false, true) => '1/4 · Normal silhouettes',
        (false, false) => '2/4 · Normal colors',
        (true, true) => '3/4 · Spectral silhouettes',
        (true, false) => '4/4 · Spectral colors',
      };

  String entryId(_AuditForm form) => '$id-${form.id}';
}
