import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/quiz_data.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class QuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase with default questions from assets
  static Future<void> initializeFirebaseQuestions() async {
    try {
      final docRef = _firestore.collection('quiz_questions').doc('master');
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Load default questions from assets
        final String jsonString =
            await rootBundle.loadString('assets/quiz_data/offline_quiz.json');
        final questions = json.decode(jsonString);

        // Save to Firebase
        await docRef.set(questions);
        print('Firebase initialized with default questions');
      }
    } catch (e) {
      print('Error initializing Firebase questions: $e');
    }
  }

  // Update Firebase questions with new AI-generated ones
  static Future<void> updateFirebaseQuestions(
      String className, List<Map<String, dynamic>> newQuestions) async {
    try {
      final docRef = _firestore.collection('quiz_questions').doc('master');

      // Get current data
      final docSnapshot = await docRef.get();
      Map<String, dynamic> existingData = {};

      if (docSnapshot.exists) {
        existingData = docSnapshot.data() as Map<String, dynamic>;
      }

      // Initialize class structure if it doesn't exist
      if (!existingData.containsKey(className)) {
        existingData[className] = {
          'Mathematics': [],
          'Science': [],
          'English': [],
          'Social Studies': []
        };
      }

      // Organize and add new questions
      Map<String, List<Map<String, dynamic>>> questionsBySubject = {};

      // Initialize subject lists
      questionsBySubject['Mathematics'] = [];
      questionsBySubject['Science'] = [];
      questionsBySubject['English'] = [];
      questionsBySubject['Social Studies'] = [];

      // Sort questions by subject
      for (var question in newQuestions) {
        final subject = question['subject'] as String;
        if (questionsBySubject.containsKey(subject)) {
          questionsBySubject[subject]!.add(question);
        }
      }

      // Update each subject's questions
      questionsBySubject.forEach((subject, questions) {
        if (!existingData[className].containsKey(subject)) {
          existingData[className][subject] = [];
        }

        // Add new questions to existing ones
        List<dynamic> currentQuestions =
            List.from(existingData[className][subject]);
        currentQuestions.addAll(questions);

        // Remove duplicates based on question text
        final seen = <String>{};
        currentQuestions = currentQuestions.where((question) {
          final questionText = question['question'] as String;
          return seen.add(questionText);
        }).toList();

        existingData[className][subject] = currentQuestions;
      });

      // Update the document
      await docRef.set(existingData);
      print('Firebase questions updated successfully');
    } catch (e) {
      print('Error updating Firebase questions: $e');
      throw e;
    }
  }

  static bool _questionExists(
      List<dynamic> existingQuestions, Map<String, dynamic> newQuestion) {
    return existingQuestions.any((q) =>
        q['question'] == newQuestion['question'] &&
        q['correctAnswer'] == newQuestion['correctAnswer']);
  }
}
