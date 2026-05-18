import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schoolapp/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Priority;
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_core/firebase_core.dart';


// Models
import 'models/assignment_model.dart';

import 'models/classroom_model.dart';

// Services
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/study_timer_service.dart';
import 'services/recommendation_service.dart';
import 'services/dashboard_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import '../screens/study_timer_screen.dart';
import 'screens/smart_recommendations_screen.dart';
import 'screens/study_insight_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}


enum UserRole { Student, Teacher}

//1. Enums for subjects and teacher
enum SubjectName {
  English,
  Mathematics,
  Physics,
  Chemistry,
  Nepali,
  ComputerOrganiztoinAndArchitecture,
  OperatingSystem,
  JavaProgramming,
  WebAndMobileApplicationDevelopment,
}

enum TeacherName {
  MrManojSapkota,
  MrSushatAdhikari,
  MrMachaKaji,
  MrSurendraKhadka,
  MrPramondAcharya,
  MsSantoshiThokar,
  MsRejaThapa,
  MsMalikaJoshi,
  MsGeetaKhatri,
}

//2. Dynamic lists for  subjects and teachers
List<String> dynamicSubjects = [];
List<String> dynamicTeachers = [];

  class ClassroomUser {
    String id;
    String name;
    String email;
    UserRole role;

    ClassroomUser ({
      required this.id,
      required this.name,
      required this.email,
      required this.role,
    });

    Map<String, dynamic> toJson() => {
      'id' : id,
      'name' : name,
      'email' : email,
      'role' : role.index,
    };

    factory ClassroomUser.fromJson(Map<String, dynamic> json) {
      return ClassroomUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: UserRole.values[json['role']],
      );
    }
  }


  class Classroom {
    String id;
    String name;
    String subject;
    String section;
    ClassroomUser teacher;
    List<ClassroomUser> students;
    String inviteCode;
    DateTime createdAt;

    Classroom ({
      required this.id,
      required this.name,
      required this.subject,
      required this.section,
      required this.teacher,
      required this.students,
      required this.inviteCode,
      required this.createdAt,
    });

    Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'subject': subject,
      'section' : section,
      'teacher' : teacher.toJson(),
      'students' : students.map((s) => s.toJson()).toList(),
      'inviteCode' : inviteCode,
      'createdAt' : createdAt.toIso8601String(),
    };

    factory Classroom.fromJson(Map<String, dynamic> json) {
      return Classroom(
        id: json['id'],
        name: json['name'],
        subject: json['subject'],
        section: json['section'],
        teacher: ClassroomUser.fromJson(json['teacher']),
        students: (json['students'] as List).map((s) => ClassroomUser.fromJson(s)).toList(),
        inviteCode: json['inviteCode'],
        createdAt: DateTime.parse(json['createdAt']),
      );
    }
  }

  class ClassroomAssignment {
    String id;
    String classroomId;
    String title;
    String description;
    List<String> attachments;
    DateTime dueDate;
    int points;
    List<StudentSubmission> submissions;

    ClassroomAssignment ({
      required this.id,
      required this.classroomId,
      required this.title,
      required this.description,
      required this.attachments,
      required this.dueDate,
      required this.points,
      required this.submissions,
    });

    Map<String, dynamic> toJson() => {
      'id': id,
      'classroomId': classroomId,
      'title': title,
      'description': description,
      'attachments': attachments,
      'dueDate': dueDate.toIso8601String(),
      'points': points,
      'submissions': submissions.map((s) => s.toJson()).toList(),
    };


    factory ClassroomAssignment.fromJson(Map<String, dynamic> json) {
        return ClassroomAssignment(
          id: json['id'],
          classroomId: json['classroomId'],
          title: json['title'],
          description: json['description'],
          attachments: List<String>.from(json['attachments']),
          dueDate: DateTime.parse(json['dueDate']),
          points: json['points'],
          submissions: (json['submissions'] as List).map((s) => StudentSubmission.fromJson(s)).toList(),
        );
    }
  }

  class StudentSubmission {
    String id;
    String studentId;
    String assignmentId;
    String? textContent;
    List<String> attachments;
    DateTime submittedAt;
    double? grade;
    String? feedback;

    StudentSubmission ({
      required this.id,
      required this.studentId,
      required this.assignmentId,
      required this.attachments,
      required this.submittedAt,
      this.textContent,
      this.grade,
      this.feedback,
    });

    Map<String, dynamic> toJson() => {
      'id' : id,
      'studentId' : studentId,
      'assignmentId': assignmentId,
      'textContent' : textContent,
      'attachments' : attachments,
      'submittedAt' : submittedAt.toIso8601String(),
      'grade' : grade,
      'feedback' : feedback,
    };

    factory StudentSubmission.fromJson(Map<String, dynamic> json) {
      return StudentSubmission (
        id: json['id'],
        studentId: json['studentId'],
        assignmentId: json['assignmentId'],
        textContent: json['textContent'],
        attachments: List<String>.from(json['attachments']),
        submittedAt: DateTime.parse(json['submittedAt']),
        grade: json['grade'],
        feedback: json['feedback'],
      );
    }
  }




class ClassroomService {
    static final ClassroomService _instance = ClassroomService._internal();
    factory ClassroomService() => _instance;
    ClassroomService._internal();

    List<Classroom> _classrooms = [];
    List<ClassroomAssignment> _classroomAssignments = [];

    //This part managed the classroom/ classroom managemnet
    Future<Classroom> createClassroom(String name, String subject, String section, ClassroomUser teacher) async {
      final classroom = Classroom (
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        subject: subject,
        section: section,
        teacher: teacher,
        students: [],
        inviteCode: _generateInviteCode(),
        createdAt: DateTime.now(),
      );

      _classrooms.add(classroom);
      await _saveClassrooms();
      return classroom;
    }

    Future<bool> joinClassroom(String inviteCode, ClassroomUser student) async {
      try {
        final classroom = _classrooms.firstWhere((c) => c.inviteCode == inviteCode);
        if (classroom.students.any((s) => s.id == student.id)) {
          return false;
        }

        classroom.students.add(student);
        await _saveClassrooms();
        return true;
      } catch (e) {
        return false;
      }
    }


    //Assignment Management
  Future<ClassroomAssignment> createClassroomAssignment ({
      required String classroomId,
      required String title,
      required String description,
      required DateTime dueDate,
    required int points,
    List<String> attachments = const [],
}) async {
      final assignment = ClassroomAssignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        classroomId: classroomId,
        title: title,
        description: description,
        attachments: attachments,
        dueDate: dueDate,
        points: points,
        submissions: [],
      );

