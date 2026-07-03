import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/orbit_contact_repository.dart';
import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_decoration.dart';
import '../../domain/entities/orbit_memory.dart';
import '../../domain/entities/relationship_mode.dart';
import 'orbit_painter.dart';
import 'orbit_scene_layout.dart';

class OrbitCanvasScreen extends StatefulWidget {
  const OrbitCanvasScreen({
    required this.repository,
    super.key,
  });

  final OrbitContactRepository repository;

  @override
  State<OrbitCanvasScreen> createState() => _OrbitCanvasScreenState();
}

class _OrbitCanvasScreenState extends State<OrbitCanvasScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _archiveTransition;
  late final List<OrbitContact> _contacts;
  late final List<OrbitDecoration> _decorations;
  late final List<OrbitMemory> _memories;
  Duration _elapsed = Duration.zero;
  String? _selectedContactId;
  String? _selectedMemoryId;
  int _quickMemorySerial = 0;

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

  OrbitDecoration get _selectedDecoration {
    final contactId = _selectedContactId ?? _contacts.first.id;

    return _decorationFor(contactId);
  }

  @override
  void initState() {
    super.initState();
    _contacts = widget.repository.getContacts();
    _decorations = widget.repository.getDecorations();
    _memories = widget.repository.getMemories();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed;
      });
    })..start();
    _archiveTransition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      reverseDuration: const Duration(milliseconds: 420),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _archiveTransition.dispose();
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
                          decorations: _decorations,
                          memories: _memories,
                          elapsed: _elapsed,
                          selectedContactId: _selectedContactId,
                          selectedMemoryId: _selectedMemoryId,
                          archiveReveal: Curves.easeOutCubic.transform(
                            _archiveTransition.value,
                          ),
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
                onBack: selectedContact == null
                    ? null
                    : () {
                        unawaited(_closeArchive());
                      },
              ),
              if (selectedContact == null)
                const _HomeHint()
              else
                _ArchiveControls(
                  contact: selectedContact,
                  decoration: _selectedDecoration,
                  memories: _selectedContactMemories,
                  onQuickAdd: _addQuickMemory,
                  onDecorate: _showDecorateSheet,
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
      _archiveTransition.forward(from: 0);
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

  Future<void> _closeArchive() async {
    HapticFeedback.selectionClick();
    await _archiveTransition.reverse();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedContactId = null;
      _selectedMemoryId = null;
    });
  }

  void _addQuickMemory(MemoryKind kind) {
    final contact = _selectedContact;
    if (contact == null) {
      return;
    }

    final now = DateTime.now();
    final serial = _quickMemorySerial++;
    final memory = OrbitMemory(
      id: 'quick-${contact.id}-${now.microsecondsSinceEpoch}-$serial',
      contactId: contact.id,
      kind: kind,
      title: _quickTitleFor(kind),
      note: _quickNoteFor(kind, contact.name),
      occurredOn: now,
      colorSeed: _quickColorSeedFor(kind),
      sticker: _quickStickerFor(kind),
      stamp: _quickStampFor(kind),
    );

    setState(() {
      _memories.add(memory);
      _selectedMemoryId = memory.id;
    });
    unawaited(_persistMemory(memory));

    if (kind.isGift) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111A3C),
          content: Text('${kind.label} captured in ${contact.name} Universe.'),
          duration: const Duration(milliseconds: 1500),
        ),
      );

    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted || _selectedMemoryId != memory.id) {
        return;
      }

      setState(() {
        _selectedMemoryId = null;
      });
    });
  }

  Future<void> _showMemoryCard(OrbitMemory memory) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      isScrollControlled: true,
      builder: (context) {
        return _MemorySheet(
          memory: memory,
          onSave: _updateMemory,
          onDelete: _deleteMemory,
          onAddPhoto: _addPhotoToMemory,
        );
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

  OrbitDecoration _decorationFor(String contactId) {
    for (final decoration in _decorations) {
      if (decoration.contactId == contactId) {
        return decoration;
      }
    }

    return OrbitDecoration(
      contactId: contactId,
      planetSkin: PlanetSkin.solarGold,
      nebulaTheme: NebulaTheme.dawn,
    );
  }

  Future<void> _showDecorateSheet() async {
    final contact = _selectedContact;
    if (contact == null) {
      return;
    }

    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      isScrollControlled: true,
      builder: (context) {
        return _DecorateSheet(
          contact: contact,
          decoration: _decorationFor(contact.id),
          onSave: _updateDecoration,
        );
      },
    );
  }

  Future<void> _persistMemory(OrbitMemory memory) async {
    try {
      await widget.repository.addMemory(memory);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF2B1020),
            content: Text('Memory was added here, but local save failed.'),
          ),
        );
    }
  }

  Future<void> _updateDecoration(OrbitDecoration updatedDecoration) async {
    final index = _decorations.indexWhere(
      (decoration) => decoration.contactId == updatedDecoration.contactId,
    );

    setState(() {
      if (index == -1) {
        _decorations.add(updatedDecoration);
      } else {
        _decorations[index] = updatedDecoration;
      }
    });

    try {
      await widget.repository.updateDecoration(updatedDecoration);
      _showOrbitSnackBar('Universe decoration saved.');
    } catch (_) {
      _showOrbitSnackBar('Decoration changed here, but local save failed.');
    }
  }

  Future<void> _updateMemory(OrbitMemory updatedMemory) async {
    final index = _memories.indexWhere(
      (memory) => memory.id == updatedMemory.id,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      _memories[index] = updatedMemory;
      _selectedMemoryId = updatedMemory.id;
    });

    try {
      await widget.repository.updateMemory(updatedMemory);
      _showOrbitSnackBar('Memory updated.');
    } catch (_) {
      _showOrbitSnackBar('Memory changed here, but local save failed.');
    }
  }

  Future<void> _deleteMemory(OrbitMemory memory) async {
    for (final photoPath in memory.photoPaths) {
      unawaited(_deletePhotoFile(photoPath));
    }

    setState(() {
      _memories.removeWhere((candidate) => candidate.id == memory.id);
      _selectedMemoryId = null;
    });

    try {
      await widget.repository.deleteMemory(memory.id);
      _showOrbitSnackBar('Memory deleted.');
    } catch (_) {
      _showOrbitSnackBar('Memory removed here, but local delete failed.');
    }
  }

  Future<OrbitMemory?> _addPhotoToMemory(OrbitMemory memory) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) {
        return null;
      }

      final storedPath = await _copyPickedPhoto(memory, image);
      final updatedMemory = memory.copyWith(
        photoPaths: [
          ...memory.photoPaths,
          storedPath,
        ],
      );
      await _updateMemory(updatedMemory);
      HapticFeedback.selectionClick();

      return updatedMemory;
    } catch (_) {
      _showOrbitSnackBar('Photo could not be attached.');
      return null;
    }
  }

  Future<String> _copyPickedPhoto(OrbitMemory memory, XFile image) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final photoDirectory = Directory('${supportDirectory.path}/orbit_photos');
    await photoDirectory.create(recursive: true);

    final pathParts = image.path.split('.');
    final extension = pathParts.length > 1 ? pathParts.last : 'jpg';
    final fileName = '${memory.id}_${DateTime.now().microsecondsSinceEpoch}'
        '.$extension';
    final targetPath = '${photoDirectory.path}/$fileName';
    await File(image.path).copy(targetPath);

    return targetPath;
  }

  Future<void> _deletePhotoFile(String photoPath) async {
    try {
      await File(photoPath).delete();
    } catch (_) {
      // The memory should still be removed even if its cached photo is gone.
    }
  }

  void _showOrbitSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111A3C),
          content: Text(message),
          duration: const Duration(milliseconds: 1400),
        ),
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
                        : '${contact.relationshipMode.label} · $memoryCount memories',
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
    required this.contact,
    required this.decoration,
    required this.memories,
    required this.onQuickAdd,
    required this.onDecorate,
    required this.onShowTimeline,
  });

  final OrbitContact contact;
  final OrbitDecoration decoration;
  final List<OrbitMemory> memories;
  final ValueChanged<MemoryKind> onQuickAdd;
  final VoidCallback onDecorate;
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
            Text(
              contact.relationshipMode.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in const [
                  MemoryKind.giftGiven,
                  MemoryKind.giftReceived,
                  MemoryKind.meal,
                  MemoryKind.cafe,
                  MemoryKind.trip,
                  MemoryKind.hobby,
                ])
                  _MemoryChip(
                    kind: kind,
                    onPressed: () => onQuickAdd(kind),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onDecorate,
                  icon: const Icon(Icons.brush_rounded),
                  label: Text(decoration.planetSkin.label),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: memories.isEmpty ? null : onShowTimeline,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Past orbit trail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryChip extends StatelessWidget {
  const _MemoryChip({
    required this.kind,
    required this.onPressed,
  });

  final MemoryKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        kind.isGift ? Icons.circle_rounded : Icons.auto_awesome_rounded,
        size: kind.isGift ? 10 : 16,
        color: Colors.white.withValues(alpha: 0.70),
      ),
      label: Text(kind.label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      backgroundColor: const Color(0xFF111A3C).withValues(alpha: 0.70),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
          ),
    );
  }
}

