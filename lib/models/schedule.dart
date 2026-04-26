import 'teacher.dart';
import 'room.dart';
import 'subject.dart';

class ScheduleEntry {
  final String id;
  final Subject subject;
  final Teacher teacher;
  final Room room;
  final String section;
  final String day; // Monday, Tuesday, etc.
  final String timeStart; // HH:mm format
  final String timeEnd;
  final String semester;
  final String academicYear;
  final bool hasConflict;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ScheduleEntry({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.section,
    required this.day,
    required this.timeStart,
    required this.timeEnd,
    required this.semester,
    required this.academicYear,
    required this.hasConflict,
    required this.createdAt,
    this.updatedAt,
  });

  String get timeRange => '$timeStart – $timeEnd';

  String get fullLabel => '${subject.code} | ${teacher.fullName} | ${room.name}';

  ScheduleEntry copyWith({
    String? id,
    Subject? subject,
    Teacher? teacher,
    Room? room,
    String? section,
    String? day,
    String? timeStart,
    String? timeEnd,
    String? semester,
    String? academicYear,
    bool? hasConflict,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      section: section ?? this.section,
      day: day ?? this.day,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      hasConflict: hasConflict ?? this.hasConflict,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectCode': subject.code,
      'subjectName': subject.name,
      'teacherName': teacher.fullName,
      'roomName': room.name,
      'section': section,
      'day': day,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'semester': semester,
      'academicYear': academicYear,
      'hasConflict': hasConflict,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum ConflictType {
  doubleBookedRoom,
  teacherDoubleScheduled,
  equipmentMismatch,
  roomCapacityMismatch,
  roomTypeMismatch,
}

class ScheduleConflict {
  final String id;
  final ConflictType type;
  final ScheduleEntry conflictingEntry1;
  final ScheduleEntry conflictingEntry2;
  final String description;
  final bool isResolved;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  ScheduleConflict({
    required this.id,
    required this.type,
    required this.conflictingEntry1,
    required this.conflictingEntry2,
    required this.description,
    required this.isResolved,
    required this.detectedAt,
    this.resolvedAt,
  });

  String get typeLabel {
    switch (type) {
      case ConflictType.doubleBookedRoom:
        return 'Double-booked Room';
      case ConflictType.teacherDoubleScheduled:
        return 'Teacher Double Scheduled';
      case ConflictType.equipmentMismatch:
        return 'Equipment Mismatch';
      case ConflictType.roomCapacityMismatch:
        return 'Room Capacity Mismatch';
      case ConflictType.roomTypeMismatch:
        return 'Room Type Mismatch';
    }
  }

  ScheduleConflict copyWith({
    bool? isResolved,
    DateTime? resolvedAt,
  }) {
    return ScheduleConflict(
      id: id,
      type: type,
      conflictingEntry1: conflictingEntry1,
      conflictingEntry2: conflictingEntry2,
      description: description,
      isResolved: isResolved ?? this.isResolved,
      detectedAt: detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final bool isFromTeacher;
  final DateTime timestamp;
  final bool isResolved;
  final String? adminResponse;
  /// true = approved, false = rejected, null = not yet actioned
  final bool? wasApproved;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isFromTeacher,
    required this.timestamp,
    required this.isResolved,
    this.adminResponse,
    this.wasApproved,
  });

  ChatMessage copyWith({
    bool? isResolved,
    String? adminResponse,
    bool? wasApproved,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      message: message,
      isFromTeacher: isFromTeacher,
      timestamp: timestamp,
      isResolved: isResolved ?? this.isResolved,
      adminResponse: adminResponse ?? this.adminResponse,
      wasApproved: wasApproved ?? this.wasApproved,
    );
  }
}