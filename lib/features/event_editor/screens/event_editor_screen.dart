import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/core/utils/on_device_event_inference.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/providers/location_provider.dart';
import 'package:life_replay/core/services/location_service.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
import 'package:life_replay/shared/widgets/location_chip.dart';
import 'package:life_replay/shared/widgets/location_picker_dialog.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  final int? eventId;
  final String? initialContent;

  const EventEditorScreen({super.key, this.eventId, this.initialContent});

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();

  String? _photoPath;
  bool _isLoading = false;
  bool _isEditing = false;
  LifeEvent? _originalEvent;
  DateTime _timestamp = DateTime.now();
  List<String> _existingTags = const [];
  double? _latitude;
  double? _longitude;
  String? _locationName;
  EventInferenceResult _inference =
      OnDeviceEventInference.infer('', fallbackMood: 3);

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_refreshInference);

    if (widget.eventId != null) {
      _isEditing = true;
      _loadEvent();
    } else if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _contentController.text = widget.initialContent!;
      _refreshInference();
    }
  }

  Future<void> _loadEvent() async {
    final db = ref.read(databaseProvider);
    final event = await db.getEventById(widget.eventId!);
    if (event != null && mounted) {
      final tags = await db.getTagsForEvent(event.id!);
      _originalEvent = event;
      _contentController.text = event.content;
      _timestamp = event.timestamp;
      _photoPath = event.photoPath;
      _latitude = event.latitude;
      _longitude = event.longitude;
      _locationName = event.locationName;
      setState(() {
        _existingTags = tags;
      });
      _refreshInference();
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_refreshInference);
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshInference() {
    final next = OnDeviceEventInference.infer(
      _contentController.text,
      fallbackTitle: _originalEvent?.title,
      fallbackMood: _originalEvent?.mood ?? 3,
    );
    if (next.title == _inference.title && next.mood == _inference.mood) return;
    if (!mounted) return;
    setState(() {
      _inference = next;
    });
  }

  Future<void> _insertImageInline() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  void _insertAtCursor(String text) {
    final value = _contentController.value;
    final selection = value.selection;
    if (!selection.isValid) {
      _contentController.text = '${value.text}$text';
      _contentController.selection =
          TextSelection.collapsed(offset: _contentController.text.length);
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final updated = value.text.replaceRange(start, end, text);
    _contentController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  Future<void> _captureCurrentLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );

      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final locationName = await LocationService.getLocationName(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _locationName = locationName;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locationName ?? 'Location captured',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Check permissions and try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showLocationPicker() async {
    try {
      final selectedLocation = await showDialog<LatLng>(
        context: context,
        builder: (context) => LocationPickerDialog(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      );

      if (selectedLocation != null && mounted) {
        final locationName = await LocationService.getLocationName(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );

        setState(() {
          _latitude = selectedLocation.latitude;
          _longitude = selectedLocation.longitude;
          _locationName = locationName;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationName ?? 'Location selected'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location cleared')),
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final inferred = OnDeviceEventInference.infer(
      content,
      fallbackTitle: _originalEvent?.title,
      fallbackMood: _originalEvent?.mood ?? 3,
    );

    final event = LifeEvent(
      id: _originalEvent?.id,
      title: inferred.title,
      content: content,
      mood: inferred.mood,
      timestamp: _timestamp,
      photoPath: _photoPath,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
    );

    try {
      if (_isEditing && _originalEvent != null) {
        await ref.read(eventsProvider.notifier).updateEvent(event, _existingTags);
      } else {
        await ref.read(eventsProvider.notifier).addEvent(event, _existingTags);
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
    final cs = context.appColors;

    return AppScaffold(
      title: _isEditing ? 'Edit Memory' : 'New Memory',
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: cs.surfaceVariant.withOpacity(0.35),
            child: Row(
              children: [
                Icon(Iconsax.magicpen, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'On-device AI: "${_inference.title}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appText.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  app_date_utils.moodEmoji(_inference.mood),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.surfaceVariant),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Insert image',
                          onPressed: _insertImageInline,
                          icon: const Icon(Iconsax.gallery),
                        ),
                        IconButton(
                          tooltip: 'Bullet list',
                          onPressed: () => _insertAtCursor('\n- '),
                          icon: const Icon(Iconsax.textalign_left),
                        ),
                        IconButton(
                          tooltip: 'Highlight',
                          onPressed: () => _insertAtCursor(' **highlight** '),
                          icon: const Icon(Iconsax.pen_add),
                        ),
                        IconButton(
                          tooltip: 'Capture or choose location',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Iconsax.location),
                                      title: const Text('Use current location'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _captureCurrentLocation();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Iconsax.map),
                                      title: const Text('Choose from map'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showLocationPicker();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.location),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 16,
                    decoration: const InputDecoration(
                      hintText: 'Write your memory here...\\n\\nUse the inline toolbar above for quick formatting and images.',
                      border: InputBorder.none,
                    ),
                    style: context.appText.bodyLarge,
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_photoPath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _photoPath = null),
                      icon: const Icon(Iconsax.trash, size: 16),
                      label: const Text('Remove image'),
                    ),
                  ],
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 12),
                    LocationChip(
                      locationName: _locationName,
                      coordinates: LocationService.formatCoordinates(
                        _latitude!,
                        _longitude!,
                      ),
                      onClear: _clearLocation,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
