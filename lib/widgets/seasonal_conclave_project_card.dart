import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/seasonal_conclave_project.dart';

class SeasonalConclaveProjectCard extends StatelessWidget {
  const SeasonalConclaveProjectCard({super.key, required this.project});
  final SeasonalConclaveProject project;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final title = project.sunwake
        ? s.pick('Our Sunwake Reef', 'Ons Sunwake-rif')
        : s.pick('Our Harvest Feast', 'Ons Oogstfeest');
    return Card(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
            key: PageStorageKey('seasonal-conclave-${project.eventId}'),
            leading: Image.asset(project.asset,
                width: 54, height: 54, fit: BoxFit.contain, cacheWidth: 144),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
                '${project.preview ? '${s.pick('Test event', 'Testevent')} · ' : ''}'
                '${s.pick('Stage', 'Fase')} ${project.stage}/5 · ${project.completedTrials}'
                '${project.nextMilestone == null ? '' : '/${project.nextMilestone}'}'),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            children: [
              Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                          colors: project.sunwake
                              ? [
                                  const Color(0xFFB1EAD9),
                                  const Color(0xFF163F4A)
                                ]
                              : [
                                  const Color(0xFFF3D5A1),
                                  const Color(0xFF48351F)
                                ])),
                  child: Stack(alignment: Alignment.center, children: [
                    Opacity(
                        opacity: .22,
                        child: Image.asset(project.asset,
                            height: 174, fit: BoxFit.contain)),
                    if (project.stage > 0)
                      ClipRect(
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: .35 + project.stage * .13,
                              child: Image.asset(project.asset,
                                  height: 174, fit: BoxFit.contain))),
                    if (project.stage == 5)
                      const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFFFFE08D))),
                  ])),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                  value: project.fraction,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 10),
              Text(
                  project.preview
                      ? s.pick(
                          'Try the shared decoration together. Test progress is separate and does not unlock the permanent project.',
                          'Probeer de gezamenlijke decoratie samen. Testvoortgang staat apart en ontgrendelt het blijvende project niet.')
                      : s.pick(
                          'Complete this event’s Trials with your Conclave to grow the decoration. Every completed run with a successful action counts once. Your decoration stays after the festival.',
                          'Voltooi de trials van dit event met je Conclave om de decoratie te laten groeien. Elke voltooide poging met een geslaagde actie telt eenmaal. De decoratie blijft na het festival.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ]));
  }
}
