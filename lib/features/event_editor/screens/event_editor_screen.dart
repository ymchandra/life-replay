import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_replay/core/models/life_event.dart';
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

class _EventEditorScreenState extends ConsumerState<EventEditorScreen>
    with TickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final _contentFocusNode = FocusNode();
  late AnimationController _toolbarAnimController;
  late Animation<double> _toolbarOpacity;
  late Animation<Offset> _toolbarSlide;

  String? _photoPath;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isToolbarVisible = false;
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
    _contentFocusNode.addListener(_updateToolbarVisibility);

    // Setup toolbar animations
    _toolbarAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _toolbarOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _toolbarAnimController, curve: Curves.easeOut),
    );
    _toolbarSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _toolbarAnimController, curve: Curves.easeOut),
    );

    if (widget.eventId != null) {
      _isEditing = true;
      _loadEvent();
    } else if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _contentController.text = widget.initialContent!;
      _refreshInference();
    }
  }

  void _updateToolbarVisibility() {
    final isFocused = _contentFocusNode.hasFocus;
    if (isFocused && !_isToolbarVisible) {
      setState(() => _isToolbarVisible = true);
      _toolbarAnimController.forward();
    } else if (!isFocused && _isToolbarVisible) {
      _toolbarAnimController.reverse().then((_) {
        if (mounted) {
          setState(() => _isToolbarVisible = false);
        }
      });
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
    _contentFocusNode.removeListener(_updateToolbarVisibility);
    _contentFocusNode.dispose();
    _scrollController.dispose();
    _toolbarAnimController.dispose();
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

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final timeStr = '$h:$minute $period';
    if (d == today) return 'Today, $timeStr';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday, $timeStr';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $timeStr';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'When did this happen?',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
      helpText: 'What time?',
    );
    if (!mounted) return;

    setState(() {
      _timestamp = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _timestamp.hour,
        pickedTime?.minute ?? _timestamp.minute,
      );
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
    final inferredTags = OnDeviceEventInference.inferTags(
      content,
      baseTags: _existingTags,
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
        await ref.read(eventsProvider.notifier).updateEvent(event, inferredTags);
      } else {
        await ref.read(eventsProvider.notifier).addEvent(event, inferredTags);
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
            child: Text('Delete', style: TextStyle(color: context.appColors.error)),
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
            icon: Icon(Iconsax.trash, color: context.appColors.error),
            onPressed: _delete,
          ),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : IconButton(
                onPressed: _save,
                icon: Icon(
                  Iconsax.tick_circle,
                  size: 26,
                  color: context.appColors.secondary,
                ),
                tooltip: 'Save memory',
              ),
      ],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date/time picker chip
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.outline.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.calendar_edit, size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimestamp(_timestamp),
                            style: context.appText.labelMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Iconsax.arrow_down_1, size: 12,
                              color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Text field
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 16,
                    decoration: InputDecoration(
                      hintText: 'Write your memory here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.surfaceVariant, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: cs.surfaceVariant.withOpacity(0.6), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: cs.primary.withOpacity(0.8), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      filled: true,
                      fillColor: cs.surface,
                    ),
                    style: context.appText.bodyLarge,
                  ),
                  // Inline toolbar — slides in below the text field when focused
                  if (_isToolbarVisible)
                    SlideTransition(
                      position: _toolbarSlide,
                      child: FadeTransition(
                        opacity: _toolbarOpacity,
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(
                              left: BorderSide(
                                  color: cs.surfaceVariant.withOpacity(0.6)),
                              right: BorderSide(
                                  color: cs.surfaceVariant.withOpacity(0.6)),
                              bottom: BorderSide(
                                  color: cs.surfaceVariant.withOpacity(0.6)),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ToolbarIconButton(
                                icon: Iconsax.gallery,
                                tooltip: 'Add image',
                                onPressed: _insertImageInline,
                              ),
                              _ToolbarIconButton(
                                icon: Iconsax.textalign_left,
                                tooltip: 'Bullet point',
                                onPressed: () => _insertAtCursor('\n• '),
                              ),
                              _ToolbarIconButton(
                                icon: Iconsax.pen_add,
                                tooltip: 'Highlight',
                                onPressed: () =>
                                    _insertAtCursor(' **highlight** '),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: cs.surfaceVariant.withOpacity(0.3),
                              ),
                              _ToolbarIconButton(
                                icon: Iconsax.location,
                                tooltip: 'Add location',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading:
                                                const Icon(Iconsax.location),
                                            title: const Text(
                                                'Use current location'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _captureCurrentLocation();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Iconsax.map),
                                            title:
                                                const Text('Choose from map'),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                   const SizedBox(height: 12),
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

/// Compact toolbar icon button for the floating formatting toolbar
class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