class _DecorateSheet extends StatefulWidget {
  const _DecorateSheet({
    required this.contact,
    required this.decoration,
    required this.onSave,
  });

  final OrbitContact contact;
  final OrbitDecoration decoration;
  final Future<void> Function(OrbitDecoration decoration) onSave;

  @override
  State<_DecorateSheet> createState() => _DecorateSheetState();
}

class _DecorateSheetState extends State<_DecorateSheet> {
  late PlanetSkin _planetSkin;
  late NebulaTheme _nebulaTheme;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _planetSkin = widget.decoration.planetSkin;
    _nebulaTheme = widget.decoration.nebulaTheme;
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      maxHeightFactor: 0.72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Decorate ${widget.contact.name} Universe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tune the planet skin and background nebula for this relationship.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.58),
                ),
          ),
          const SizedBox(height: 20),
          _ChoiceSection(
            title: 'Planet skin',
            children: [
              for (final skin in PlanetSkin.values)
                _ChoiceChipButton(
                  label: skin.label,
                  selected: skin == _planetSkin,
                  onPressed: () {
                    setState(() {
                      _planetSkin = skin;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          _ChoiceSection(
            title: 'Nebula theme',
            children: [
              for (final theme in NebulaTheme.values)
                _ChoiceChipButton(
                  label: theme.label,
                  selected: theme == _nebulaTheme,
                  onPressed: () {
                    setState(() {
                      _nebulaTheme = theme;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save decoration'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });
    await widget.onSave(
      widget.decoration.copyWith(
        planetSkin: _planetSkin,
        nebulaTheme: _nebulaTheme,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onPressed(),
      label: Text(label),
      side: BorderSide(
        color: selected
            ? const Color(0xFFFFD27A).withValues(alpha: 0.64)
            : Colors.white.withValues(alpha: 0.12),
      ),
      selectedColor: const Color(0xFFFFD27A).withValues(alpha: 0.20),
      backgroundColor: const Color(0xFF111A3C).withValues(alpha: 0.68),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: selected ? 0.94 : 0.72),
          ),
    );
  }
}

class _MemorySheet extends StatefulWidget {
  const _MemorySheet({
    required this.memory,
    required this.onSave,
    required this.onDelete,
    required this.onAddPhoto,
  });

  final OrbitMemory memory;
  final Future<void> Function(OrbitMemory memory) onSave;
  final Future<void> Function(OrbitMemory memory) onDelete;
  final Future<OrbitMemory?> Function(OrbitMemory memory) onAddPhoto;

  @override
  State<_MemorySheet> createState() => _MemorySheetState();
}

class _MemorySheetState extends State<_MemorySheet> {
  late OrbitMemory _memory;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _locationController;
  var _isEditing = false;
  var _isBusy = false;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    _titleController = TextEditingController(text: _memory.title);
    _noteController = TextEditingController(text: _memory.note);
    _locationController = TextEditingController(text: _memory.location ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      maxHeightFactor: 0.86,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemoryOrb(memory: _memory),
                const SizedBox(width: 14),
                Expanded(
                  child: _isEditing
                      ? _buildTitleEditor()
                      : _buildTitleSummary(context),
                ),
                IconButton(
                  tooltip: _isEditing ? 'Cancel edit' : 'Edit memory',
                  onPressed: _isBusy
                      ? null
                      : () {
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                        },
                  icon: Icon(
                    _isEditing
                        ? Icons.close_rounded
                        : Icons.edit_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isEditing) ...[
              _buildTextField(
                controller: _noteController,
                label: 'Note',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
              ),
              const SizedBox(height: 14),
              _ChoiceSection(
                title: 'Sticker',
                children: [
                  for (final sticker in MemorySticker.values)
                    _ChoiceChipButton(
                      label: sticker.label,
                      selected: sticker == _memory.sticker,
                      onPressed: () {
                        setState(() {
                          _memory = _memory.copyWith(sticker: sticker);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _ChoiceSection(
                title: 'Stamp',
                children: [
                  for (final stamp in MemoryStamp.values)
                    _ChoiceChipButton(
                      label: stamp.label,
                      selected: stamp == _memory.stamp,
                      onPressed: () {
                        setState(() {
                          _memory = _memory.copyWith(stamp: stamp);
                        });
                      },
                    ),
                ],
              ),
            ] else ...[
              Text(
                _memory.note,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.42,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _PhotoStrip(memory: _memory),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_memory.location != null)
                  _MetaPill(
                    icon: Icons.place_rounded,
                    label: _memory.location!,
                  ),
                if (_memory.visiblePhotoCount > 0)
                  _MetaPill(
                    icon: Icons.photo_rounded,
                    label: '${_memory.visiblePhotoCount} photos',
                  ),
                _MetaPill(
                  icon: Icons.local_offer_rounded,
                  label: _memory.sticker.label,
                ),
                _MetaPill(
                  icon: Icons.brightness_5_rounded,
                  label: _memory.stamp.label,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _addPhoto,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Add photo'),
                ),
                const Spacer(),
                if (_isEditing)
                  FilledButton.icon(
                    onPressed: _isBusy ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save'),
                  )
                else
                  TextButton.icon(
                    onPressed: _isBusy ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _memory.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_memory.kind.label} · ${_formatDate(_memory.occurredOn)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
              ),
        ),
      ],
    );
  }

  Widget _buildTitleEditor() {
    return _buildTextField(
      controller: _titleController,
      label: 'Title',
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final locationText = _locationController.text.trim();
    final updatedMemory = _memory.copyWith(
      title: title,
      note: _noteController.text.trim(),
      location: locationText.isEmpty ? null : locationText,
      sticker: _memory.sticker,
      stamp: _memory.stamp,
    );

    setState(() {
      _isBusy = true;
    });
    await widget.onSave(updatedMemory);
    if (!mounted) {
      return;
    }
    setState(() {
      _memory = updatedMemory;
      _isEditing = false;
      _isBusy = false;
    });
  }

  Future<void> _addPhoto() async {
    setState(() {
      _isBusy = true;
    });
    final updatedMemory = await widget.onAddPhoto(_memory);
    if (!mounted) {
      return;
    }
    setState(() {
      if (updatedMemory != null) {
        _memory = updatedMemory;
      }
      _isBusy = false;
    });
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF090D1C),
          title: const Text('Delete this memory?'),
          content: const Text('Its satellite or constellation node will vanish.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    await widget.onDelete(_memory);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
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
        padding: EdgeInsets.fromLTRB(
          14,
          14,
          14,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
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

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.memory});

  final OrbitMemory memory;

  @override
  Widget build(BuildContext context) {
    if (memory.visiblePhotoCount == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: memory.visiblePhotoCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index < memory.photoPaths.length) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(memory.photoPaths[index]),
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const _PhotoPlaceholder();
                },
              ),
            );
          }

          return const _PhotoPlaceholder();
        },
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Icon(
        Icons.photo_rounded,
        color: Colors.white.withValues(alpha: 0.44),
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

String _quickTitleFor(MemoryKind kind) {
  return switch (kind) {
    MemoryKind.giftGiven => 'Gift given',
    MemoryKind.giftReceived => 'Gift received',
    MemoryKind.meal => 'Meal & drinks',
    MemoryKind.cafe => 'Cafe moment',
    MemoryKind.trip => 'Place memory',
    MemoryKind.hobby => 'Shared hobby',
  };
}

String _quickNoteFor(MemoryKind kind, String contactName) {
  return switch (kind) {
    MemoryKind.giftGiven =>
      'Captured with one tap. Add the gift name or photo later.',
    MemoryKind.giftReceived =>
      'A gift from $contactName. Details can be filled in later.',
    MemoryKind.meal =>
      'A shared table became a new star in this relationship.',
    MemoryKind.cafe =>
      'A quiet cafe memory captured without opening the keyboard.',
    MemoryKind.trip =>
      'A place worth saving as a constellation in this universe.',
    MemoryKind.hobby =>
      'Something you did together, saved before the feeling fades.',
  };
}

int _quickColorSeedFor(MemoryKind kind) {
  return switch (kind) {
    MemoryKind.giftGiven => 0xFFFFD27A,
    MemoryKind.giftReceived => 0xFFD9C7FF,
    MemoryKind.meal => 0xFFFF8E3C,
    MemoryKind.cafe => 0xFFA8D8FF,
    MemoryKind.trip => 0xFFB48CFF,
    MemoryKind.hobby => 0xFF65E4FF,
  };
}

MemorySticker _quickStickerFor(MemoryKind kind) {
  return switch (kind) {
    MemoryKind.giftGiven || MemoryKind.giftReceived => MemorySticker.ribbon,
    MemoryKind.meal => MemorySticker.plate,
    MemoryKind.cafe => MemorySticker.cup,
    MemoryKind.trip => MemorySticker.flag,
    MemoryKind.hobby => MemorySticker.sparkle,
  };
}

MemoryStamp _quickStampFor(MemoryKind kind) {
  return switch (kind) {
    MemoryKind.giftGiven || MemoryKind.giftReceived => MemoryStamp.grateful,
    MemoryKind.meal => MemoryStamp.cozy,
    MemoryKind.cafe => MemoryStamp.cozy,
    MemoryKind.trip => MemoryStamp.bright,
    MemoryKind.hobby => MemoryStamp.funny,
  };
}