      _classroomAssignments.add(assignment);
      await _saveClassroomAssignments();
      return assignment;
  }

  Future<StudentSubmission> submitAssignment ({
      required String assignmentId,
      required String studentId,
    String? textContent,
    List<String> attachments = const [],
})  async {
      final submission = StudentSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        assignmentId: assignmentId,
        textContent: textContent,
        attachments: attachments,
        submittedAt: DateTime.now(),
      );

      final assignment = _classroomAssignments.firstWhere((a) => a.id == assignmentId);
      assignment.submissions.add(submission);

      await _saveClassroomAssignments();
      return submission;
  }

  //Grade submission
  Future<void> gradeSubmission ({
      required String assignmentId,
    required String studentId,
    required double grade,
    String? feedback,
}) async {
      final assignment = _classroomAssignments.firstWhere((a) => a.id == assignmentId);
      final submission = assignment.submissions.firstWhere((s) => s.studentId == studentId);

      submission.grade = grade;
      submission.feedback = feedback;
      await _saveClassroomAssignments();
  }

    String _generateInviteCode() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    }

    //Storage methods
Future<void> _saveClassrooms() async {
      final prefs = await SharedPreferences.getInstance();
      final data = _classrooms.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('classrooms', data);
}


Future<void> _saveClassroomAssignments() async {
      final prefs = await SharedPreferences.getInstance();
      final data = _classroomAssignments.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('classroom_assignments', data);
}


Future<void> loadClassrooms() async {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('classrooms') ?? [];
      _classrooms = data.map((e) => Classroom.fromJson(jsonDecode(e))).toList();
}


Future<void> loadClassroomAssignments() async {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('classroom_assignments') ?? [];
      _classroomAssignments = data.map((e) => ClassroomAssignment.fromJson(jsonDecode(e))).toList();
}

//Getters
List<Classroom> get classrooms => _classrooms;
List<ClassroomAssignment> get classroomAssignments => _classroomAssignments;
List<ClassroomAssignment> getAssignmentsForClassroom(String id) {
  return _classroomAssignments.where((a) => a.classroomId == id).toList();
}
List<Classroom> getClassroomsForUser(String userId) {
  return _classrooms.where((c) => c.teacher.id == userId || c.students.any((s) => s.id == userId)).toList();
}
}

//3. For Notifications and Reminders


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(

    android: androidSettings,
    //IOS/macos/linux/windows left
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("notification tapped: ${response.payload}");
      },
    );
  }


  static Future<void> scheduleAssignmentReminder(Assignment assignment) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'assignment_channel',
      'Assignment  Reminders',
      importance: Importance.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    //Reminder 1 day before deadline
    final remindertime = assignment.deadline.subtract(const Duration(days: 1));
    if (remindertime.isAfter(DateTime.now())) {
      await _notifications.show(
        id: assignment.hashCode,
        title: 'Assignment Reminder',
        body: '${assignment.title} is due on ${assignment.deadline.toLocal().toString().split(' ')[0]}',
        payload: 'reminder_${assignment.hashCode}',
        notificationDetails: details,
      );
    }

    await _notifications.show(
      id: assignment.hashCode + 1,
      title: 'ASSIGNMENT DUE TODAY!!!!!',
      body: '${assignment.title} is due today',
      notificationDetails: details,
    );

      //Reminder expierd notificaiton
    final expiredTime = assignment.deadline.add(const Duration(days: 1));
    await _notifications.show(
      id: assignment.hashCode + 2,
      title: 'Assignment Overdue!',
      body: '${assignment.title} was due yesterday',
      notificationDetails: details,
    );
  }

  static Future<void> cancelAssignmentsReminders(Assignment assignment) async {
    await _notifications.cancel(id: assignment.hashCode);
    await _notifications.cancel(id: assignment.hashCode + 1);
    await _notifications.cancel(id: assignment.hashCode + 2);
  }
}



//4. For Exporting and Importing of Data

class ExportService {
  static Future<void> exportToCSV(List<Assignment> assignments) async {
    final csvData = StringBuffer();
    csvData.writeln('Subject, Title, Description, Deadline, Status, Priority, Timespent');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/assignments_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here are my assignment export!',
      subject: 'Assignment Export',
    );

    for (var assignment in assignments) {
      csvData.writeln('${assignment.subject}, ${assignment.title}.'
          '${assignment.description}, ${assignment.deadline.toIso8601String()},'
          '${assignment.status}, ${assignment.priority}, ${assignment.timeSpent?.inMinutes ?? 0}'
      );
    }
  }

  static Future<List<Assignment>> importFromCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );


    if (result != null) {
      final file = File(result.files.single.path!);
      final csvData = await file.readAsString();
      return _parseCSVData(csvData);
    }
    return [];
  }


  static List<Assignment> _parseCSVData(String csvData) {
    final lines =  csvData.split('\n');
    final assignments = <Assignment>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = line.split(',');
      if (values.length >= 6) {
        assignments.add(Assignment(
          subject: values[0],
          title: values[1],
          description: values[2],
          deadline: DateTime.parse(values[3]),
          submitTo: '',
          status: AssignmentStatus.Todo,
          priority: Priority.values.firstWhere((p) => p.toString().contains(values[5]), orElse: () => Priority.Medium),
        ));
      }
    }
    return assignments;
  }
}


//5 Theme Serivce


class ThemeService with ChangeNotifier {

  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final ThemeData _lightTheme = ThemeData.light();
  static final ThemeData _darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
  );
}


//6. Helper function for subjects and Teachers

String prettifyEnumName(String name) {
  final withSpaces = name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}');
  return withSpaces[0].toUpperCase() + withSpaces.substring(1);
}


List<String> getAllSubjects() {
  return [
    ...SubjectName.values.map((e) => prettifyEnumName(e.name)),
    ...dynamicSubjects,
  ];
}


List<String> getAllTeachers() {
  return [
    ...TeacherName.values.map((e) => prettifyEnumName(e.name)),
    ...dynamicTeachers,
  ];
}


void addSubject(String subject) {
  if (!dynamicSubjects.contains(subject)) {
    dynamicSubjects.add(subject);
  }
}


void addTeacher(String teacher) {
  if (!dynamicTeachers.contains(teacher)) {
    dynamicTeachers.add(teacher);
  }
}


String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}

Color _getPriorityColor(Priority priority) {
  switch (priority) {
    case Priority.Low: return Colors.green;
    case Priority.Medium: return Colors.orange;
    case Priority.High: return Colors.red;
    case Priority.Urgent: return Colors.deepPurple;
  }
}


