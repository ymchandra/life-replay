import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/shared/widgets/tag_chip.dart';
import 'package:uuid/uuid.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  final int? eventId;

  const EventEditorScreen({super.key, this.eventId});

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  static const _moodEmojis = ['😞', '😐', '🙂', '😊', '🤩'];
  static const _moodLabels = ['Awful', 'Meh', 'Okay', 'Good', 'Amazing'];

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  int _mood = 3;
  DateTime _selectedDate = DateTime.now();
  String? _photoPath;
  final List<String> _tags = [];
  bool _isLoading = false;
  bool _isEditing = false;
  LifeEvent? _originalEvent;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _isEditing = true;
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    final db = ref.read(databaseProvider);
    final event = await db.getEventById(widget.eventId!);
    if (event != null && mounted) {
      _originalEvent = event;
      _titleController.text = event.title;
      _contentController.text = event.content;
      _mood = event.mood;
      _selectedDate = event.timestamp;
      _photoPath = event.photoPath;
      final tags = await db.getTagsForEvent(event.id!);
      setState(() {
        _tags.addAll(tags);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          pickedTime?.hour ?? _selectedDate.hour,
          pickedTime?.minute ?? _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _photoPath = image.path);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final event = LifeEvent(
      id: _originalEvent?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _mood,
      timestamp: _selectedDate,
      photoPath: _photoPath,
    );

    try {
      if (_isEditing && _originalEvent != null) {
        await ref.read(eventsProvider.notifier).updateEvent(event, _tags);
      } else {
        await ref.read(eventsProvider.notifier).addEvent(event, _tags);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Memory'),
        content: const Text('Are you sure you want to delete this memory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && _originalEvent?.id != null) {
      await ref.read(eventsProvider.notifier).deleteEvent(_originalEvent!.id!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Memory' : 'New Memory'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.redAccent),
              onPressed: _delete,
            ),
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.tick_circle, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What happened?',
              ),
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Describe this moment...',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Mood
            Text('Mood', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final val = i + 1;
                final isSelected = _mood == val;
                return GestureDetector(
                  onTap: () => setState(() => _mood = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 56,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary.withOpacity(0.2) : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 26 : 22,
                          ),
                          child: Text(_moodEmojis[i]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moodLabels[i],
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.calendar, size: 20, color: cs.primary),
              ),
              title: Text(DateFormat('EEEE, MMMM d, yyyy – h:mm a').format(_selectedDate)),
              subtitle: const Text('Tap to change'),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: cs.surfaceVariant),
              ),
              tileColor: cs.surfaceVariant,
            ),
            const SizedBox(height: 16),

            // Tags
            Text('Tags', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag...',
                      isDense: true,
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addTag(_tagController.text),
                  icon: const Icon(Iconsax.add_circle),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _tags
                    .map((t) => TagChip(
                          label: t,
                          onDeleted: () => setState(() => _tags.remove(t)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Photo
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: Icon(_photoPath != null ? Iconsax.tick_circle : Iconsax.gallery),
              label: Text(_photoPath != null ? 'Photo attached' : 'Add Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _photoPath != null ? cs.secondary : cs.onSurface,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
