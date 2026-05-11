import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../models/study_insight_model.dart';
import '../models/study_session_model.dart';



class StudyInsightsService {
  List<Assignment> _assignments = [];
  List<StudySession> _studySessions = [];
  StudyInsightsService(this._assignments, this._studySessions);

  //calcualtes the overall completion rate acorrss all assignments
  double calculateOverallCompletionRate() {
    if (_assignments.isEmpty) return 0.0;
    final completed = _assignments.where((a) =>  a.status == AssignmentStatus.Completed).length;
    return (completed / _assignments.length) * 100;
  }


  //calculates the average study session duration in minutes
  double calculateOnTimeCompletionRate() {
      final completedAssignments = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.completionDate != null).toList();
      if (completedAssignments.isEmpty) return 0.0;

      final onTime = completedAssignments.where((a) => a.completionDate!.isBefore(a.deadline) || a.completionDate!.isAtSameMomentAs(a.deadline)).length;
      return (onTime / completedAssignments.length) * 100;
  }


//Calcuate the late completion precentage
double calculateLateCompletionRate() {
  final completedAssignments = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.completionDate != null).toList();

  if (completedAssignments.isEmpty) return 0.0;

  final late = completedAssignments.where((a) => a.completionDate!.isAfter(a.deadline)).length;
  return (late / completedAssignments.length) * 100;
}



//get average completion spped (hrs spent/assignemtn)
double calculateAverageCompletionSpeed() {
  final completedAssignments = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.startDate != null && a.completionDate != null).toList();
  if (completedAssignments.isEmpty) return 0.0;

  double totalHours = 0.0;
  for (var a in completedAssignments) {
    final hours = a.completionDate!.difference(a.startDate!).inHours;
    totalHours += hours;
  }
  return totalHours / completedAssignments.length;
}



//get productivity trend compared to last week
StudyTrend calculateProductivityTrend() {
  final now = DateTime.now();
  final thisWeekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final thisWeekCompleted = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.completionDate != null && a.completionDate!.isAfter(thisWeekStart)).length;
  final lastWeekCompleted = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.completionDate != null && a.completionDate!.isAfter(lastWeekStart) && a.completionDate!.isBefore(thisWeekStart)).length;
  

  if (lastWeekCompleted == 0) {
    if (thisWeekCompleted > 0 ) {
      return StudyTrend(
        direction: 'up',
        percentageChange: 100,
        message: 'Great improvement this week !',
      );
    }
    return StudyTrend(
      direction: 'stable',
      percentageChange: 100,
      message: 'start completing assignments to see ',
    );
  }

  final percentageChange = ((thisWeekCompleted - lastWeekCompleted) / lastWeekCompleted) * 100;

  if (percentageChange > 0) {
    return StudyTrend(
      direction: 'up',
      percentageChange: percentageChange,
      message: 'You completed ${percentageChange. toStringAsFixed(0)}% more assianmnets this weak !',
    );
  } else if (precentageChange < 0) {
    return StudyTrend(
      direction:'down',
    percentageChange: percentagechange.abs(),
    message: 'you completed  ${percentageChange.abs(). toStringAsFixed(0)}% fewer assignments this week',
    );
  } else {
    return StudyTrend(
      direction: 'stable', 
    percentageChange: 0,
    message: 'Consistent performance this week',
    );
  }
}



// Get subject performance breakdown
List<SubjectPerformance> calculateSubjectPerformance() {
  final Map<String, SubjectPerformance> performanceMap = {};


  for (var a in _assignments) {
    if (!performance.containsKey(a.subject)) {
      performance[a.subject] = SubjectPerformance(subject: a.subject);
    }

    final subject = performance[a.subject]!;
    subject.totalAssignments ++;

    if (a.status == AssignmentStatus.Completed) {
      subject.completedAssignments++;


      if (a.completionDate != null && a.completionDate!.isAfter(a.deadline)) {
        subject.lastCompletions++;
      }


      if (a.startDate != null && a.completionDate != null) {
        final hoursSpent = a.completionDate!.difference(a.startDate!).inHours;
        final currentTotal = subject.averageTimeSpentHours * (subject.completedAssignments - 1);
        subject.averageTimeSpentHours = (currentTotal + hoursSpent) / subject.completedAssignments;
      }
    }
  }
  return performance.values.toList();
}



