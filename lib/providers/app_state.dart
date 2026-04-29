import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/room.dart';
import '../models/subject.dart';
import '../models/schedule.dart';
import '../data/mock_data.dart';


// ─────────────────────────────────────────────────────────────────────────────
// RoomOverride — represents a blocked room slot (event / meeting / maintenance)
// ─────────────────────────────────────────────────────────────────────────────
class RoomOverride {
  final String id;
  final String roomId;
  final String roomName;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;

  RoomOverride({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.reason,
    required this.startDate,
    required this.endDate,
  });

  /// True if this override covers any part of [date] (ignores time, day-level check)
  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'roomName': roomName,
    'reason': reason,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };

  factory RoomOverride.fromMap(String id, Map<String, dynamic> d) => RoomOverride(
    id: id,
    roomId: d['roomId'] ?? '',
    roomName: d['roomName'] ?? '',
    reason: d['reason'] ?? '',
    startDate: DateTime.parse(d['startDate'] ?? DateTime.now().toIso8601String()),
    endDate: DateTime.parse(d['endDate'] ?? DateTime.now().toIso8601String()),
  );
}

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  Teacher? _currentTeacher;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  Teacher? get currentTeacher => _currentTeacher;

  List<Teacher> _teachers = [];
  List<Room> _rooms = [];
  List<Subject> _subjects = [];
  List<String> _sections = [];
  List<ScheduleEntry> _scheduleEntries = [];
  List<ScheduleConflict> _conflicts = [];
  List<ChatMessage> _chatMessages = [];
  List<RoomOverride> _roomOverrides = [];
  // ── Request-driven state ──────────────────────────────────────────────────
  Set<String> _cancelledEntryIds = {};
  Map<String, String> _teacherRequestStatuses = {};

  List<Teacher> get teachers => List.unmodifiable(_teachers);
  List<Room> get rooms => List.unmodifiable(_rooms);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<String> get sections => List.unmodifiable(_sections);
  List<ScheduleEntry> get scheduleEntries => List.unmodifiable(_scheduleEntries);
  List<ScheduleConflict> get conflicts => List.unmodifiable(_conflicts);
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<RoomOverride> get roomOverrides => List.unmodifiable(_roomOverrides);
  Set<String> get cancelledEntryIds => Set.unmodifiable(_cancelledEntryIds);
  Map<String, String> get teacherRequestStatuses => Map.unmodifiable(_teacherRequestStatuses);

  int get availableRooms => _rooms.where((r) => r.status == RoomStatus.available).length;
  int get occupiedRooms => _rooms.where((r) => r.status == RoomStatus.occupied).length;
  int get scheduledClasses => _scheduleEntries.length;
  int get activeConflicts => _conflicts.where((c) => !c.isResolved).length;
  int get pendingChatRequests => _chatMessages.where((m) => !m.isResolved).length;
  double get occupancyRate => _rooms.isEmpty ? 0 : occupiedRooms / _rooms.length;

  final _db = FirebaseFirestore.instance;

  // ── Real-time chat stream subscription ───────────────────────────────────
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<QuerySnapshot>? _scheduleSubscription;
  StreamSubscription<QuerySnapshot>? _cancelledSubscription;
  StreamSubscription<QuerySnapshot>? _statusSubscription;
  StreamSubscription<QuerySnapshot>? _overrideSubscription;
  StreamSubscription<QuerySnapshot>? _roomSubscription; // real-time room sync

  AppState() { _loadData(); }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _scheduleSubscription?.cancel();
    _cancelledSubscription?.cancel();
    _statusSubscription?.cancel();
    _overrideSubscription?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }

  // ── Load: Firestore first, fall back to MockData ─────────────────────────
  Future<void> _loadData() async {
    // Seed non-chat data with mock data so UI is never empty
    _teachers = List.from(MockData.teachers);
    _rooms = List.from(MockData.rooms);
    _subjects = List.from(MockData.subjects);
    _sections = [
      'BSCS 1-A','BSCS 1-B','BSCS 1-C',
      'BSCS 2-A','BSCS 2-B','BSCS 2-C',
      'BSCS 3-A','BSCS 3-B','BSCS 3-C',
      'BSCS 4-A','BSCS 4-B',
      'BSIT 1-A','BSIT 1-B',
      'BSIT 2-A','BSIT 2-B',
      'BSIT 3-A','BSIT 3-B',
      'BSIT 4-A','BSIT 4-B',
    ];
    _scheduleEntries = List.from(MockData.scheduleEntries);
    _conflicts = MockData.conflicts;
    // NOTE: _chatMessages intentionally NOT seeded from MockData —
    // Firestore is the single source of truth for chat messages.
    _chatMessages = [];
    notifyListeners();

    // Overlay with Firestore data
    await _loadSubjectsFromFirestore();
    await _loadTeachersFromFirestore();
    await Future.wait([
      _loadRoomsFromFirestore(),
      _loadSectionsFromFirestore(),
    ]);
    _resolveTeacherSubjects();
    _detectConflicts();
    notifyListeners();

    _subscribeToSchedules();
    _subscribeToChatMessages();
    _subscribeToCancelledClasses();
    _subscribeToTeacherRequestStatuses();
    _subscribeToRoomOverrides();
    _subscribeToRooms();
  }

  // ── Real-time Firestore listener for schedules ────────────────────────────
  void _subscribeToSchedules() {
    _scheduleSubscription?.cancel();
    _scheduleSubscription = _db
        .collection('schedules')
        .snapshots()
        .listen((snapshot) {
      final firestoreEntries = <ScheduleEntry>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final teacher = _teachers.cast<Teacher?>().firstWhere(
                (t) => t!.id == d['teacherId'], orElse: () => null);
        final room = _rooms.cast<Room?>().firstWhere(
                (r) => r!.id == d['roomId'], orElse: () => null);
        final subject = _subjects.cast<Subject?>().firstWhere(
                (s) => s!.id == d['subjectId'], orElse: () => null);
        if (teacher == null || room == null || subject == null) continue;
        firestoreEntries.add(ScheduleEntry(
          id: doc.id,
          subject: subject,
          teacher: teacher,
          room: room,
          section: d['section'] ?? '',
          day: d['day'] ?? '',
          timeStart: d['timeStart'] ?? '',
          timeEnd: d['timeEnd'] ?? '',
          semester: d['semester'] ?? '1st Semester',
          academicYear: d['academicYear'] ?? '2024-2025',
          hasConflict: d['hasConflict'] ?? false,
          createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          specificDate: d['specificDate'] != null
              ? DateTime.tryParse(d['specificDate'] as String)
              : null,
        ));
      }
      final firestoreIds = firestoreEntries.map((e) => e.id).toSet();
      final mockOnly = _scheduleEntries
          .where((e) => !firestoreIds.contains(e.id) && !e.id.startsWith('s'))
          .toList();
      _scheduleEntries = [...mockOnly, ...firestoreEntries];
      _detectConflicts();
      notifyListeners();
    }, onError: (e) => debugPrint('Schedule stream error: $e'));
  }

  // ── Real-time Firestore listener for chat messages ────────────────────────
  /// This keeps both the admin (on their computer) and the teacher (on their
  /// phone) in sync automatically — no restart required.
  void _subscribeToChatMessages() {
    _chatSubscription?.cancel(); // cancel any existing subscription first

    _chatSubscription = _db
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        _chatMessages = snapshot.docs.map((doc) {
          final d = doc.data();
          return ChatMessage(
            id: doc.id,
            senderId: d['senderId'] ?? '',
            senderName: d['senderName'] ?? '',
            message: d['message'] ?? '',
            isFromTeacher: d['isFromTeacher'] ?? true,
            timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isResolved: d['isResolved'] ?? false,
            adminResponse: d['adminResponse'],
            wasApproved: d['wasApproved'],
          );
        }).toList();
        notifyListeners();
      },
      onError: (e) => debugPrint('Chat stream error: $e'),
    );
  }

  // ── Real-time listener: cancelled classes ───────────────────────────────
  void _subscribeToCancelledClasses() {
    _cancelledSubscription?.cancel();
    _cancelledSubscription = _db.collection('cancelled_classes').snapshots().listen(
          (snap) {
        _cancelledEntryIds = snap.docs.map((d) => d.id).toSet();
        notifyListeners();
      },
      onError: (e) => debugPrint('Cancelled classes stream error: \$e'),
    );
  }

  // ── Real-time listener: teacher request statuses ─────────────────────────
  void _subscribeToTeacherRequestStatuses() {
    _statusSubscription?.cancel();
    _statusSubscription = _db.collection('teacher_request_statuses').snapshots().listen(
          (snap) {
        _teacherRequestStatuses = {
          for (final d in snap.docs) d.id: (d.data()['status'] as String? ?? ''),
        };
        notifyListeners();
      },
      onError: (e) => debugPrint('Teacher status stream error: \$e'),
    );
  }

  Future<void> _loadTeachersFromFirestore() async {
    try {
      final snap = await _db.collection('teachers').get();
      if (snap.docs.isEmpty) return;
      final firestoreTeachers = <Teacher>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final subjectIds = List<String>.from(d['assignedSubjectIds'] ?? []);
        if (subjectIds.isNotEmpty) _teacherSubjectIdMap[doc.id] = subjectIds;
        final assigned = _subjects.where((s) => subjectIds.contains(s.id)).toList();
        firestoreTeachers.add(Teacher(
          id: doc.id,
          firstName: d['firstName'] ?? '',
          lastName: d['lastName'] ?? '',
          email: d['email'] ?? '',
          employeeId: d['employeeId'] ?? '',
          department: d['department'] ?? '',
          expertise: List<String>.from(d['expertise'] ?? []),
          unitType: d['unitType'] ?? 'Regular',
          maxUnits: d['maxUnits'] ?? 21,
          currentUnits: d['currentUnits'] ?? 0,
          status: TeacherStatus.active,
          availableDays: List<String>.from(d['availableDays'] ?? ['Monday','Tuesday','Wednesday','Thursday','Friday']),
          availableTimeStart: d['availableTimeStart'] ?? '07:00',
          availableTimeEnd: d['availableTimeEnd'] ?? '18:00',
          assignedSubjects: assigned,
          password: '',
          sections: List<String>.from(d['sections'] ?? []),
          yearLevels: List<String>.from(d['yearLevels'] ?? (d['yearLevel'] != null ? [d['yearLevel']] : [])),
          semester: d['semester'] ?? '1st Semester',
        ));
      }
      final firestoreEmails = firestoreTeachers.map((t) => t.email).toSet();
      final mockOnly = _teachers.where((t) => !firestoreEmails.contains(t.email)).toList();
      _teachers = [...mockOnly, ...firestoreTeachers];
    } catch (e) {
      debugPrint('Error loading teachers from Firestore: $e');
    }
  }

  final Map<String, List<String>> _teacherSubjectIdMap = {};

  void _resolveTeacherSubjects() {
    _teachers = _teachers.map((teacher) {
      final ids = _teacherSubjectIdMap[teacher.id];
      if (ids == null || ids.isEmpty) return teacher;
      final resolved = _subjects.where((s) => ids.contains(s.id)).toList();
      if (resolved.isEmpty) return teacher;
      return teacher.copyWith(assignedSubjects: resolved);
    }).toList();
  }

  /// Public method so teacher/admin room screens can force a fresh pull
  /// from Firestore, keeping both views in sync in real time.
  Future<void> loadRoomsFromFirestore() => _loadRoomsFromFirestore();

  Future<void> _loadRoomsFromFirestore() async {
    try {
      final snap = await _db.collection('rooms').get();
      if (snap.docs.isEmpty) return;
      final firestoreRooms = snap.docs.map((doc) {
        final d = doc.data();
        return Room(
          id: doc.id,
          name: d['name'] ?? '',
          floor: d['floor'] ?? 1,
          capacity: d['capacity'] ?? 30,
          type: d['type'] == 'RoomType.laboratory' ? RoomType.laboratory : RoomType.lecture,
          hasProjector: d['hasProjector'] ?? false,
          hasAirConditioning: d['hasAirConditioning'] ?? false,
          hasComputers: d['hasComputers'] ?? false,
          status: _parseRoomStatus(d['status']),
          currentSubject: d['currentSubject'],
          currentTeacher: d['currentTeacher'],
          currentSection: d['currentSection'],
          currentTimeStart: d['currentTimeStart'],
          currentTimeEnd: d['currentTimeEnd'],
          eventNote: d['eventNote'],
        );
      }).toList();
      final firestoreNames = firestoreRooms.map((r) => r.name).toSet();
      final mockOnly = _rooms.where((r) => !firestoreNames.contains(r.name)).toList();
      _rooms = [...mockOnly, ...firestoreRooms];
    } catch (e) {
      debugPrint('Error loading rooms from Firestore: $e');
    }
  }

  /// Real-time Firestore stream for rooms — any status change made by the
  /// admin is instantly reflected on the teacher's room screen too.
  void _subscribeToRooms() {
    _roomSubscription?.cancel();
    _roomSubscription = _db.collection('rooms').snapshots().listen((snap) {
      if (snap.docs.isEmpty) return;
      final statusMap = <String, RoomStatus>{};
      final noteMap   = <String, String?>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        final rawStatus = d['status'] as String? ?? '';
        RoomStatus st;
        if (rawStatus.contains('occupied'))    st = RoomStatus.occupied;
        else if (rawStatus.contains('maintenance')) st = RoomStatus.maintenance;
        else if (rawStatus.contains('event'))  st = RoomStatus.event;
        else                                   st = RoomStatus.available;
        statusMap[doc.id] = st;
        noteMap[doc.id]   = d['eventNote'] as String?;
        // Also match by room name for mock rooms that don't have Firestore IDs
        final name = d['name'] as String?;
        if (name != null) {
          final mockIdx = _rooms.indexWhere((r) => r.name == name && r.id != doc.id);
          if (mockIdx != -1) {
            statusMap[_rooms[mockIdx].id] = st;
            noteMap[_rooms[mockIdx].id]   = d['eventNote'] as String?;
          }
        }
      }
      bool changed = false;
      for (int i = 0; i < _rooms.length; i++) {
        final newSt   = statusMap[_rooms[i].id];
        final newNote = noteMap[_rooms[i].id];
        if (newSt != null && (_rooms[i].status != newSt || _rooms[i].eventNote != newNote)) {
          _rooms[i] = _rooms[i].copyWith(status: newSt, eventNote: newNote);
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  Future<void> _loadSubjectsFromFirestore() async {
    try {
      final snap = await _db.collection('subjects').get();
      if (snap.docs.isEmpty) return;
      final firestoreSubjects = snap.docs.map((doc) {
        final d = doc.data();
        return Subject(
          id: doc.id,
          code: d['code'] ?? '',
          name: d['name'] ?? '',
          description: d['description'] ?? '',
          units: d['units'] ?? 3,
          hours: d['hours'] ?? 3,
          type: d['type'] == 'SubjectType.laboratory' ? SubjectType.laboratory : SubjectType.lecture,
          department: d['department'] ?? '',
          requiredExpertise: List<String>.from(d['requiredExpertise'] ?? []),
          requiresProjector: d['requiresProjector'] ?? false,
          requiresComputers: d['requiresComputers'] ?? false,
          minRoomCapacity: d['minRoomCapacity'] ?? 30,
          yearLevel: d['yearLevel'] ?? '1st Year',
          semester: d['semester'] ?? '1st Semester',
          sections: List<String>.from(d['sections'] ?? []),
        );
      }).toList();
      final firestoreCodes = firestoreSubjects.map((s) => s.code).toSet();
      final mockOnly = _subjects.where((s) => !firestoreCodes.contains(s.code)).toList();
      _subjects = [...mockOnly, ...firestoreSubjects];
    } catch (e) {
      debugPrint('Error loading subjects from Firestore: $e');
    }
  }

  RoomStatus _parseRoomStatus(String? s) {
    switch (s) {
      case 'RoomStatus.occupied': return RoomStatus.occupied;
      case 'RoomStatus.maintenance': return RoomStatus.maintenance;
      case 'RoomStatus.event': return RoomStatus.event;
      default: return RoomStatus.available;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  void setAdminLoggedIn() {
    _isLoggedIn = true; _isAdmin = true; _currentTeacher = null;
    notifyListeners();
  }

  void setTeacherLoggedInFromFirestore(String docId, Map<String, dynamic> data) {
    _isLoggedIn = true; _isAdmin = false;
    final email = data['email'] ?? '';
    final localMatch = _teachers.where((t) => t.email == email).toList();
    final resolvedId = localMatch.isNotEmpty ? localMatch.first.id : docId;
    final subjectIds = List<String>.from(data['assignedSubjectIds'] ?? []);
    var assigned = _subjects.where((s) => subjectIds.contains(s.id)).toList();
    if (assigned.isEmpty && subjectIds.isNotEmpty) {
      _teacherSubjectIdMap[resolvedId] = subjectIds;
    }
    _currentTeacher = Teacher(
      id: resolvedId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: email,
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      expertise: List<String>.from(data['expertise'] ?? []),
      unitType: data['unitType'] ?? 'Regular',
      maxUnits: data['maxUnits'] ?? 21,
      currentUnits: data['currentUnits'] ?? 0,
      status: TeacherStatus.active,
      availableDays: List<String>.from(data['availableDays'] ?? ['Monday','Tuesday','Wednesday','Thursday','Friday']),
      availableTimeStart: data['availableTimeStart'] ?? '07:00',
      availableTimeEnd: data['availableTimeEnd'] ?? '18:00',
      assignedSubjects: assigned,
      password: '',
      sections: List<String>.from(data['sections'] ?? []),
      yearLevels: List<String>.from(data['yearLevels'] ?? []),
      semester: data['semester'] ?? '1st Semester',
    );
    notifyListeners();
  }

  void setTeacherLoggedInFromFirebase({required String uid, required String email, required String displayName}) {
    _isLoggedIn = true; _isAdmin = false;
    final parts = displayName.split(' ');
    final localMatch = _teachers.where((t) => t.email == email).toList();
    final resolvedId = localMatch.isNotEmpty ? localMatch.first.id : uid;
    _currentTeacher = Teacher(
      id: resolvedId,
      firstName: localMatch.isNotEmpty ? localMatch.first.firstName : (parts.isNotEmpty ? parts.first : displayName),
      lastName: localMatch.isNotEmpty ? localMatch.first.lastName : (parts.length > 1 ? parts.last : ''),
      email: email,
      employeeId: localMatch.isNotEmpty ? localMatch.first.employeeId : uid.substring(0, 8).toUpperCase(),
      department: localMatch.isNotEmpty ? localMatch.first.department : 'General',
      expertise: localMatch.isNotEmpty ? localMatch.first.expertise : [],
      unitType: localMatch.isNotEmpty ? localMatch.first.unitType : 'Regular',
      maxUnits: localMatch.isNotEmpty ? localMatch.first.maxUnits : 21,
      currentUnits: 0,
      status: TeacherStatus.active,
      availableDays: localMatch.isNotEmpty ? localMatch.first.availableDays : ['Monday','Tuesday','Wednesday','Thursday','Friday'],
      availableTimeStart: localMatch.isNotEmpty ? localMatch.first.availableTimeStart : '07:00',
      availableTimeEnd: localMatch.isNotEmpty ? localMatch.first.availableTimeEnd : '18:00',
      assignedSubjects: localMatch.isNotEmpty ? localMatch.first.assignedSubjects : [],
      password: '',
      sections: localMatch.isNotEmpty ? localMatch.first.sections : [],
      yearLevels: localMatch.isNotEmpty ? localMatch.first.yearLevels : [],
      semester: localMatch.isNotEmpty ? localMatch.first.semester : '1st Semester',
    );
    notifyListeners();
  }

  bool loginAsAdmin(String username, String password) {
    if (username == 'admin' && password == 'admin123') { setAdminLoggedIn(); return true; }
    return false;
  }

  void logout() { _isLoggedIn = false; _isAdmin = false; _currentTeacher = null; notifyListeners(); }

  // ── Room Actions ─────────────────────────────────────────────────────────
  void updateRoomStatus(String roomId, RoomStatus status, {String? eventNote}) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(status: status, eventNote: eventNote);
      _saveRoomToFirestore(_rooms[idx]);
      notifyListeners();
    }
  }

  void addRoom(Room room) {
    _rooms.add(room);
    _saveRoomToFirestore(room);
    notifyListeners();
  }

  void updateRoom(Room room) {
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      _rooms[idx] = room;
      _saveRoomToFirestore(room);
      notifyListeners();
    }
  }

  void deleteRoom(String roomId) {
    _rooms.removeWhere((r) => r.id == roomId);
    _db.collection('rooms').doc(roomId).delete().catchError((_) {});
    notifyListeners();
  }

  void _saveRoomToFirestore(Room room) {
    _db.collection('rooms').doc(room.id).set(room.toMap(), SetOptions(merge: true))
        .catchError((e) => debugPrint('Save room error: $e'));
  }

  // ── Teacher Actions ──────────────────────────────────────────────────────
  void addTeacher(Teacher teacher) {
    _teachers.add(teacher);
    _saveTeacherToFirestore(teacher);
    notifyListeners();
  }

  void updateTeacher(Teacher teacher) {
    final idx = _teachers.indexWhere((t) => t.id == teacher.id);
    if (idx != -1) {
      _teachers[idx] = teacher;
      _saveTeacherToFirestore(teacher);
      notifyListeners();
    }
  }

  void deleteTeacher(String teacherId) {
    _teachers.removeWhere((t) => t.id == teacherId);
    _db.collection('teachers').doc(teacherId).delete().catchError((_) {});
    notifyListeners();
  }

  void _saveTeacherToFirestore(Teacher teacher) {
    final data = teacher.toMap();
    data['assignedSubjectIds'] = teacher.assignedSubjects.map((s) => s.id).toList();
    data['yearLevels'] = teacher.yearLevels;
    _db.collection('teachers').doc(teacher.id).set(data, SetOptions(merge: true))
        .catchError((e) => debugPrint('Save teacher error: $e'));
  }

  // ── Section Actions ─────────────────────────────────────────────────────
  void addSection(String section) {
    final trimmed = section.trim();
    if (trimmed.isEmpty || _sections.contains(trimmed)) return;
    _sections.add(trimmed);
    _sections.sort();
    _saveSectionsToFirestore();
    notifyListeners();
  }

  void updateSection(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final idx = _sections.indexOf(oldName);
    if (idx == -1) return;
    _sections[idx] = trimmed;
    _sections.sort();
    _saveSectionsToFirestore();
    notifyListeners();
  }

  void deleteSection(String section) {
    _sections.remove(section);
    _saveSectionsToFirestore();
    notifyListeners();
  }

  Future<void> _loadSectionsFromFirestore() async {
    try {
      final doc = await _db.collection('config').doc('sections').get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final firestoreList = List<String>.from(data['list'] ?? []);
      if (firestoreList.isEmpty) return;
      // Merge: keep mock defaults + any Firestore-only additions
      final merged = <String>{..._sections, ...firestoreList}.toList()..sort();
      _sections = merged;
    } catch (e) {
      debugPrint('Error loading sections from Firestore: $e');
    }
  }

  void _saveSectionsToFirestore() {
    _db.collection('config').doc('sections').set(
      {'list': _sections, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    ).catchError((e) => debugPrint('Save sections error: $e'));
  }

  // ── Subject Actions ──────────────────────────────────────────────────────
  void addSubject(Subject subject) {
    _subjects.add(subject);
    _saveSubjectToFirestore(subject);
    notifyListeners();
  }

  void updateSubject(Subject subject) {
    final idx = _subjects.indexWhere((s) => s.id == subject.id);
    if (idx != -1) {
      _subjects[idx] = subject;
      _saveSubjectToFirestore(subject);
      notifyListeners();
    }
  }

  void deleteSubject(String subjectId) {
    _subjects.removeWhere((s) => s.id == subjectId);
    _db.collection('subjects').doc(subjectId).delete().catchError((_) {});
    notifyListeners();
  }

  void _saveSubjectToFirestore(Subject subject) {
    _db.collection('subjects').doc(subject.id).set(subject.toMap(), SetOptions(merge: true))
        .catchError((e) => debugPrint('Save subject error: $e'));
  }

  // ── Schedule Actions ─────────────────────────────────────────────────────
  void addScheduleEntry(ScheduleEntry entry) {
    _scheduleEntries.add(entry);
    _saveScheduleToFirestore(entry);
    _detectConflicts();
    notifyListeners();
  }

  void updateScheduleEntry(ScheduleEntry entry) {
    final idx = _scheduleEntries.indexWhere((s) => s.id == entry.id);
    if (idx != -1) {
      _scheduleEntries[idx] = entry;
      _saveScheduleToFirestore(entry);
      _detectConflicts();
      notifyListeners();
    }
  }

  void deleteScheduleEntry(String entryId) {
    _scheduleEntries.removeWhere((s) => s.id == entryId);
    _conflicts.removeWhere(
            (c) => c.conflictingEntry1.id == entryId || c.conflictingEntry2.id == entryId);
    _db.collection('schedules').doc(entryId).delete().catchError((_) {});
    _detectConflicts();
    notifyListeners();
  }

  void _saveScheduleToFirestore(ScheduleEntry entry) {
    _db.collection('schedules').doc(entry.id).set({
      'subjectId': entry.subject.id,
      'teacherId': entry.teacher.id,
      'roomId': entry.room.id,
      'section': entry.section,
      'day': entry.day,
      'timeStart': entry.timeStart,
      'timeEnd': entry.timeEnd,
      'semester': entry.semester,
      'academicYear': entry.academicYear,
      'hasConflict': entry.hasConflict,
      'createdAt': FieldValue.serverTimestamp(),
      if (entry.specificDate != null)
        'specificDate': entry.specificDate!.toIso8601String(),
    }, SetOptions(merge: true)).catchError((e) => debugPrint('Save schedule error: $e'));
  }

  // ── Schedule Queries ─────────────────────────────────────────────────────
  List<ScheduleEntry> getTeacherSchedule(String teacherId) {
    final byId = _scheduleEntries.where((s) => s.teacher.id == teacherId).toList();
    if (byId.isNotEmpty) return byId;

    final localById = _teachers.cast<Teacher?>().firstWhere(
            (t) => t!.id == teacherId, orElse: () => null);
    if (localById != null) {
      final byEmail = _scheduleEntries.where((s) => s.teacher.email == localById.email).toList();
      if (byEmail.isNotEmpty) return byEmail;
    }

    final teacher = _currentTeacher;
    if (teacher == null) return [];
    final localByEmail = _teachers.cast<Teacher?>().firstWhere(
            (t) => t!.email == teacher.email, orElse: () => null);
    final matchEmail = localByEmail?.email ?? teacher.email;
    return _scheduleEntries.where((s) => s.teacher.email == matchEmail).toList();
  }

  List<ScheduleEntry> getRoomSchedule(String roomId) =>
      _scheduleEntries.where((s) => s.room.id == roomId).toList();

  List<Subject> getTeacherSubjects(String teacherId) {
    final entries = getTeacherSchedule(teacherId);
    if (entries.isNotEmpty) {
      final seen = <String>{};
      return entries.map((e) => e.subject).where((s) => seen.add(s.id)).toList();
    }
    final teacher = _teachers.cast<Teacher?>().firstWhere(
            (t) => t!.id == teacherId, orElse: () => _currentTeacher);
    if (teacher == null) return [];
    if (teacher.assignedSubjects.isNotEmpty) return teacher.assignedSubjects;
    return _subjects.where((s) =>
    s.department == teacher.department ||
        s.requiredExpertise.any((e) => teacher.expertise.contains(e))).toList();
  }

  // ── Conflict Detection ───────────────────────────────────────────────────
  void _detectConflicts() {
    final newConflicts = <ScheduleConflict>[];
    final entries = List<ScheduleEntry>.from(_scheduleEntries);
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final e1 = entries[i]; final e2 = entries[j];
        if (e1.day == e2.day && _timesOverlap(e1, e2)) {
          if (e1.room.id == e2.room.id) {
            newConflicts.add(ScheduleConflict(
              id: 'c_room_${DateTime.now().millisecondsSinceEpoch}_$i$j',
              type: ConflictType.doubleBookedRoom,
              conflictingEntry1: e1, conflictingEntry2: e2,
              description: 'Room ${e1.room.name} is double-booked on ${e1.day}.',
              isResolved: false, detectedAt: DateTime.now(),
            ));
          }
          if (e1.teacher.id == e2.teacher.id) {
            newConflicts.add(ScheduleConflict(
              id: 'c_teacher_${DateTime.now().millisecondsSinceEpoch}_t$i$j',
              type: ConflictType.teacherDoubleScheduled,
              conflictingEntry1: e1, conflictingEntry2: e2,
              description: '${e1.teacher.fullName} is double-scheduled on ${e1.day}.',
              isResolved: false, detectedAt: DateTime.now(),
            ));
          }
        }
      }
    }
    _conflicts = newConflicts;
  }

  bool _timesOverlap(ScheduleEntry e1, ScheduleEntry e2) {
    final s1 = _toMin(e1.timeStart), end1 = _toMin(e1.timeEnd);
    final s2 = _toMin(e2.timeStart), end2 = _toMin(e2.timeEnd);
    return s1 < end2 && s2 < end1;
  }

  int _toMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  void resolveConflict(String conflictId) {
    final idx = _conflicts.indexWhere((c) => c.id == conflictId);
    if (idx != -1) {
      _conflicts[idx] = _conflicts[idx].copyWith(isResolved: true, resolvedAt: DateTime.now());
      notifyListeners();
    }
  }

  // ── Chat Actions ─────────────────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _localChatHistory = {};
  final Map<String, Set<String>> _notifiedMessageIds = {};

  List<Map<String, dynamic>> getTeacherLocalHistory(String teacherId) =>
      List.unmodifiable(_localChatHistory[teacherId] ?? []);

  void saveTeacherLocalHistory(String teacherId, List<Map<String, dynamic>> bubbles) {
    _localChatHistory[teacherId] = List.from(bubbles);
  }

  bool isMessageNotified(String teacherId, String messageId) =>
      _notifiedMessageIds[teacherId]?.contains(messageId) ?? false;

  void markMessageNotified(String teacherId, String messageId) {
    _notifiedMessageIds[teacherId] ??= {};
    _notifiedMessageIds[teacherId]!.add(messageId);
  }

  /// Sends a teacher's chat message and persists it to Firestore.
  /// Because [_subscribeToChatMessages] is a live stream, both the teacher's
  /// device and the admin's device will see the new message instantly.
  void sendChatMessage(ChatMessage message) {
    // Optimistic local update so the teacher sees their message immediately
    _chatMessages = [message, ..._chatMessages];
    notifyListeners();

    // Persist to Firestore — this is what makes it visible to the admin
    _db.collection('chat_messages').doc(message.id).set({
      'senderId': message.senderId,
      'senderName': message.senderName,
      'message': message.message,
      'isFromTeacher': message.isFromTeacher,
      'timestamp': FieldValue.serverTimestamp(),
      'isResolved': false,
      'adminResponse': null,
      'wasApproved': null,
    }).catchError((e) => debugPrint('Send chat message error: $e'));
  }

  /// Admin declines a teacher request.
  /// Writes [isResolved: true] to Firestore so it never resurfaces after restart.
  void respondToChat(String messageId, String response) {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _chatMessages[idx] = _chatMessages[idx].copyWith(
        isResolved: true,
        adminResponse: response,
        wasApproved: false,
      );
      notifyListeners();
    }

    // Persist resolution to Firestore
    _db.collection('chat_messages').doc(messageId).update({
      'isResolved': true,
      'adminResponse': response,
      'wasApproved': false,
      'resolvedAt': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint('Resolve chat message error: $e'));
  }

  // ── Teacher Request Auto-Approval ────────────────────────────────────────
  /// Parses the structured chatbot message, automatically adjusts the relevant
  /// part of the system (schedule, rooms, teacher load), then marks resolved.
  void approveTeacherRequest(ChatMessage message, String adminResponse) {
    final msg = message.message;
    if (msg.contains('ABSENCE REPORT')) {
      _handleAbsenceApproval(message.senderId, msg);
    } else if (msg.contains('CANCEL CLASS REQUEST')) {
      _handleCancelClassApproval(message.senderId, msg);
    } else if (msg.contains('SCHEDULE CHANGE REQUEST')) {
      _handleScheduleChangeApproval(message.senderId, msg);
    } else if (msg.contains('ADVANCE CLASS REQUEST')) {
      _handleAdvanceClassApproval(message.senderId, msg);
    } else if (msg.contains('ROOM REQUEST')) {
      _handleRoomRequestApproval(message.senderId, msg);
    }

    // Optimistic local update
    final idx = _chatMessages.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      _chatMessages[idx] = _chatMessages[idx].copyWith(
        isResolved: true,
        adminResponse: adminResponse.isEmpty ? 'Schedule automatically adjusted.' : adminResponse,
        wasApproved: true,
      );
    }
    notifyListeners();

    // Persist approval to Firestore so the teacher is notified in real-time
    // and the message never comes back after restart.
    _db.collection('chat_messages').doc(message.id).update({
      'isResolved': true,
      'adminResponse': adminResponse.isEmpty ? 'Schedule automatically adjusted.' : adminResponse,
      'wasApproved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint('Approve chat message error: $e'));
  }

  // ── Request parsing helpers ───────────────────────────────────────────────
  Map<String, String> _parseRequestMessage(String message) {
    final result = <String, String>{};
    for (final line in message.split('\n')) {
      if (line.contains('📚 Subject:')) result['subject'] = line.split('Subject:').last.trim();
      if (line.contains('📅 Date:') && !line.contains('New:') && !line.contains('Current:') && !line.contains('Original:') && !line.contains('Advance To:')) {
        result['date'] = line.split('Date:').last.split('  ').first.trim();
      }
      if (line.contains('📅 Current:')) result['currentDate'] = line.split('Current:').last.trim();
      if (line.contains('📅 New:')) {
        result['newDate'] = line.split('New:').last.split('  ').first.trim();
        final tMatch = RegExp(r'⏰\s*(\d+:\d+\s*[AP]M)').firstMatch(line);
        if (tMatch != null) result['newTime'] = tMatch.group(1) ?? '';
      }
      if (line.contains('📅 Original:')) result['originalDate'] = line.split('Original:').last.trim();
      if (line.contains('📅 Advance To:')) {
        result['advDate'] = line.split('Advance To:').last.split('  ').first.trim();
        final tMatch = RegExp(r'⏰\s*(\d+:\d+\s*[AP]M)').firstMatch(line);
        if (tMatch != null) result['advTime'] = tMatch.group(1) ?? '';
      }
      if (line.contains('🚪 Room:')) result['room'] = line.split('Room:').last.trim();
    }
    return result;
  }

  String _extractDay(String dateStr) => dateStr.split(',').first.trim();
  String _extractSubjectCode(String subjectLine) =>
      subjectLine.split(RegExp(r'\s*[–\-]\s*')).first.trim();

  void _handleAbsenceApproval(String teacherId, String message) {
    final p = _parseRequestMessage(message);
    final day = _extractDay(p['date'] ?? '');
    if (day.isEmpty) return;
    // Mark all entries for that teacher+day as cancelled (shown in dashboard)
    for (final e in _scheduleEntries) {
      if (e.teacher.id == teacherId && e.day == day) {
        _cancelledEntryIds.add(e.id);
        _db.collection('cancelled_classes').doc(e.id).set({
          'entryId': e.id,
          'teacherId': teacherId,
          'day': day,
          'reason': 'absent',
          'cancelledAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    }
    _teacherRequestStatuses[teacherId] = 'Absent';
    _db.collection('teacher_request_statuses').doc(teacherId).set({
      'status': 'Absent',
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
    _detectConflicts();
    debugPrint('Absence approved: marked entries on \$day as absent for teacher \$teacherId');
  }

  void _handleCancelClassApproval(String teacherId, String message) {
    final p = _parseRequestMessage(message);
    final day = _extractDay(p['date'] ?? '');
    final code = _extractSubjectCode(p['subject'] ?? '');
    if (day.isEmpty) return;
    // Mark matching entries as cancelled — keep them in schedule for dashboard display
    for (final e in _scheduleEntries) {
      final matchTeacher = e.teacher.id == teacherId;
      final matchDay = e.day == day;
      final matchSubject = code.isEmpty || e.subject.code.startsWith(code);
      if (matchTeacher && matchDay && matchSubject) {
        _cancelledEntryIds.add(e.id);
        _db.collection('cancelled_classes').doc(e.id).set({
          'entryId': e.id,
          'teacherId': teacherId,
          'day': day,
          'subjectCode': code,
          'reason': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    }
    _teacherRequestStatuses[teacherId] = 'Class Cancelled';
    _db.collection('teacher_request_statuses').doc(teacherId).set({
      'status': 'Class Cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
    _detectConflicts();
    debugPrint('Cancel class approved: marked \$day (\$code) as cancelled for \$teacherId');
  }

  void _handleScheduleChangeApproval(String teacherId, String message) {
    final p = _parseRequestMessage(message);
    final currentDay = _extractDay(p['currentDate'] ?? '');
    final newDay = _extractDay(p['newDate'] ?? '');
    final code = _extractSubjectCode(p['subject'] ?? '');
    if (currentDay.isEmpty || newDay.isEmpty) return;
    for (int i = 0; i < _scheduleEntries.length; i++) {
      final e = _scheduleEntries[i];
      if (e.teacher.id == teacherId && e.day == currentDay &&
          (code.isEmpty || e.subject.code.startsWith(code))) {
        // Conflict check before applying the day change
        final wouldConflict = _scheduleEntries.any((other) =>
        other.id != e.id &&
            other.day == newDay &&
            _slotsOverlap(e.timeStart, e.timeEnd, other.timeStart, other.timeEnd) &&
            (other.teacher.id == teacherId || other.room.id == e.room.id));
        if (!wouldConflict) {
          _scheduleEntries[i] = e.copyWith(day: newDay, updatedAt: DateTime.now());
          _saveScheduleToFirestore(_scheduleEntries[i]);
        }
      }
    }
    _teacherRequestStatuses[teacherId] = 'Schedule Changed';
    _db.collection('teacher_request_statuses').doc(teacherId).set({
      'status': 'Schedule Changed',
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
    _detectConflicts();
    debugPrint('Schedule change approved: moved entries from \$currentDay → \$newDay for \$teacherId');
  }

  void _handleAdvanceClassApproval(String teacherId, String message) {
    final p = _parseRequestMessage(message);
    final originalDay = _extractDay(p['originalDate'] ?? '');
    final newDay = _extractDay(p['advDate'] ?? '');
    final code = _extractSubjectCode(p['subject'] ?? '');
    if (originalDay.isEmpty || newDay.isEmpty) return;
    for (int i = 0; i < _scheduleEntries.length; i++) {
      final e = _scheduleEntries[i];
      if (e.teacher.id == teacherId && e.day == originalDay &&
          (code.isEmpty || e.subject.code.startsWith(code))) {
        // Conflict check before applying the advance
        final wouldConflict = _scheduleEntries.any((other) =>
        other.id != e.id &&
            other.day == newDay &&
            _slotsOverlap(e.timeStart, e.timeEnd, other.timeStart, other.timeEnd) &&
            (other.teacher.id == teacherId || other.room.id == e.room.id));
        if (!wouldConflict) {
          _scheduleEntries[i] = e.copyWith(day: newDay, updatedAt: DateTime.now());
          _saveScheduleToFirestore(_scheduleEntries[i]);
        }
      }
    }
    _teacherRequestStatuses[teacherId] = 'Advance Scheduled';
    _db.collection('teacher_request_statuses').doc(teacherId).set({
      'status': 'Advance Scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
    _detectConflicts();
    debugPrint('Advance class approved: moved \$originalDay → \$newDay for \$teacherId');
  }

  void _handleRoomRequestApproval(String teacherId, String message) {
    final p = _parseRequestMessage(message);
    final roomName = p['room'] ?? '';
    if (roomName.isEmpty) return;
    final teacher = _teachers.cast<Teacher?>().firstWhere(
            (t) => t!.id == teacherId, orElse: () => null);
    final roomIdx = _rooms.indexWhere((r) =>
    r.name.toLowerCase().contains(roomName.toLowerCase()) ||
        roomName.toLowerCase().contains(r.name.toLowerCase()));
    if (roomIdx != -1) {
      _rooms[roomIdx] = _rooms[roomIdx].copyWith(
        status: RoomStatus.occupied,
        currentTeacher: teacher?.fullName ?? 'Teacher',
        currentSubject: p['subject'],
        eventNote: 'Reserved per teacher request',
      );
      _saveRoomToFirestore(_rooms[roomIdx]);
      debugPrint('Room request approved: ${_rooms[roomIdx].name} marked occupied');
    }
  }


  // ── Real-time listener: room overrides ───────────────────────────────────
  void _subscribeToRoomOverrides() {
    _overrideSubscription?.cancel();
    _overrideSubscription = _db.collection('room_overrides').snapshots().listen(
          (snap) {
        _roomOverrides = snap.docs
            .map((d) => RoomOverride.fromMap(d.id, d.data()))
            .toList();
        notifyListeners();
      },
      onError: (e) => debugPrint('Room overrides stream error: \$e'),
    );
  }

  // Add a room override, persist to Firestore, and notify affected teachers.
  Future<void> addRoomOverride(RoomOverride override) async {
    try {
      // Save to Firestore — real-time stream updates _roomOverrides automatically.
      // No optimistic local update here to prevent duplicates.
      final ref = await _db.collection('room_overrides').add(override.toMap());
      // Mark the room as event-blocked in Firestore + local state
      updateRoomStatus(override.roomId, RoomStatus.event, eventNote: override.reason);
      // Notify affected teachers with the Firestore-assigned ID
      _notifyAffectedTeachers(RoomOverride.fromMap(ref.id, override.toMap()));
    } catch (e) {
      debugPrint('addRoomOverride error: $e');
    }
  }

  // Delete a room override by ID.
  Future<void> deleteRoomOverride(String overrideId) async {
    _roomOverrides = _roomOverrides.where((o) => o.id != overrideId).toList();
    notifyListeners();
    await _db.collection('room_overrides').doc(overrideId).delete().catchError((_) {});
  }

  // Notify teachers affected by a room override.
  void _notifyAffectedTeachers(RoomOverride override) {
    // Collect days spanned by the override
    final days = <String>{};
    var cursor = DateTime(override.startDate.year, override.startDate.month, override.startDate.day);
    final last = DateTime(override.endDate.year, override.endDate.month, override.endDate.day);
    const dayNames = {1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday'};
    while (!cursor.isAfter(last)) {
      final name = dayNames[cursor.weekday];
      if (name != null) days.add(name);
      cursor = cursor.add(const Duration(days: 1));
    }

    // Find schedule entries that use this room on those days
    final affected = _scheduleEntries.where((e) =>
    e.room.id == override.roomId && days.contains(e.day)).toList();

    // Group by teacher and send one notification per teacher
    final notified = <String>{};
    for (final entry in affected) {
      final teacherId = entry.teacher.id;
      if (notified.contains(teacherId)) continue;
      notified.add(teacherId);

      final msgId = 'sys_${DateTime.now().millisecondsSinceEpoch}_$teacherId';
      final startStr = _fmtDate(override.startDate);
      final endStr = _fmtDate(override.endDate);
      final subjectCode = entry.subject.code;
      final dayName = entry.day;
      final roomName = override.roomName;
      final reason = override.reason;
      final msgText = '\u26a0\ufe0f ROOM OVERRIDE NOTICE\n\n'
          '\ud83d\udead Room: $roomName\n'
          '\ud83d\udcc5 Period: $startStr \u2013 $endStr\n'
          '\ud83d\udccb Reason: $reason\n\n'
          'Your class $subjectCode on $dayName is affected. '
          'Please contact the admin to reschedule or confirm a new room.';

      _db.collection('teacher_notifications').doc(msgId).set({
        'teacherId': teacherId,
        'senderId': 'system',
        'senderName': 'System',
        'message': msgText,
        'isFromTeacher': false,
        'timestamp': FieldValue.serverTimestamp(),
        'isResolved': false,
        'overrideId': override.id,
      }).catchError((_) {});
    }
    if (notified.isNotEmpty) {
      debugPrint('Override notification sent to ${notified.length} teacher(s)');
    }
  }

  String _fmtDate(DateTime dt) {
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  // Get overrides for a specific room.
  List<RoomOverride> getRoomOverrides(String roomId) =>
      _roomOverrides.where((o) => o.roomId == roomId).toList();


  // ── Manual refresh — re-fetches all Firestore collections ───────────────
  Future<void> refreshAllData() async {
    await Future.wait([
      _loadSubjectsFromFirestore(),
      _loadRoomsFromFirestore(),
      _loadSectionsFromFirestore(),
    ]);
    await _loadTeachersFromFirestore();
    _resolveTeacherSubjects();
    _detectConflicts();
    notifyListeners();
  }

  // ── Auto-Scheduler ───────────────────────────────────────────────────────
  /// Only removes and re-assigns entries that are part of a conflict.
  /// Non-conflicting schedules are left untouched.
  Future<int> runAutoScheduler() async {
    await Future.delayed(const Duration(seconds: 3));

    // ── Step 1: Collect all entry IDs that are in a conflict ──────────────
    final conflictEntryIds = <String>{};
    for (final c in _conflicts) {
      if (!c.isResolved) {
        conflictEntryIds.add(c.conflictingEntry1.id);
        conflictEntryIds.add(c.conflictingEntry2.id);
      }
    }

    // If no conflicts, nothing to fix — return 0 immediately
    if (conflictEntryIds.isEmpty) {
      notifyListeners();
      return 0;
    }

    // ── Step 2: Remove conflicting entries from memory + Firestore ─────────
    final toReschedule = _scheduleEntries
        .where((e) => conflictEntryIds.contains(e.id))
        .toList();

    for (final e in toReschedule) {
      _scheduleEntries.removeWhere((s) => s.id == e.id);
      _db.collection('schedules').doc(e.id).delete().catchError((_) {});
    }

    // ── Step 3: Re-assign each affected entry to a conflict-free slot ──────
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday'];
    final timeSlots = [
      ['07:30','09:00'],['09:00','10:30'],['10:30','12:00'],
      ['13:00','14:30'],['14:30','16:00'],['16:00','17:30'],
    ];
    int generated = 0;

    for (final original in toReschedule) {
      // Prefer the original teacher; fall back to any compatible one
      final candidates = [
        original.teacher,
        ..._teachers.where((t) =>
        t.id != original.teacher.id &&
            t.status == TeacherStatus.active &&
            t.expertise.any((e) => original.subject.requiredExpertise.contains(e))),
      ];

      bool placed = false;
      for (final teacher in candidates) {
        if (placed) break;
        // Prefer the original room; fall back to any compatible one
        final rooms = [
          original.room,
          ..._rooms.where((r) =>
          r.id != original.room.id &&
              original.subject.matchesRoom(r.type) &&
              r.capacity >= original.subject.minRoomCapacity),
        ];
        for (final room in rooms) {
          if (placed) break;
          for (final day in days) {
            if (!teacher.availableDays.contains(day)) continue;
            if (placed) break;
            for (final slot in timeSlots) {
              // Slot is free if neither this teacher nor this room is taken
              final taken = _scheduleEntries.any((e) =>
              e.day == day &&
                  _slotsOverlap(e.timeStart, e.timeEnd, slot[0], slot[1]) &&
                  (e.teacher.id == teacher.id || e.room.id == room.id));
              if (!taken) {
                final entry = ScheduleEntry(
                  id: 'auto_${DateTime.now().millisecondsSinceEpoch}_$generated',
                  subject: original.subject,
                  teacher: teacher,
                  room: room,
                  section: original.section,
                  day: day,
                  timeStart: slot[0],
                  timeEnd: slot[1],
                  semester: original.semester,
                  academicYear: original.academicYear,
                  hasConflict: false,
                  createdAt: DateTime.now(),
                );
                _scheduleEntries.add(entry);
                _saveScheduleToFirestore(entry);
                generated++;
                placed = true;
                break;
              }
            }
          }
        }
      }
    }

    _detectConflicts();
    notifyListeners();
    return generated;
  }

  /// Checks if two time ranges (HH:mm strings) overlap.
  bool _slotsOverlap(String s1, String e1, String s2, String e2) {
    final start1 = _toMin(s1), end1 = _toMin(e1);
    final start2 = _toMin(s2), end2 = _toMin(e2);
    return start1 < end2 && start2 < end1;
  }
}