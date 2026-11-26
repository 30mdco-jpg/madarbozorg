/// یک یادداشت خانوادگی. اگر [toFamilyId] خالی باشد یادداشت همگانی است.
class Note {
  const Note({
    required this.id,
    required this.authorId,
    required this.authorFamilyId,
    required this.toFamilyId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorFamilyId;
  final String? toFamilyId;
  final String body;
  final DateTime createdAt;

  bool get isPrivate => toFamilyId != null;

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        authorId: m['author_id'] as String,
        authorFamilyId: m['author_family_id'] as String,
        toFamilyId: m['to_family_id'] as String?,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toUtc(),
      );
}