//Get Weekly acticity breakdonw
List<WeeklyActivity> getWeeklyActivity({int weeks = 4}) {
  final activities = <WeeklyActivity>[];
  final now = DateTime.now();

  for (int i = 0; i < weeks;  i++) {
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1 - (i * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weeklySessions = _studySessions.where((s) => s.startTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd)).toList();
    final weeklyCompleted = _assignments.where((a) => a.status == AssignmentStatus.Completed && a.completionDate != null && a.completionDate!.isAfter(weekStart) && a.completionDate!.isBefore(weekEnd)).length;
    final dailyMinutes = <int, int>{};
    for (int day = 0; day < 7; day++) {
      final dayStart = WeekStart.add(Duration(days: day));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayMinutes = weeklySessions.where((s) => s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd)).fold(0, (sum, s) => sum + s.duration.inMinutes);
      dailyMinutes[day] = dayMinutes;
    }

    activities.add(WeeklyActivity(
      weekStart: weekStart,
      dailyStudyMinutes: dailyMinutes,
      totalAssignmentsCompleted: weeklyCompleted,
      totalStudySessions: weeklySessions.length,
      ));
  } 
  return activities;
}



//Get time-based analytics
TimeAnalytics getTimeAnalytics() {
  final studyByHour = Map<String, int>.fromIterable(List.generate(24, (i) => '$i:00'), value: (_) => 0,);
  final studyByDay = {
    'Monday': 0,
    'Tuesday': 0,
    'Wednesday': 0,
    'Thruusday': 0,
    'Friday': 0,
    'Saturaday': 0,
    'Sunday': 0,
  };

  int totalMinutes = 0;
  int totalSessions = _studySessions.length;
  
  for (var session in _studySessions) {
    final hour = session.startTime.hour;
    final dayName = _getDayName(session.startTime.weekday);
    studyByHour['$hour:00'] = (studyByHour['$hour:00'] ?? 0) + session.duration.inMinutes;
    studyByDay[dayName] = (studyByDay[dayName] ?? 0) + session.duration.inMinutes;
    totalMinutes += session.duration.inMinutes;
  }

  final mostProductiveHour = studyByHour.entries.reduce((a, b) => a.value > b.value ? a:b).key;
  final mostProductiveDay = studyByDay.entries.reduce(((a, b) => a.value > b.value ? a : b)).key;
  return TimeAnalytics(
    studyTimeByHour: studyByHour,
    studyTimeByDayOfWeek:  studyByDay,
    totalStudyMinutes: totalMinutes,
    averageSessionLengthMinutes: totalSessions > 0 ? totalMinutes ~/ totalSessions : 0,
    mostProductiveHour: int.parse(mostProductiveHour.split(':')[0]),
    mostProductiveDay: mostProductiveDay,
  );
}



//get list of insights for the dashboard
List<StudyInsight> getAllInsights() {
  return [
    StudyInsight(
      title: 'Compleion rate',
      description: 'Overall assignemtn completion',
      value: calculateOverallCompletionRate().toInt(),
      icon: Icons.check_circle,
      color: Colors.green,
      unit: '%',
    ),


    StudyInsight(
      title: 'On-time rate',
      description: 'Completed before deadline',
      value: calculateOnTimeCompletionRate().toInt(),
      icon: Icons.schedule,
      color: Colors.blue,
      unit: '%',
    ),


    StudyInsight(
      title: 'Total Sessions',
      description: 'Study session completed',
      value: _studySessions.length,
      icon: Icons.timer,
      color: Colors.purple,
      unit: '',
    ),
  ];
}



String _getDayName(int weekday) {
  const days = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };
  return days[weekday] ?? 'Monday';
}
}