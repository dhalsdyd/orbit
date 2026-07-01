import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/orbit_contact_repository.dart';
import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_memory.dart';
import 'orbit_painter.dart';
import 'orbit_scene_layout.dart';

class OrbitCanvasScreen extends StatefulWidget {
  const OrbitCanvasScreen({super.key});

  @override
  State<OrbitCanvasScreen> createState() => _OrbitCanvasScreenState();
}

class _OrbitCanvasScreenState extends State<OrbitCanvasScreen>
    with SingleTickerProviderStateMixin {
  final OrbitContactRepository _repository =
      const SeedOrbitContactRepository();

  late final Ticker _ticker;
  late final List<OrbitContact> _contacts;
  late final List<OrbitMemory> _memories;
  Duration _elapsed = Duration.zero;
  String? _selectedContactId;
  String? _selectedMemoryId;

  OrbitContact? get _selectedContact {
    final id = _selectedContactId;
    if (id == null) {
      return null;
    }

    for (final contact in _contacts) {
      if (contact.id == id) {
        return contact;
      }
    }

    return null;
  }

  List<OrbitMemory> get _selectedContactMemories {
    final id = _selectedContactId;
    if (id == null) {
      return const [];
    }

    return _memories
        .where((memory) => memory.contactId == id)
        .toList()
      ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
  }

  @override
  void initState() {
    super.initState();
    _contacts = _repository.getContacts();
    _memories = _repository.getMemories();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedContact = _selectedContact;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: Semantics(
                    label: selectedContact == null
                        ? 'Orbit canvas with the sun and relationship planets'
                        : 'Personal memory universe for ${selectedContact.name}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _handleTap(details, size),
                      child: CustomPaint(
                        painter: OrbitPainter(
                          contacts: _contacts,
                          memories: _memories,
                          elapsed: _elapsed,
                          selectedContactId: _selectedContactId,
                          selectedMemoryId: _selectedMemoryId,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              _OrbitHeader(
                selectedContact: selectedContact,
                memoryCount: _selectedContactMemories.length,
                onBack: selectedContact == null ? null : _closeArchive,
              ),
              if (selectedContact == null)
                const _HomeHint()
              else
                _ArchiveControls(
                  memories: _selectedContactMemories,
                  onShowTimeline: _showTimeline,
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleTap(TapDownDetails details, Size size) {
    final tap = details.localPosition;
    final selectedContact = _selectedContact;

    if (selectedContact == null) {
      final planet = _hitPlanet(tap, size);
      if (planet == null) {
        return;
      }

      HapticFeedback.selectionClick();
      setState(() {
        _selectedContactId = planet.contact.id;
        _selectedMemoryId = null;
      });
      return;
    }

    final memory = _hitMemory(tap, size);
    if (memory == null) {
      setState(() {
        _selectedMemoryId = null;
      });
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _selectedMemoryId = memory.id;
    });
    _showMemoryCard(memory);
  }

  OrbitPlanetLayout? _hitPlanet(Offset tap, Size size) {
    final planets = OrbitSceneLayout.homePlanets(
      contacts: _contacts,
      size: size,
      elapsed: _elapsed,
    );

    OrbitPlanetLayout? closest;
    var closestDistance = double.infinity;

    for (final planet in planets) {
      final distance = (tap - planet.position).distance;
      if (distance < closestDistance) {
        closest = planet;
        closestDistance = distance;
      }
    }

    if (closest == null || closestDistance > closest.planetRadius + 28) {
      return null;
    }

    return closest;
  }

  OrbitMemory? _hitMemory(Offset tap, Size size) {
    final layouts = OrbitSceneLayout.memoryObjects(
      memories: _selectedContactMemories,
      size: size,
      elapsed: _elapsed,
    );

    OrbitMemoryLayout? closest;
    var closestDistance = double.infinity;

    for (final layout in layouts) {
      final distance = (tap - layout.position).distance;
      if (distance < closestDistance) {
        closest = layout;
        closestDistance = distance;
      }
    }

    if (closest == null ||
        closestDistance > math.max(28, closest.visualRadius + 14)) {
      return null;
    }

    return closest.memory;
  }

  void _closeArchive() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedContactId = null;
      _selectedMemoryId = null;
    });
  }

  Future<void> _showMemoryCard(OrbitMemory memory) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        return _MemorySheet(memory: memory);
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMemoryId = null;
    });
  }

  Future<void> _showTimeline() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      isScrollControlled: true,
      builder: (context) {
        return _TimelineSheet(memories: _selectedContactMemories);
      },
    );
  }
}

class _OrbitHeader extends StatelessWidget {
  const _OrbitHeader({
    required this.selectedContact,
    required this.memoryCount,
    required this.onBack,
  });

  final OrbitContact? selectedContact;
  final int memoryCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final contact = selectedContact;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Row(
          children: [
            if (onBack != null)
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            if (onBack != null) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact == null ? 'Orbit' : '${contact.name} Universe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact == null
                        ? 'Tap a planet to drift into its memory archive.'
                        : '$memoryCount memories orbiting as satellites and stars.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHint extends StatelessWidget {
  const _HomeHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1024).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            'Close planets stay bright for memories. Outer planets still nudge gently.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveControls extends StatelessWidget {
  const _ArchiveControls({
    required this.memories,
    required this.onShowTimeline,
  });

  final List<OrbitMemory> memories;
  final VoidCallback onShowTimeline;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 22,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _MemoryChip(label: 'Gift given'),
                _MemoryChip(label: 'Gift received'),
                _MemoryChip(label: 'Meal & drinks'),
                _MemoryChip(label: 'Cafe'),
                _MemoryChip(label: 'Trip'),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: memories.isEmpty ? null : onShowTimeline,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Past orbit trail'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryChip extends StatelessWidget {
  const _MemoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      backgroundColor: const Color(0xFF111A3C).withValues(alpha: 0.70),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
          ),
    );
  }
}

class _MemorySheet extends StatelessWidget {
  const _MemorySheet({required this.memory});

  final OrbitMemory memory;

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MemoryOrb(memory: memory),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${memory.kind.label} · ${_formatDate(memory.occurredOn)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            memory.note,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.42,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (memory.location != null)
                _MetaPill(
                  icon: Icons.place_rounded,
                  label: memory.location!,
                ),
              if (memory.photoCount > 0)
                _MetaPill(
                  icon: Icons.photo_rounded,
                  label: '${memory.photoCount} photos',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineSheet extends StatelessWidget {
  const _TimelineSheet({required this.memories});

  final List<OrbitMemory> memories;

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      maxHeightFactor: 0.74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Past orbit trail',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: memories.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) {
                final memory = memories[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _MemoryOrb(memory: memory),
                  title: Text(memory.title),
                  subtitle: Text(
                    '${memory.kind.label} · ${_formatDate(memory.occurredOn)}',
                  ),
                  trailing: memory.kind.isGift
                      ? const Icon(Icons.circle_rounded, size: 12)
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({
    required this.child,
    this.maxHeightFactor = 0.56,
  });

  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF090D1C).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7CFA).withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryOrb extends StatelessWidget {
  const _MemoryOrb({required this.memory});

  final OrbitMemory memory;

  @override
  Widget build(BuildContext context) {
    final color = Color(memory.colorSeed);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            color.withValues(alpha: 0.86),
            color.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.40),
            blurRadius: 22,
          ),
        ],
      ),
      child: Icon(
        memory.kind.isGift
            ? Icons.circle_rounded
            : Icons.auto_awesome_rounded,
        color: Colors.white.withValues(alpha: 0.86),
        size: memory.kind.isGift ? 12 : 20,
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.68)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