//7. Main Part with Theme Support

class MyApp extends StatefulWidget {
    const MyApp({super.key});

    @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {


    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider<StudyTimerService>(create: (_) => StudyTimerService()),
          ChangeNotifierProvider(create: (_) => ConnectivityService()),
          ChangeNotifierProvider(create: (_) => DashboardService()),
/*          ChangeNotifierProvider<UltimateGamificationService>(
            create: (context) => UltimateGamificationService(
              Provider.of<StudyTimerService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider<QuestionService>(
            create: (context) => QuestionService(
              Provider.of<UltimateGamificationService>(context, listen: false),
            ),
          ),*/
        ],

        child: Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              title: 'Assignment Manager',
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeService.isDarkMode ? ThemeMode.dark: ThemeMode.light,
              initialRoute: '/',
              routes: {
                '/': (context) => const AuthWrapper(),
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/home': (context) => AssignmentManager(
                  themeService: themeService,
                ),
              },
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      );
    }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return AssignmentManager(
            themeService: Provider.of<ThemeService>(context),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

//8. Core part of the Assingment manager

class AssignmentManager extends StatefulWidget {
  final ThemeService themeService;

  const AssignmentManager({super.key, required this.themeService});

  @override
  State<AssignmentManager> createState() => _AssignmentManagerState();
}

class _AssignmentManagerState extends State<AssignmentManager> {
  final List<Assignment> _assignments = [];
  final ClassroomService _classroomService = ClassroomService();

  final ClassroomUser _currentUser = ClassroomUser(
    id: 'user_001',
    name: 'Current User',
    email: 'user@school.com',
    role: UserRole.Teacher,
  );


  String _formatDateTime(DateTime dt) {
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }


  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _classroomService.loadClassrooms();
    _classroomService.loadClassroomAssignments();
   // NotificationService.initialize();
    widget.themeService.addListener(_onThemeChanged);
  }


  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('Assignments') ?? [];
    setState(() {
      _assignments.clear();
      _assignments.addAll(data.map((e) => Assignment.fromJson(jsonDecode(e))));
    });
  }

  Future<void> _saveAssignment() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _assignments.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('Assignments', data);
  }

  void _addOrEditAssignment({Assignment? assignment, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentForm(assignment: assignment),
      ),
    );

    if (result != null && result is Assignment) {
      setState(() {
        if (index != null) {
          _assignments[index] = result;
        } else {
          _assignments.add(result);
          NotificationService.scheduleAssignmentReminder(result);
        }
      });
      await _saveAssignment();
    }
  }

  void _removeAssignment(int index) async {
    setState(() {
      _assignments.removeAt(index);
    });
    await _saveAssignment();
  }


  void _showAssignmentDetail(Assignment assignment, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:  (context) => AssignmentDetail(
          assignment: assignment,
          onEdit: () => _addOrEditAssignment(assignment: assignment, index: index),
          onDelete: () {
            _removeAssignment(index);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }


  void _showDeleteConfirmation(Assignment assignment, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Assignment'),
            content: Text('Are you sure you want to delete "${assignment.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),

              TextButton(
              onPressed: () {
                  _removeAssignment(index);
                  Navigator.pop(context);
              },
                  child: const Text('Delete', style: TextStyle(color: Colors.red),
                  ),
              ),
            ],
          );
        }
    );
  }

  Future<void> _promptForImageAndComplete(Assignment assignment) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      final index = _assignments.indexOf(assignment);
      if (index != -1) {
        _assignments[index] = Assignment(
          subject: assignment.subject,
          title: assignment.title,
          description: assignment.description,
          deadline: assignment.deadline,
          submitTo: assignment.submitTo,
          status: AssignmentStatus.Completed,
          startDate: assignment.startDate,
          completionDate: DateTime.now(),
          imagePath: picked?.path,
          priority: assignment.priority,
          timeSpent: assignment.timeSpent,
          timerStartTime: assignment.timerStartTime,
        );
      }
    });
    await _saveAssignment();
  }

  void _createClassroom() async {
    final result = await showDialog(
      context: context,
      builder: (context) => CreateClassroomDialog(),
    );

    if (result != null && result is Map<String, String>) {
      final classroom = await _classroomService.createClassroom(
        result['name']!,
        result['subject']!,
        result['section']!,
        _currentUser,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Classroom created! Invite Code: ${classroom.inviteCode}'),
            duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'COPY',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: classroom.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invite code copie to clipboard!')),
              );
            },
          ),
        ),
      );
      setState(() {});
    }
  }

  void _joinClassroom() async {
    final inviteCode = await showDialog<String>(
      context: context,
      builder: (context) => JoinClassroomDialog(),
    );

    if (inviteCode != null && inviteCode.isNotEmpty) {
      final success = await _classroomService.joinClassroom(inviteCode, _currentUser);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to join classroom. Invalid code or already joined')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join Classroom. Invalid code or already joined.')),
        );
      }
    }
  }

  void _showClassroomList() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClassroomListPage(
          classroomService: _classroomService,
          currentUser: _currentUser,
        ),
      ),
    );
  }

  Widget _buildClassroomSection() {
    final userClassrooms = _classroomService.getClassroomsForUser(_currentUser.id);

    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Classrooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (userClassrooms.isEmpty)
                const Text('NO Classrooms yet. Create or join one!'),

              if (userClassrooms.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: userClassrooms.length,
                      itemBuilder: (context, index) {
                      final classroom = userClassrooms[index];
                      final isTeacher = classroom.teacher.id == _currentUser.id;
                      return Container(
    width: 200,
    margin: const EdgeInsets.only(right: 10),
    child:  Card(
    color: Colors.blue[50],
    child: ListTile(
    title: Text(classroom.name),
    subtitle: Text('${classroom.subject} ${classroom.section}'),
    trailing: isTeacher ? const Icon(Icons.school, color: Colors.orange)
    : const Icon(Icons.person, color: Colors.green),
    onTap: () {
      Navigator.push(
      context,
      MaterialPageRoute(
      builder: (context) => ClassroomDetailPage(
    classroom: classroom,
    classroomService: _classroomService,
    currentUser: _currentUser
                                  ),
                                ),
                              );
                            },
      onLongPress: isTeacher ? () async {
      await Clipboard.setData(ClipboardData(text: classroom.inviteCode));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite Code "${classroom.inviteCode}" copied!')),
      );
      } : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                  const SizedBox(height: 10),
    Row(
    children: [
      Expanded(
    child: ElevatedButton.icon(
    onPressed: _createClassroom,
    icon: const Icon(Icons.add),
    label: const Text('create Classroom'),
                        ),
                      ),
                      const SizedBox(width: 10),
                  Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _joinClassroom,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join Classroom'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }


  //9. Kanban Board with Drag and Drop

  Widget buildKanbanBoard() {
    Map<AssignmentStatus, List<Assignment>> statusMap = {
      AssignmentStatus.Todo: [],
      AssignmentStatus.InProgress: [],
      AssignmentStatus.Completed: [],
    };

    for (var a in _assignments) {
      statusMap[a.status]?.add(a);
    }

    final double KanbanHeight = (MediaQuery.of(context).size.height - kToolbarHeight - 100).clamp(200.0, double.infinity);

      return Container(
          height: MediaQuery.of(context).size.height - 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AssignmentStatus.values.map((status) {
                  final columnAssignments = statusMap[status] ?? [];
                  return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: DragTarget<Assignment>(
                        onWillAccept: (assignment) {
                          if (assignment == null) return false;
                          if (status == AssignmentStatus.Todo) {
                            return assignment.status == AssignmentStatus.InProgress;
                          }

                          if (status == AssignmentStatus.InProgress) {
                            return assignment.status == AssignmentStatus.Todo;
                          }

                          if (status == AssignmentStatus.Completed) {
                            return assignment.status == AssignmentStatus.InProgress;
                          }

                          return false;
                        },

                      onAccept: (assignment) {
                        setState(() {
                          final index = _assignments.indexOf(assignment);
                          if (index != -1) {
                            if (status == AssignmentStatus.Completed) {
                              _promptForImageAndComplete(assignment);
                            } else {
                              Assignment updatedAssignment = Assignment(
                                subject: assignment.subject,
                                title: assignment.title,
                                description: assignment.description,
                                deadline: assignment.deadline,
                                submitTo: assignment.submitTo,
                                status: status,
                                startDate: assignment.startDate,
                                completionDate: assignment.completionDate,
                                imagePath: assignment.imagePath,
                                priority: assignment.priority,
                                timeSpent: assignment.timeSpent,
                                timerStartTime: assignment.timerStartTime,
                              );

                              if (status == AssignmentStatus.InProgress && assignment.status == AssignmentStatus.Todo) {
                                updatedAssignment.startDate = DateTime.now();
                              }

                              if (status != AssignmentStatus.Completed && assignment.status == AssignmentStatus.Completed) {
                                updatedAssignment.completionDate = null;
                                updatedAssignment.imagePath = null;
                              }
                              _assignments[index] = updatedAssignment;
                              _saveAssignment();
                            }
                          }
                        });
                      },


                builder: (context, candidateDate, rejectionData) => Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          status.toString().split('.').last.replaceAllMapped(
                            RegExp(r'([A-Z])'),
                                (m) => '${m[1]}',
                          ).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: status == AssignmentStatus.Todo ? Colors.orange :
                            status == AssignmentStatus.InProgress ? Colors.blue :
                            Colors.green,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (candidateDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Drop Here",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: statusMap[status]!.length,
                            itemBuilder: (context, index) {
                              final assignment = statusMap[status]![index];

                              return Draggable<Assignment>(
                                data: assignment,
                                feedback: SizedBox(
                                  width: 240,
                                  child: Card(
                                    child: ListTile(
                                      title: Text(
                                        assignment.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87, // Fixed: Removed Theme.of(context)
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        assignment.subject,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54, // Fixed: Removed Theme.of(context)
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),

                                child: GestureDetector(
                                  onLongPress: () => _showDeleteConfirmation(assignment, _assignments.indexOf(assignment)),
                                child: ListTile(
                                  title: Text(
                                    assignment.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${assignment.subject} . Due: ${_formatDateTime(assignment.deadline)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: assignment.status == AssignmentStatus.Completed && assignment.imagePath != null ? Image.file(
                                    File(assignment.imagePath!),
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                  )
                                      : null,
                                  onTap: () => _showAssignmentDetail(
                                    assignment,
                                    _assignments.indexOf(assignment),
                                  ),
                                ),
                                ),
                              );
                            },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Manager'),
        actions: [
          IconButton(
            icon:const Icon(Icons.timer),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyTimerScreen(),
                ),
              );
            },
            tooltip: 'Focus Timer',
          ),
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: _showClassroomList,
            tooltip: 'Classrooms',
          ),
          //Buttons for Dashboard
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    assignments: _assignments,
                    onAssignmentTap: (a, idx) => _showAssignmentDetail(a, idx),
                    onAssignmentLongPress: _showDeleteConfirmation,
                  ),
                ),
              );
            },
          ),

          //Button for Calendar
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarPage(assignments: _assignments),
                ),
              );
            },
          ),

          //Button for Anayltics
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyticsPage(assignments: _assignments),
                ),
              );
            },
          ),

          //Button for Export/Import
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () => _showExportMenu(context),
          ),

          //Button for Theme Toggeling
          IconButton(
            icon: Icon(widget.themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.themeService.toggleTheme();
            },
          ),


          //Button fro dashboard
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(
                    assignments: _assignments,
                    onAssignmentTap: _showAssignmentDetail,
                  ),
                ),
              );
            },
            tooltip: 'Dashboard',
          ),


          //Button for study insgihts'
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed:() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyInsightScreen(
                    assignments: _assignments,
                    studySession: [],
                  ),
                ),
              );
            },
            tooltip: 'Study Insights',
          ),

