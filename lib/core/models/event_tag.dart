class EventTag {
  final int? id;
  final int eventId;
  final String tag;

  const EventTag({
    this.id,
    required this.eventId,
    required this.tag,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'event_id': eventId,
      'tag': tag,
    };
  }

  static EventTag fromMap(Map<String, dynamic> map) {
    return EventTag(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      tag: map['tag'] as String,
    );
  }
}
