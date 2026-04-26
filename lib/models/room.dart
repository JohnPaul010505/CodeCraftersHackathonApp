enum RoomType { lecture, laboratory }
enum RoomStatus { available, occupied, maintenance, event }

class Room {
  final String id;
  final String name;
  final int floor;
  final int capacity;
  final RoomType type;
  final bool hasProjector;
  final bool hasAirConditioning;
  final bool hasComputers;
  final RoomStatus status;
  final String? currentSubject;
  final String? currentTeacher;
  final String? currentSection;
  final String? currentTimeStart;
  final String? currentTimeEnd;
  final String? eventNote;

  Room({
    required this.id,
    required this.name,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.hasProjector,
    required this.hasAirConditioning,
    required this.hasComputers,
    required this.status,
    this.currentSubject,
    this.currentTeacher,
    this.currentSection,
    this.currentTimeStart,
    this.currentTimeEnd,
    this.eventNote,
  });

  bool get isAvailable => status == RoomStatus.available;

  String get typeLabel => type == RoomType.laboratory ? 'Laboratory' : 'Lecture';

  String get statusLabel {
    switch (status) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.maintenance:
        return 'Maintenance';
      case RoomStatus.event:
        return 'Event';
    }
  }

  Room copyWith({
    String? id,
    String? name,
    int? floor,
    int? capacity,
    RoomType? type,
    bool? hasProjector,
    bool? hasAirConditioning,
    bool? hasComputers,
    RoomStatus? status,
    String? currentSubject,
    String? currentTeacher,
    String? currentSection,
    String? currentTimeStart,
    String? currentTimeEnd,
    String? eventNote,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      hasProjector: hasProjector ?? this.hasProjector,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      hasComputers: hasComputers ?? this.hasComputers,
      status: status ?? this.status,
      currentSubject: currentSubject ?? this.currentSubject,
      currentTeacher: currentTeacher ?? this.currentTeacher,
      currentSection: currentSection ?? this.currentSection,
      currentTimeStart: currentTimeStart ?? this.currentTimeStart,
      currentTimeEnd: currentTimeEnd ?? this.currentTimeEnd,
      eventNote: eventNote ?? this.eventNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'capacity': capacity,
      'type': type.toString(),
      'hasProjector': hasProjector,
      'hasAirConditioning': hasAirConditioning,
      'hasComputers': hasComputers,
      'status': status.toString(),
      'currentSubject': currentSubject,
      'currentTeacher': currentTeacher,
      'currentSection': currentSection,
      'currentTimeStart': currentTimeStart,
      'currentTimeEnd': currentTimeEnd,
      'eventNote': eventNote,
    };
  }
}