/*
          //Button for the gamification screen
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GamificationScreen()),
              );
            },
            tooltip: 'Achievements',
          ),


          //button for achiv
            IconButton(
              icon: const Icon(Icons.games),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HubScreen()),
                );
              },
              tooltip: 'Gamification Tab',
            ),
*/

          //Button for question bank
          /*IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
              );
            },
            tooltip: 'Question Bank',
          ),*/
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildClassroomSection(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _addOrEditAssignment(),
              child: const Text('Add Assignment'),
            ),
            const SizedBox(height: 20),
            Expanded(child: buildKanbanBoard()),
          ],
        ),
      ),
    );
  }



  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export to CSV'),
            onTap: () {
              Navigator.pop(context);
              ExportService.exportToCSV(_assignments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import from CSV'),
            onTap: () async {
              Navigator.pop(context);
              final imported = await ExportService.importFromCSV();
              if (imported.isNotEmpty) {
                setState(() {
                  _assignments.addAll(imported);
                });
                await _saveAssignment();
              }
            },
          ),
        ],
      ),
    );
  }
}


class CreateClassroomDialog extends StatefulWidget {
    @override
  State<CreateClassroomDialog> createState() => _CreateClassroomDialogState();
}

class _CreateClassroomDialogState extends State<CreateClassroomDialog> {
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Classroom'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Class Name'),
          ),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          TextField(
            controller: _sectionController,
            decoration: const InputDecoration(labelText: 'Section'),
          ),
        ],
      ),
      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        TextButton(onPressed: () {
          if (_nameController.text.isNotEmpty &&
              _subjectController.text.isNotEmpty &&
              _sectionController.text.isNotEmpty) {
            Navigator.pop(context, {
              'name': _nameController.text,
              'subject': _subjectController.text,
              'section': _sectionController.text,
            });
          }
        },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class JoinClassroomDialog extends StatefulWidget {
    @override
  State<JoinClassroomDialog> createState() => _JoinClassroomDialogState();
}

class _JoinClassroomDialogState extends State<JoinClassroomDialog> {
    final _inviteCodeController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: const Text('Join Classroom'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'e.g., ABC123',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: () {
              if (_inviteCodeController.text.isNotEmpty) {
                Navigator.pop(context, _inviteCodeController.text);
              }
            },
            child:  const Text('Join'),
          ),
        ],
      );
    }
  }


  //Clasroom List Page
