import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../models/study_insight_model.dart';

class StudyInsightScreen extends StatelessWidget {
  final List<Assignment> assignments;
  final List<dynamic> studySession;

  const StudyInsightScreen({
    super.key,
    required this.assignments,
    required this.studySession,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Insights'),
      ),
      body: const Center(
        child: Text('Study Insights Screen Placeholder'),
      ),
    );
  }
}
