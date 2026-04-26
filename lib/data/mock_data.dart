import '../models/teacher.dart';
import '../models/room.dart';
import '../models/subject.dart';
import '../models/schedule.dart';

class MockData {
  // ─── Sections — single source of truth for all section lists ─────────────────
  static List<String> get sections => [
    'BSCS 1-A', 'BSCS 1-B', 'BSCS 1-C',
    'BSCS 2-A', 'BSCS 2-B', 'BSCS 2-C',
    'BSCS 3-A', 'BSCS 3-B', 'BSCS 3-C',
    'BSCS 4-A', 'BSCS 4-B',
    'BSIT 1-A', 'BSIT 1-B',
    'BSIT 2-A', 'BSIT 2-B',
    'BSIT 3-A', 'BSIT 3-B',
    'BSIT 4-A', 'BSIT 4-B',
  ];

  // ─── Subjects ────────────────────────────────────────────────────────────────
  static List<Subject> get subjects => [
    // ── 1st Year – 1st Semester ──────────────────────────────────────────
    Subject(id:'s1',code:'CS101',name:'Introduction to Computing',description:'Fundamentals of computer science',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:30,yearLevel:'1st Year',semester:'1st Semester'),
    Subject(id:'s2',code:'CS102',name:'Computer Programming 1',description:'Introduction to programming using Python',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Programming','Computer Science'],requiresProjector:true,requiresComputers:true,minRoomCapacity:25,yearLevel:'1st Year',semester:'1st Semester'),
    Subject(id:'s3',code:'MATH101',name:'Calculus 1',description:'Limits, derivatives, and integrals',units:4,hours:4,type:SubjectType.lecture,department:'Mathematics',requiredExpertise:['Mathematics'],requiresProjector:false,requiresComputers:false,minRoomCapacity:40,yearLevel:'1st Year',semester:'1st Semester'),
    Subject(id:'s6',code:'ENG101',name:'Technical Writing',description:'Academic and professional writing',units:3,hours:3,type:SubjectType.lecture,department:'English',requiredExpertise:['English','Communication'],requiresProjector:false,requiresComputers:false,minRoomCapacity:40,yearLevel:'1st Year',semester:'1st Semester'),
    Subject(id:'s7',code:'IT101',name:'Information Technology Fundamentals',description:'Overview of IT concepts and systems',units:3,hours:3,type:SubjectType.lecture,department:'Information Technology',requiredExpertise:['Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:40,yearLevel:'1st Year',semester:'1st Semester'),
    Subject(id:'s8',code:'MATH102',name:'Discrete Mathematics',description:'Logic, sets, relations and combinatorics',units:3,hours:3,type:SubjectType.lecture,department:'Mathematics',requiredExpertise:['Mathematics'],requiresProjector:false,requiresComputers:false,minRoomCapacity:40,yearLevel:'1st Year',semester:'1st Semester'),
    // ── 1st Year – 2nd Semester ──────────────────────────────────────────
    Subject(id:'s9',code:'CS103',name:'Computer Programming 2',description:'Object-oriented programming using Java',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Programming','Computer Science'],requiresProjector:true,requiresComputers:true,minRoomCapacity:25,yearLevel:'1st Year',semester:'2nd Semester'),
    Subject(id:'s10',code:'MATH103',name:'Calculus 2',description:'Integral calculus and series',units:4,hours:4,type:SubjectType.lecture,department:'Mathematics',requiredExpertise:['Mathematics'],requiresProjector:false,requiresComputers:false,minRoomCapacity:40,yearLevel:'1st Year',semester:'2nd Semester'),
    Subject(id:'s11',code:'CS104',name:'Digital Logic Design',description:'Boolean algebra and logic circuits',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'1st Year',semester:'2nd Semester'),
    // ── 2nd Year – 1st Semester ──────────────────────────────────────────
    Subject(id:'s4',code:'CS201',name:'Data Structures and Algorithms',description:'Advanced data structures and algorithm design',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Programming','Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'2nd Year',semester:'1st Semester'),
    Subject(id:'s5',code:'CS202',name:'Database Management Systems',description:'Relational databases and SQL',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Database','Computer Science'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'2nd Year',semester:'1st Semester'),
    Subject(id:'s12',code:'CS203',name:'Object-Oriented Programming',description:'Advanced OOP concepts and design patterns',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Programming'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'2nd Year',semester:'1st Semester'),
    Subject(id:'s13',code:'IT201',name:'Web Development 1',description:'HTML, CSS and JavaScript fundamentals',units:3,hours:5,type:SubjectType.laboratory,department:'Information Technology',requiredExpertise:['Programming'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'2nd Year',semester:'1st Semester'),
    Subject(id:'s14',code:'MATH201',name:'Linear Algebra',description:'Vectors, matrices and linear transformations',units:3,hours:3,type:SubjectType.lecture,department:'Mathematics',requiredExpertise:['Mathematics'],requiresProjector:false,requiresComputers:false,minRoomCapacity:40,yearLevel:'2nd Year',semester:'1st Semester'),
    // ── 2nd Year – 2nd Semester ──────────────────────────────────────────
    Subject(id:'s15',code:'CS204',name:'Operating Systems',description:'Process management, memory and file systems',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'2nd Year',semester:'2nd Semester'),
    Subject(id:'s16',code:'CS205',name:'Computer Networks',description:'Network protocols and architecture',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Networking','Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'2nd Year',semester:'2nd Semester'),
    Subject(id:'s17',code:'IT202',name:'Web Development 2',description:'Backend development with PHP and MySQL',units:3,hours:5,type:SubjectType.laboratory,department:'Information Technology',requiredExpertise:['Programming','Database'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'2nd Year',semester:'2nd Semester'),
    // ── 3rd Year – 1st Semester ──────────────────────────────────────────
    Subject(id:'s18',code:'CS301',name:'Software Engineering',description:'Software development life cycle and project management',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Programming','Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'3rd Year',semester:'1st Semester'),
    Subject(id:'s19',code:'CS302',name:'Algorithm Analysis',description:'Complexity theory and advanced algorithms',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Programming','Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'3rd Year',semester:'1st Semester'),
    Subject(id:'s20',code:'CS303',name:'Artificial Intelligence',description:'Search algorithms, machine learning basics',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Computer Science','Programming'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'3rd Year',semester:'1st Semester'),
    Subject(id:'s21',code:'IT301',name:'Systems Analysis and Design',description:'System modeling and requirements engineering',units:3,hours:3,type:SubjectType.lecture,department:'Information Technology',requiredExpertise:['Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'3rd Year',semester:'1st Semester'),
    // ── 3rd Year – 2nd Semester ──────────────────────────────────────────
    Subject(id:'s22',code:'CS304',name:'Mobile Application Development',description:'Android and iOS app development',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Programming'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'3rd Year',semester:'2nd Semester'),
    Subject(id:'s23',code:'CS305',name:'Information Security',description:'Cybersecurity principles and cryptography',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Networking','Computer Science'],requiresProjector:true,requiresComputers:false,minRoomCapacity:35,yearLevel:'3rd Year',semester:'2nd Semester'),
    // ── 4th Year ─────────────────────────────────────────────────────────
    Subject(id:'s24',code:'CS401',name:'Capstone Project 1',description:'Research and system proposal',units:3,hours:3,type:SubjectType.lecture,department:'Computer Science',requiredExpertise:['Computer Science','Programming'],requiresProjector:true,requiresComputers:false,minRoomCapacity:30,yearLevel:'4th Year',semester:'1st Semester'),
    Subject(id:'s25',code:'CS402',name:'Capstone Project 2',description:'System development and implementation',units:3,hours:5,type:SubjectType.laboratory,department:'Computer Science',requiredExpertise:['Computer Science','Programming'],requiresProjector:true,requiresComputers:true,minRoomCapacity:30,yearLevel:'4th Year',semester:'2nd Semester'),
  ];

  // ─── Rooms — Floor+Letter naming (1A–4G) ────────────────────────────────────
  static List<Room> get rooms {
    final list = <Room>[];
    int id = 1;
    final floors = [1, 2, 3, 4];
    final letters = ['A','B','C','D','E','F','G'];

    for (final floor in floors) {
      for (final letter in letters) {
        final name = '$floor$letter';
        final isLab = letter == 'F' || letter == 'G'; // F & G are labs
        final isOccupied = (floor == 1 && letter == 'A') || (floor == 2 && letter == 'C');
        final isEvent = (floor == 1 && letter == 'G');
        final isMaintenance = (floor == 3 && letter == 'E');

        RoomStatus status;
        if (isOccupied) status = RoomStatus.occupied;
        else if (isEvent) status = RoomStatus.event;
        else if (isMaintenance) status = RoomStatus.maintenance;
        else status = RoomStatus.available;

        list.add(Room(
          id: 'r$id',
          name: name,
          floor: floor,
          capacity: isLab ? 30 : (letter == 'A' || letter == 'B' ? 50 : 40),
          type: isLab ? RoomType.laboratory : RoomType.lecture,
          hasProjector: true,
          hasAirConditioning: floor <= 2 || letter == 'A',
          hasComputers: isLab,
          status: status,
          currentSubject: isOccupied && floor == 1 && letter == 'A' ? 'CS101 - Intro to Computing' : isOccupied ? 'CS102 - Computer Programming 1' : null,
          currentTeacher: isOccupied && floor == 1 && letter == 'A' ? 'Dr. Maria Santos' : isOccupied ? 'Prof. Juan dela Cruz' : null,
          currentSection: isOccupied && floor == 1 && letter == 'A' ? 'BSCS 1-A' : isOccupied ? 'BSCS 1-B' : null,
          currentTimeStart: isOccupied ? '07:30' : null,
          currentTimeEnd: isOccupied ? '09:00' : null,
          eventNote: isEvent ? 'Faculty Meeting – 8:00 AM to 5:00 PM' : isMaintenance ? 'Under repair – AC unit replacement' : null,
        ));
        id++;
      }
    }
    return list;
  }

  // ─── Teachers ────────────────────────────────────────────────────────────────
  static List<Teacher> get teachers => [
    Teacher(id:'t1',firstName:'Maria',lastName:'Santos',email:'maria.santos@school.edu',employeeId:'EMP-001',department:'Computer Science',expertise:['Computer Science','Programming'],unitType:'Regular',maxUnits:21,currentUnits:18,status:TeacherStatus.active,availableDays:['Monday','Tuesday','Wednesday','Thursday','Friday'],availableTimeStart:'07:00',availableTimeEnd:'17:00',assignedSubjects:[],password:'teacher123',sections:['BSCS 1-A','BSCS 2-B'],yearLevels:['1st Year','2nd Year'],semester:'1st Semester'),
    Teacher(id:'t2',firstName:'Juan',lastName:'dela Cruz',email:'juan.delacruz@school.edu',employeeId:'EMP-002',department:'Computer Science',expertise:['Programming','Database','Computer Science'],unitType:'Regular',maxUnits:21,currentUnits:15,status:TeacherStatus.active,availableDays:['Monday','Wednesday','Friday'],availableTimeStart:'08:00',availableTimeEnd:'16:00',assignedSubjects:[],password:'teacher123',sections:['BSCS 1-B','BSCS 3-A'],yearLevels:['1st Year','3rd Year'],semester:'1st Semester'),
    Teacher(id:'t3',firstName:'Ana',lastName:'Reyes',email:'ana.reyes@school.edu',employeeId:'EMP-003',department:'Mathematics',expertise:['Mathematics'],unitType:'Regular',maxUnits:21,currentUnits:20,status:TeacherStatus.active,availableDays:['Tuesday','Thursday'],availableTimeStart:'07:00',availableTimeEnd:'18:00',assignedSubjects:[],password:'teacher123',sections:['BSCS 2-A'],yearLevels:['2nd Year'],semester:'1st Semester'),
    Teacher(id:'t4',firstName:'Roberto',lastName:'Garcia',email:'roberto.garcia@school.edu',employeeId:'EMP-004',department:'English',expertise:['English','Communication'],unitType:'Part-time',maxUnits:12,currentUnits:9,status:TeacherStatus.active,availableDays:['Monday','Tuesday','Wednesday'],availableTimeStart:'09:00',availableTimeEnd:'15:00',assignedSubjects:[],password:'teacher123',sections:['BSCS 1-C'],yearLevels:['1st Year'],semester:'1st Semester'),
    Teacher(id:'t5',firstName:'Liza',lastName:'Flores',email:'liza.flores@school.edu',employeeId:'EMP-005',department:'Computer Science',expertise:['Computer Science','Networking'],unitType:'Part-time',maxUnits:12,currentUnits:6,status:TeacherStatus.onLeave,availableDays:['Thursday','Friday'],availableTimeStart:'13:00',availableTimeEnd:'18:00',assignedSubjects:[],password:'teacher123',sections:['BSIT 1-A','BSIT 1-B'],yearLevels:['1st Year'],semester:'1st Semester'),
    Teacher(id:'t6',firstName:'Kasandra',lastName:'Calma',email:'kass@gmail.com',employeeId:'EMP-006',department:'Computer Science',expertise:['Programming'],unitType:'Regular',maxUnits:21,currentUnits:0,status:TeacherStatus.active,availableDays:['Monday','Tuesday','Wednesday','Thursday','Friday'],availableTimeStart:'07:00',availableTimeEnd:'18:00',assignedSubjects:[],password:'',sections:['BSCS 1-A','BSCS 1-B','BSCS 1-C'],yearLevels:['1st Year'],semester:'1st Semester'),
  ];

  // ─── Schedule Entries ─────────────────────────────────────────────────────────
  static List<ScheduleEntry> get scheduleEntries {
    final s = subjects; final t = teachers; final r = rooms;
    return [
      // t1 – Maria Santos
      ScheduleEntry(id:'sch1',subject:s[0],teacher:t[0],room:r[0],section:'BSCS 1-A',day:'Monday',timeStart:'07:30',timeEnd:'09:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:5))),
      ScheduleEntry(id:'sch4',subject:s[3],teacher:t[0],room:r[1],section:'BSCS 2-B',day:'Wednesday',timeStart:'13:00',timeEnd:'14:30',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:3))),
      ScheduleEntry(id:'sch7',subject:s[0],teacher:t[0],room:r[2],section:'BSCS 1-A',day:'Friday',timeStart:'07:30',timeEnd:'09:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:2))),
      // t2 – Juan dela Cruz
      ScheduleEntry(id:'sch2',subject:s[1],teacher:t[1],room:r[9],section:'BSCS 1-B',day:'Monday',timeStart:'09:00',timeEnd:'11:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:5))),
      ScheduleEntry(id:'sch5',subject:s[4],teacher:t[1],room:r[10],section:'BSCS 3-A',day:'Wednesday',timeStart:'13:00',timeEnd:'15:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:2))),
      ScheduleEntry(id:'sch8',subject:s[1],teacher:t[1],room:r[9],section:'BSCS 1-B',day:'Friday',timeStart:'09:00',timeEnd:'11:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      // t3 – Ana Reyes
      ScheduleEntry(id:'sch3',subject:s[2],teacher:t[2],room:r[2],section:'BSCS 2-A',day:'Tuesday',timeStart:'10:30',timeEnd:'12:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:4))),
      ScheduleEntry(id:'sch9',subject:s[2],teacher:t[2],room:r[3],section:'BSCS 2-A',day:'Thursday',timeStart:'10:30',timeEnd:'12:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:3))),
      // t4 – Roberto Garcia
      ScheduleEntry(id:'sch6',subject:s[5],teacher:t[3],room:r[3],section:'BSCS 1-C',day:'Thursday',timeStart:'08:00',timeEnd:'09:30',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      ScheduleEntry(id:'sch10',subject:s[5],teacher:t[3],room:r[4],section:'BSCS 1-C',day:'Tuesday',timeStart:'08:00',timeEnd:'09:30',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:2))),
      // t6 – Kasandra Calma
      ScheduleEntry(id:'sch11',subject:s[0],teacher:t[5],room:r[5],section:'BSCS 1-A',day:'Monday',timeStart:'07:30',timeEnd:'09:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      ScheduleEntry(id:'sch12',subject:s[1],teacher:t[5],room:r[11],section:'BSCS 1-B',day:'Tuesday',timeStart:'09:00',timeEnd:'11:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      ScheduleEntry(id:'sch13',subject:s[0],teacher:t[5],room:r[5],section:'BSCS 1-C',day:'Wednesday',timeStart:'07:30',timeEnd:'09:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      ScheduleEntry(id:'sch14',subject:s[1],teacher:t[5],room:r[11],section:'BSCS 1-A',day:'Thursday',timeStart:'09:00',timeEnd:'11:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
      ScheduleEntry(id:'sch15',subject:s[0],teacher:t[5],room:r[5],section:'BSCS 1-B',day:'Friday',timeStart:'07:30',timeEnd:'09:00',semester:'1st Semester',academicYear:'2024-2025',hasConflict:false,createdAt:DateTime.now().subtract(const Duration(days:1))),
    ];
  }

  static List<ScheduleConflict> get conflicts => [];

  static List<ChatMessage> get chatMessages => [
    ChatMessage(id:'msg1',senderId:'t1',senderName:'Dr. Maria Santos',message:'Good morning, I will be absent today due to a medical emergency. Please arrange for a substitute for my 7:30 AM class (CS101 – BSCS 1-A).',isFromTeacher:true,timestamp:DateTime.now().subtract(const Duration(hours:1)),isResolved:false),
    ChatMessage(id:'msg2',senderId:'t2',senderName:'Prof. Juan dela Cruz',message:'I need to reschedule my Wednesday 1:00 PM class (CS202) to Friday 3:00 PM due to a department seminar.',isFromTeacher:true,timestamp:DateTime.now().subtract(const Duration(minutes:30)),isResolved:true,adminResponse:'Approved. Schedule has been updated. Friday 3:00 PM – 5:00 PM in room 2F.'),
  ];
}