class ClassroomListPage extends StatelessWidget {
    final ClassroomService classroomService;
    final ClassroomUser currentUser;

    const ClassroomListPage({
      super.key,
      required this.classroomService,
      required this.currentUser,
});

    @override
  Widget build(BuildContext context) {
      final userClassrooms = classroomService.getClassroomsForUser(currentUser.id);

      return Scaffold(
        appBar: AppBar(
          title: const Text('My Classrooms'),
        ),
        body: userClassrooms.isEmpty ? const Center(child: Text('No Classrooms yet. Create or join one!')) : ListView.builder(
          itemCount: userClassrooms.length,
          itemBuilder: (context, index) {
            final classroom = userClassrooms[index];
            final isTeacher = classroom.teacher.id == currentUser.id;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: classroom.teacher.id == currentUser.id ? const Icon(Icons.school, color: Colors.orange) : const Icon(Icons.person, color: Colors.green),
                title: Text(classroom.name),
                subtitle: Text('${classroom.subject} ${classroom.section}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${classroom.students.length} students'),
                    if (isTeacher) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy Invite Code',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: classroom.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invite Code "${classroom.inviteCode}" copied!')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                  onTap: () {
                  Navigator.push(
                      context,
                    MaterialPageRoute(
                        builder: (context) => ClassroomDetailPage(
                            classroom: classroom,
                            classroomService: classroomService,
                            currentUser: currentUser
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          )
        );
      }
    }


  //Classroom Detail Page
class ClassroomDetailPage extends StatefulWidget {
    final Classroom classroom;
    final ClassroomService classroomService;
    final ClassroomUser currentUser;

    const ClassroomDetailPage ({
      super.key,
      required this.classroom,
      required this.classroomService,
      required this.currentUser,
});

    @override
  State<ClassroomDetailPage> createState() => _ClassroomDetailPageState();
}

class _ClassroomDetailPageState extends State<ClassroomDetailPage> with WidgetsBindingObserver {
  late List<ClassroomAssignment> _assignments;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAssignments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAssignments();
    }
  }

  void _loadAssignments() {
    setState(() {
      _assignments = widget.classroomService.getAssignmentsForClassroom(widget.classroom.id);
    });
  }

  void _createClassroomAssignment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomAssignmentForm(
          classroom: widget.classroom,
          classroomService: widget.classroomService,
        ),
      ),
    );

    if (result == true) {
      _loadAssignments();
    }
  }

  void _gradeAssignment(ClassroomAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade: ${assignment.title}'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Points: ${assignment.points}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Divider(),
              ...assignment.submissions.map((submission) {
                // Find student name from classroom students list
                final student = widget.classroom.students.firstWhere(
                  (s) => s.id == submission.studentId,
                  orElse: () => ClassroomUser(
                    id: submission.studentId,
                    name: 'Unknown Student',
                    email: '',
                    role: UserRole.Student,
                  ),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submitted: ${submission.submittedAt.toLocal().toString().split('.')[0]}'),
                        if (submission.textContent != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Note: ${submission.textContent}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: submission.grade != null ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        submission.grade != null ? 'Grade: ${submission.grade}' : 'Not Graded',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () async {
                      // Close current dialog
                      Navigator.pop(context);

                      // Open grade input dialog
                      final grade = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: submission.grade?.toString() ?? ''
                          );
                          return AlertDialog(
                            title: Text('Grade ${student.name}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Assignment: ${assignment.title}'),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Grade',
                                    hintText: 'Enter grade (0-100)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, controller.text),
                                child: const Text('Save Grade'),
                              ),
                            ],
                          );
                        },
                      );

                      if (grade != null && grade.isNotEmpty) {
                        // Update locally
                        setState(() {
                          submission.grade = double.tryParse(grade);
                        });

                        // Save to service
                        await widget.classroomService.gradeSubmission(
                          assignmentId: assignment.id,
                          studentId: submission.studentId,
                          grade: double.tryParse(grade) ?? 0,
                          feedback: null,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Grade saved for ${student.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    final assignments = widget.classroomService.getAssignmentsForClassroom(widget.classroom.id);

    if (assignments.isEmpty) {
      return const Center(
        child: Text('No assignments yet. Create one!'),
      );
    }

    return ListView.builder(
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final isTeacher = widget.classroom.teacher.id == widget.currentUser.id;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(assignment.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Due: ${assignment.dueDate.toLocal().toString().split('.')[0]}'),
                Text('Points: ${assignment.points}'),
                Text('Submissions: ${assignment.submissions.length}'),
              ],
            ),
            trailing: isTeacher
                ? IconButton(
                    icon: const Icon(Icons.grade),
                    onPressed: () => _gradeAssignment(assignment),
                  )
                : null,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(assignment.title),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Description: ${assignment.description}'),
                        const SizedBox(height: 10),
                        Text('Due Date: ${assignment.dueDate.toLocal().toString().split('.')[0]}'),
                        Text('Points: ${assignment.points}'),
                        if (assignment.attachments.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Attachments:'),
                          ...assignment.attachments.map((file) => Text('• $file')),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.school, color: Colors.orange),
          title: Text(widget.classroom.teacher.name),
          subtitle: const Text('Teacher'),
        ),
        const Divider(),
        ...widget.classroom.students.map((student) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(student.name),
              subtitle: Text(student.email),
            )),
      ],
    );
  }

  Widget _buildGradesTab() {
    final assignments = widget.classroomService.getAssignmentsForClassroom(widget.classroom.id);

    if (assignments.isEmpty) {
      return const Center(
        child: Text('No assignments to grade'),
      );
    }

    return ListView.builder(
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(assignment.title),
            subtitle: Text(
                'Submissions: ${assignment.submissions.length}/${widget.classroom.students.length}'),
            trailing: IconButton(
              icon: const Icon(Icons.grade),
              onPressed: () => _gradeAssignment(assignment),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.classroom.teacher.id == widget.currentUser.id;

    return DefaultTabController(
      length: isTeacher ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.classroom.name),
          actions: [
            if (isTeacher)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy Invite Code',
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: widget.classroom.inviteCode));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Invite Code "${widget.classroom.inviteCode}" copied!')),
                    );
                  }
                },
              ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
              const Tab(icon: Icon(Icons.people), text: 'People'),
              if (isTeacher) const Tab(icon: Icon(Icons.grade), text: 'Grades'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAssignmentsTab(),
            _buildPeopleTab(),
            if (isTeacher) _buildGradesTab(),
          ],
        ),
        floatingActionButton: isTeacher
            ? FloatingActionButton(
                onPressed: _createClassroomAssignment,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}




