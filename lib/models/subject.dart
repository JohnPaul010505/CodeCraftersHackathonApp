import 'room.dart';

enum SubjectType { lecture, laboratory }

class Subject {
  final String id;
  final String code;
  final String name;
  final String description;
  final int units;
  final int hours;
  final SubjectType type;
  final String department;
  final List<String> requiredExpertise;
  final bool requiresProjector;
  final bool requiresComputers;
  final int minRoomCapacity;
  final String yearLevel;
  final String semester;
  // ✅ NEW: sections this subject is assigned to
  final List<String> sections;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.units,
    required this.hours,
    required this.type,
    required this.department,
    required this.requiredExpertise,
    required this.requiresProjector,
    required this.requiresComputers,
    required this.minRoomCapacity,
    required this.yearLevel,
    required this.semester,
    this.sections = const [],
  });

  String get typeLabel => type == SubjectType.laboratory ? 'Laboratory' : 'Lecture';

  bool matchesRoom(RoomType roomType) {
    if (type == SubjectType.laboratory) return roomType == RoomType.laboratory;
    return roomType == RoomType.lecture;
  }

  Subject copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    int? units,
    int? hours,
    SubjectType? type,
    String? department,
    List<String>? requiredExpertise,
    bool? requiresProjector,
    bool? requiresComputers,
    int? minRoomCapacity,
    String? yearLevel,
    String? semester,
    List<String>? sections,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      units: units ?? this.units,
      hours: hours ?? this.hours,
      type: type ?? this.type,
      department: department ?? this.department,
      requiredExpertise: requiredExpertise ?? this.requiredExpertise,
      requiresProjector: requiresProjector ?? this.requiresProjector,
      requiresComputers: requiresComputers ?? this.requiresComputers,
      minRoomCapacity: minRoomCapacity ?? this.minRoomCapacity,
      yearLevel: yearLevel ?? this.yearLevel,
      semester: semester ?? this.semester,
      sections: sections ?? this.sections,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'units': units,
      'hours': hours,
      'type': type.toString(),
      'department': department,
      'requiredExpertise': requiredExpertise,
      'requiresProjector': requiresProjector,
      'requiresComputers': requiresComputers,
      'minRoomCapacity': minRoomCapacity,
      'yearLevel': yearLevel,
      'semester': semester,
      'sections': sections,
    };
  }
}