import 'package:flutter/material.dart';
import 'assignment_model.dart';



class StudyInsight {
    final String title;
    final String description;
    final int value;
    final IconData icon;
    final Color color;
    final String unit;


    StudyInsight ({
        required this.title,
        required this.description,
        required this.value,
        required this.icon,
        required this.color,
        required this.unit,
    });
}



class SubjectPerformance {
    final String subject;
    int totalAssignments;
    int completedAssignments;
    int lateCompletions;
    int averageScore;
    double averageTimeSpentHours;


    SubjectPerformance({
        required this.subject,
        this.totalAssignments = 0,
        this.completedAssignments = 0,
        this.lateCompletions = 0,
        this.averageScore = 0,
        this.averageTimeSpentHours = 0.0,
    });


    double get completionRate {
        if (totalAssignments == 0) return 0;
        return (completedAssignments / totalAssignments) * 100;
    }


    String get performanceGrade {
        if (completionRate >= 90) return 'A+';
        if (completionRate >= 80) return 'A';
        if (completionRate >= 70) return 'B+';
        if (completionRate >= 60) return 'B';
        if (completionRate >= 50) return 'C+';
        if (completionRate >= 40) return 'C';
        if (completionRate >= 30) return 'D';
        return 'F';
    }


    Color get gradeColor {
        if (completionRate >= 80) return Colors.green;
        if (completionRate >= 60) return Colors.lightGreen;
        if (completionRate >= 40) return Colors.orange;
        if (completionRate >= 30) return Colors.deepOrange;
        return Colors.red;
    }
}



class WeeklyActivity {
    final DateTime weekStart;
    final Map<int, int> dailyStudyMinutes;
    final int totalAssignmentsCompleted;
    final int totalStudySessions;


    WeeklyActivity ({
        required this.weekStart,
        required this.dailyStudyMinutes,
        this.totalAssignmentsCompleted = 0,
        this.totalStudySessions = 0,
    });

    int get totalStudyMinutes {
        return dailyStudyMinutes.values.fold(0, (sum, minutes) => sum + minutes);
    }


    double get averageDailyMinutes {
        if (dailyStudyMinutes.isEmpty) return 0;
        return totalStudyMinutes / dailyStudyMinutes.length;
    }

    int get mostProductiveDay {
        if (dailyStudyMinutes.isEmpty) return 0;
        return dailyStudyMinutes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }


    String getDayName(int dayIndex) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dayIndex];
    }  
}


class StudyTrend {
    final String direction;
    final double precentageChange;
    final String message;

    StudyTrend({
        required this.direction,
        required this.precentageChange,
        required this.message,
    });
}



class TimeAnalytics {
    final Map<String, int> studyTimeByHour;
    final Map<String, int> studyTimeByDayOfWeek;
    final int totalStudyMinutes;
    final int averageSessionLengthMinutes;
    final int mostProductiveHour;
    final String mostProductiveDay;


    TimeAnalytics({
        required this.studyTimeByHour,
        required this.studyTimeByDayOfWeek,
        required this.totalStudyMinutes,
        required this.averageSessionLengthMinutes,
        required this.mostProductiveHour,
        required this.mostProductiveDay,
    });


    String get formattedTotalTime {
        final hours = totalStudyMinutes ~/ 60;
        final minutes = totalStudyMinutes % 60;

        if (hours > 0) {
            return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
        } 
        return '$minutes min';
    }
}