//10. Assignment Form with Teachrs and Subjects

class AssignmentForm extends StatefulWidget {
  final Assignment? assignment;
  const AssignmentForm({super.key, this.assignment});

  @override
  State<AssignmentForm> createState() => _AssignmentFormState();


}
class _AssignmentFormState extends State<AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _submitToController;
  DateTime? _deadline;
  Priority _priority = Priority.Medium;


    String _formatDateTime(DateTime dt) {
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      final hour  = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
    }


  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.assignment?.subject ?? '');
    _titleController = TextEditingController(text: widget.assignment?.title ?? '');
    _descriptionController = TextEditingController(text: widget.assignment?.description ?? '');
    _submitToController = TextEditingController(text: widget.assignment?.submitTo ?? '');
    _deadline = widget.assignment?.deadline;
    _priority = widget.assignment?.priority ?? Priority.Medium;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _submitToController.dispose();
    super.dispose();
  }

   Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );

    if (pickedTime == null) return;

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );


    setState(() {
      _deadline = finalDateTime;
    });
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment == null ? 'Add Assignment' : 'Edit Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Subject Dropdown
              DropdownButtonFormField<String>(
                value: _subjectController.text.isNotEmpty ? _subjectController.text : null,
                items: getAllSubjects().map((subject) {
                  return DropdownMenuItem(value: subject, child: Text(subject));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _subjectController.text = val ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),

              // Add Subject Button
              TextButton(
                onPressed: () async {
                  final newSubject = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add Subject'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(labelText: 'Subject Name'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );

                  if (newSubject != null && newSubject.trim().isNotEmpty) {
                    setState(() {
                      addSubject(newSubject.trim());
                      _subjectController.text = newSubject.trim();
                    });
                  }
                },
                child: const Text('Add Subject'),
              ),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Assignment Title'),
                validator: (value) => value!.isEmpty ? 'Enter Title' : null,
              ),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description (Optional but recommended)'),
                maxLines: 3,
              ),

              // Teacher Dropdown
              DropdownButtonFormField<String>(
                value: _submitToController.text.isNotEmpty ? _submitToController.text : null,
                items: getAllTeachers().map((teacher) {
                  return DropdownMenuItem(value: teacher, child: Text(teacher));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _submitToController.text = val ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: 'Submit To Teacher'),
              ),

              // Add Teacher Button
              TextButton(
                onPressed: () async {
                  final newTeacher = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add teacher'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(labelText: 'Teacher Name'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );

                  if (newTeacher != null && newTeacher.trim().isNotEmpty) {
                    setState(() {
                      addTeacher(newTeacher.trim());
                      _submitToController.text = newTeacher.trim();
                    });
                  }
                },
                child: const Text('Add Teacher'),
              ),

              // Priority Dropdown
              DropdownButtonFormField<Priority>(
                value: _priority,
                items: Priority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority.toString().split('.').last),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _priority = val ?? Priority.Medium;
                  });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),

              const SizedBox(height: 10),

              // Deadline Picker
                ListTile(
                  title: Text(
                    _deadline == null ? 'Pick Deadline (Date + TIME)' : 'Deadline: ${_formatDateTime(_deadline!)}',
                  ),

                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDeadline,
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),


                if (_deadline == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4),
                    child: Text(
                      'Please select a date and time',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    ),


              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.assignment == null ? 'ADD' : 'UPDATE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate() && _deadline != null) {
      final assignment = Assignment(
        subject: _subjectController.text,
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _deadline!,
        submitTo: _submitToController.text,
        priority: _priority,
        status: widget.assignment?.status ?? AssignmentStatus.Todo,
        startDate: widget.assignment?.startDate,
        completionDate: widget.assignment?.completionDate,
        imagePath: widget.assignment?.imagePath,
        timeSpent: widget.assignment?.timeSpent,
        timerStartTime: widget.assignment?.timerStartTime,
      );
      Navigator.pop(context, assignment);
    } else if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline with date and time')),
      );
    }
  }
}

class ClassroomAssignmentForm extends StatefulWidget {
    final Classroom classroom;
    final ClassroomService classroomService;

    const ClassroomAssignmentForm({
      super.key,
      required this.classroom,
      required this.classroomService,
});

    @override
    State<ClassroomAssignmentForm> createState() => _ClassroomAssignmentFormState();
}

class _ClassroomAssignmentFormState extends State<ClassroomAssignmentForm> {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _pointsController = TextEditingController();
    DateTime? _dueDate;
    List<String> _attachments = [];

    @override
  void dispose() {
      _titleController.dispose();
      _descriptionController.dispose();
      _pointsController.dispose();
      super.dispose();
    }

