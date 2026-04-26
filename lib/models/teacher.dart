import 'subject.dart';

enum TeacherStatus { active, inactive, onLeave }

class Teacher {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String employeeId;
  final String department;
  final List<String> expertise;
  final String unitType; // Regular, Part-time, Overload
  final int maxUnits;
  final int currentUnits;
  final String? profileImageUrl;
  final TeacherStatus status;
  final List<String> availableDays;
  final String availableTimeStart;
  final String availableTimeEnd;
  final List<Subject> assignedSubjects;
  final String password; // For login
  final List<String> sections;    // e.g. ['BSCS 1-A', 'BSCS 1-B']
  final List<String> yearLevels;  // e.g. ['1st Year', '2nd Year']
  final String semester;          // e.g. '1st Semester'

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.expertise,
    required this.unitType,
    required this.maxUnits,
    required this.currentUnits,
    this.profileImageUrl,
    required this.status,
    required this.availableDays,
    required this.availableTimeStart,
    required this.availableTimeEnd,
    required this.assignedSubjects,
    required this.password,
    this.sections = const [],
    this.yearLevels = const [],
    this.semester = '1st Semester',
  });

  String get fullName => '$firstName $lastName';

  bool get isOverloaded => currentUnits > maxUnits;

  double get loadPercentage => maxUnits > 0 ? currentUnits / maxUnits : 0;

  Teacher copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? employeeId,
    String? department,
    List<String>? expertise,
    String? unitType,
    int? maxUnits,
    int? currentUnits,
    String? profileImageUrl,
    TeacherStatus? status,
    List<String>? availableDays,
    String? availableTimeStart,
    String? availableTimeEnd,
    List<Subject>? assignedSubjects,
    String? password,
    List<String>? sections,
    List<String>? yearLevels,
    String? semester,
  }) {
    return Teacher(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      expertise: expertise ?? this.expertise,
      unitType: unitType ?? this.unitType,
      maxUnits: maxUnits ?? this.maxUnits,
      currentUnits: currentUnits ?? this.currentUnits,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      availableDays: availableDays ?? this.availableDays,
      availableTimeStart: availableTimeStart ?? this.availableTimeStart,
      availableTimeEnd: availableTimeEnd ?? this.availableTimeEnd,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      password: password ?? this.password,
      sections: sections ?? this.sections,
      yearLevels: yearLevels ?? this.yearLevels,
      semester: semester ?? this.semester,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'employeeId': employeeId,
      'department': department,
      'expertise': expertise,
      'unitType': unitType,
      'maxUnits': maxUnits,
      'currentUnits': currentUnits,
      'profileImageUrl': profileImageUrl,
      'status': status.toString(),
      'availableDays': availableDays,
      'availableTimeStart': availableTimeStart,
      'availableTimeEnd': availableTimeEnd,
      'sections': sections,
      'yearLevels': yearLevels,
      'semester': semester,
    };
  }
}