    Future<void> _pickDeadline() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _dueDate ?? now.add(const Duration(days: 7)),
        firstDate: now,
        lastDate: DateTime(now.year + 1),
      );

      if (picked != null) {
        setState(() {
          _dueDate = picked;
        });
      }
    }

    Future<void> _pickFiles() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files.map((file) => file.name).toList());
        });
      }
    }

    Future<void> _save() async {
      if (_formKey.currentState!.validate() && _dueDate != null) {
        try {
          await widget.classroomService.createClassroomAssignment(
            classroomId: widget.classroom.id,
            title: _titleController.text,
            description: _descriptionController.text,
            dueDate: _dueDate!,
            points: int.tryParse(_pointsController.text) ?? 100,
            attachments: _attachments,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment created sucessfully!')),
          );
          Navigator.pop(context, true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating assignments: $e')),
          );
        }
      }
    }

    @override
      Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Classroom Assignment'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                  ),
              validator: (value) => value!.isEmpty ? 'Enter title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Enter points';
                final points = int.tryParse(value);
                if (points == null || points <= 0) return 'Enter valid points';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                  _dueDate == null ? ' Select Due Date' : 'Due Date: ${_dueDate!.toLocal().toString().split(' ')[0]}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDeadline,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            if (_dueDate == null)
              Padding(
            padding: const EdgeInsets.only(left: 16.0, top:  4),
          child: Text(
            'Please selecte a due date',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      const SizedBox(height: 16),
      if (_attachments.isNotEmpty) ...[
        const Text(
          'Attachments:',
      style: TextStyle(fontWeight: FontWeight.bold),
      ),
      ..._attachments.map((file) => ListTile(
      leading: const Icon(Icons.attach_file),
      title: Text(file),
      trailing: IconButton(
      icon: const Icon(Icons.close, size: 18),
      onPressed: () {
        setState(() {
          _attachments.remove(file);
        });
        },
      ),
      )
      ),
      const SizedBox(height: 16),
      ],
      ElevatedButton.icon(onPressed: _pickFiles,
          icon: const Icon(Icons.attach_file),
            label: const Text('Add Attachments'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[800],
        ),
),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                    ),
                  child: const Text(
                    'Create Assignments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
}

//11. Assignment Detail with Timer
class AssignmentDetail extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AssignmentDetail({
    super.key,
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
});

  @override
  State<AssignmentDetail> createState() => _AssignmentDetailState();
}

class _AssignmentDetailState extends State<AssignmentDetail> {
  late Assignment _assignment;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    if (_assignment.timerStartTime != null) {
      _startTimerUpdates();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_assignment.timerStartTime != null && mounted) {
      setState(() {

      });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    setState(() {
      _assignment.startTimer();
      _startTimerUpdates();
    });
  }

  void _stopTimer() {
    setState(() {
      _assignment.stopTimer();
      _timer?.cancel();
    });
  }


  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Assignment Picture'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: Hero(
                  tag: imagePath,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 67, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
              ),
            ),
            floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pop(context), child: const Icon(Icons.close), backgroundColor: Colors.black54,),
          ),
      )
    );
  }


  Widget _buildTimerControls() {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                    icon: Icon(_assignment.timerStartTime == null ? Icons.play_arrow : Icons.stop),
                  onPressed: () {
                      if (_assignment.timerStartTime == null) {
                        _startTimer();
                      } else {
                        _stopTimer();
                      }
                  },
                ),
                Text('Time Spent: ${_formatDuration(_assignment.timeSpent ?? Duration.zero)}'),
              ],
            ),
            if (_assignment.timerStartTime != null) ...[
              const SizedBox(height: 8),
              Text('Timer running .... Current Session: ${_formatDuration(DateTime.now().difference(_assignment.timerStartTime!))}',
              style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_assignment.title),
        actions: [
          IconButton(onPressed: widget.onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete)),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(title: const Text('Subject'), subtitle: Text(_assignment.subject)),
            ListTile(title: const Text('Title'), subtitle: Text(_assignment.title)),
            ListTile(title: const Text('Description'), subtitle: Text(_assignment.description)),
            ListTile(title: const Text('Deadline'), subtitle: Text(_assignment.deadline.toLocal().toString().split(' ')[0])),
            ListTile(title: const Text('Submiyt To'), subtitle: Text(_assignment.submitTo)),
            ListTile(title: const Text('Priority'), subtitle: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_assignment.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_assignment.priority.toString().split('.').last),
              ],
            ),
            ),
            if (_assignment.status == AssignmentStatus.InProgress) _buildTimerControls(),
            if (_assignment.status == AssignmentStatus.Completed) ...[

              if (_assignment.startDate != null)
                ListTile(
                  title: const Text('Started Date'),
                  subtitle: Text(_assignment.startDate!.toLocal().toString().split('.')[0]),
                ),

              if (_assignment.completionDate != null)
                ListTile(
                  title: const Text('Completed Date'),
                  subtitle: Text(_assignment.completionDate!.toLocal().toString().split('')[0]),
                ),

              if (_assignment.imagePath != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignment Image', style: TextStyle(fontWeight: FontWeight.bold),),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, _assignment.imagePath!),
                        child: Hero(
                          tag: _assignment.imagePath!,
                          child: Image.file(
                            File(_assignment.imagePath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the image to view full screen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

//12. Dashboard Page`1

class DashboardPage extends StatefulWidget {
  final List<Assignment> assignments;
  final void Function(Assignment, int) onAssignmentTap;
  final void Function(Assignment, int) onAssignmentLongPress;

  const DashboardPage({
    super.key,
    required this.assignments,
    required this.onAssignmentTap,
    required this.onAssignmentLongPress,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  AssignmentStatus? _statusFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final todoCount = widget.assignments.where((a) => a.status == AssignmentStatus.Todo).length;
    final inProgressCount = widget.assignments.where((a) => a.status == AssignmentStatus.InProgress).length;
    final completedCount = widget.assignments.where((a) => a.status == AssignmentStatus.Completed).length;
    final filtered = widget.assignments.where((a) {
      final matchesStatus = _statusFilter == null ||
          a.status == _statusFilter;
      final matchesSearch = _search.isEmpty ||
          a.title.toLowerCase().contains(_search.toLowerCase()) ||
          a.subject.toLowerCase().contains(_search.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();


    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusCountCard('To Do', todoCount, Colors.orange),
                _statusCountCard('In Progress', inProgressCount, Colors.blue),
                _statusCountCard('Completed', completedCount, Colors.green),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: [

                    PieChartSectionData(
                      value: todoCount.toDouble(),
                      color: Colors.orange,
                      title: 'To Do',
                    ),

                    PieChartSectionData(
                      value: inProgressCount.toDouble(),
                      color: Colors.blue,
                      title: 'In Progress',
                    ),

                    PieChartSectionData(
                      value: completedCount.toDouble(),
                      color: Colors.green,
                      title: 'Completed',
                    ),
                  ],

                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<AssignmentStatus?>(
                  value: _statusFilter,
                  hint: const Text('Filter by Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...AssignmentStatus.values.map(
                          (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val),
                ),
                const SizedBox(width:16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search by title or subject",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => _search = val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty ? const Center(child: Text('No assignmets found.')) : ListView.builder(
                itemCount:filtered.length,
                itemBuilder: (context, idx) {
                  final a = filtered[idx];
                  return Card(
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 2),
                          Text(
                            a.subject,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),

                      subtitle: Text(
                        a.status.toString().split('.').last,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                      trailing: a.status == AssignmentStatus.Completed && a.imagePath != null
                          ? Image.file(
                        File(a.imagePath!),
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      )
                          : null,
                      onTap: () => widget.onAssignmentTap(a, widget.assignments.indexOf(a)),
                      onLongPress: () => widget.onAssignmentLongPress(a,widget.assignments.indexOf(a)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCountCard(String label, int count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold),),
            Text('$count', style: TextStyle(
              fontSize: 30,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            ),
          ],
        ),
      ),
    );
  }
}


//13. Calendar Page Feature


  class CalendarPage extends StatefulWidget {
    final List<Assignment> assignments;

    const CalendarPage({super.key, required this.assignments});

    @override
    State<CalendarPage> createState() => _CalendarPageState();
  }

  class _CalendarPageState extends State<CalendarPage> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Map<DateTime, List<Assignment>> _assignmentsByDay;


    String _formatDateTime(DateTime dt) {
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
    }

  @override
  void initState() {
    super.initState();
    _assignmentsByDay = _getAssignmentsByDay();
  }

  Map<DateTime, List<Assignment>> _getAssignmentsByDay() {
    final Map<DateTime, List<Assignment>> assignmentsMap = {};

    for (var assignment in widget.assignments) {
      final day = DateTime(
        assignment.deadline.year,
        assignment.deadline.month,
        assignment.deadline.day,
      );

      if (!assignmentsMap.containsKey(day)) {
        assignmentsMap[day] = [];
      }
      assignmentsMap[day]!.add(assignment);
    }
    return assignmentsMap;
  }

  List<Assignment> _getAssignmentsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final assignments = _assignmentsByDay[normalizedDay] ?? [];
    return assignments;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsForSelectedDay = _selectedDay != null
        ? _getAssignmentsForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar View')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            eventLoader: (day) => _getAssignmentsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },


            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final assignmentsForDay = _getAssignmentsForDay(day);
                if (assignmentsForDay.isNotEmpty) {
                  return Positioned(
                    right: 65,
                    bottom: 40,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${assignmentsForDay.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },


              defaultBuilder: (context, day, focusedDay) {
                final assignmentsForDay = _getAssignmentsForDay(day);
                final isToday = isSameDay(day, DateTime.now());
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: assignmentsForDay.isNotEmpty
                        ? Colors.red.withOpacity(0.3)
                        : isToday
                            ? Colors.blue.withOpacity(0.3)
                            : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: assignmentsForDay.isNotEmpty
                          ? Colors.red
                          : isToday
                              ? Colors.blue
                              : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: assignmentsForDay.isNotEmpty
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: assignmentsForDay.isNotEmpty
                            ? Colors.red
                            : isToday
                                ? Colors.blue
                                : null,
                      ),
                    ),
                  ),
                );
              },


              selectedBuilder: (context, day, focusedDay) {
                final assignmentsForDay = _getAssignmentsForDay(day);
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: assignmentsForDay.isNotEmpty
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),


          const SizedBox(height: 16),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Assignments due on ${_selectedDay!.toLocal().toString().split(' ')[0]} (${assignmentsForSelectedDay.length} found)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: assignmentsForSelectedDay.isEmpty
                  ? const Center(
                      child: Text(
                        'No assignments due on this day',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: assignmentsForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final assignment = assignmentsForSelectedDay[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(assignment.priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              assignment.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Subject: ${assignment.subject}'),
                                const SizedBox(height: 2),
                                Text('Status: ${assignment.status.toString().split('.').last}'),
                                const SizedBox(height: 2),
                                Text('Priority: ${assignment.priority.toString().split('.').last}',
                                  style: TextStyle(color: _getPriorityColor(assignment.priority),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Select a date to view assignments',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//14. Analytics Page

class AnalyticsPage extends StatelessWidget {
  final List<Assignment> assignments;

  const AnalyticsPage({super.key, required this.assignments});

  Duration _calculateAverageCompletionTime() {
    final completedAssignments = assignments.where((a) => a.status == AssignmentStatus.Completed && a.startDate != null && a.completionDate != null).toList();

    if (completedAssignments.isEmpty) return Duration.zero;

    final totalDuration = completedAssignments.fold<Duration>(
        Duration.zero,
            (prev, a) => prev + a.completionDate!.difference(a.startDate!)
    );

    return Duration(
        microseconds: totalDuration.inMicroseconds ~/ completedAssignments.length
    );
  }

  String _findMostProductiveDay() {
    final completedByDay = <String, int>{};

    for (var assignment in assignments.where((a) => a.completionDate != null)) {
      final day = assignment.completionDate!.weekday;
      completedByDay[day.toString()] = (completedByDay[day.toString()] ?? 0) + 1;
    }

    if (completedByDay.isEmpty) return 'No Data';

    final mostProductive = completedByDay.entries.reduce((a,b) => a.value > b.value ? a:b);
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[int.parse(mostProductive.key) - 1];
  }


  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSubjectDistributionChart() {
    final subjectCounts = <String, int>{};
    for (var assignment in assignments) {
      subjectCounts[assignment.subject] = (subjectCounts[assignment.subject] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignments by Subject',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...subjectCounts.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / assignments.length,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final completedThisWeek = assignments.where((a) =>
    a.completionDate != null &&
        a.completionDate!.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;

    final averageCompletionTime = _calculateAverageCompletionTime();
    final mostProductiveDay = _findMostProductiveDay();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatCard('Completed This Week', '$completedThisWeek assignments'),
          _buildStatCard('Average Completion Time', '${averageCompletionTime.inHours}h ${averageCompletionTime.inMinutes.remainder(60)}m'),
          _buildStatCard('Most Productive Day', mostProductiveDay),
          _buildStatCard('Total Assignments', '${assignments.length}'),
          const SizedBox(height: 16),
          _buildSubjectDistributionChart(),
        ],
      ),
    );
  }
}




