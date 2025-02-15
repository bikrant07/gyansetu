import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/quiz_service.dart';

class QuizDataHelper {
  static const String offlineFileName = 'offline_quiz.json';

  static Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get localFile async {
    final path = await localPath;
    return File('$path/$offlineFileName');
  }

  static Future<void> updateOfflineQuestions(
      Map<String, dynamic> newQuestions) async {
    try {
      final file = await localFile;
      await file.writeAsString(json.encode(newQuestions));
      print('Offline questions updated successfully');
    } catch (e) {
      print('Error updating offline questions: $e');
      throw Exception('Failed to update offline questions');
    }
  }

  static Future<void> syncWithFirebase() async {
    try {
      // Get questions from Firebase
      final questionsDoc = await FirebaseFirestore.instance
          .collection('quiz_questions')
          .doc('master')
          .get();

      if (questionsDoc.exists) {
        // Update local storage with Firebase questions
        final firebaseQuestions = questionsDoc.data() as Map<String, dynamic>;
        final file = await localFile;
        await file.writeAsString(json.encode(firebaseQuestions));
        print('Questions synced from Firebase to local storage');
      } else {
        // Initialize Firebase if empty
        await QuizService.initializeFirebaseQuestions();
        await syncWithFirebase(); // Retry sync after initialization
      }
    } catch (e) {
      print('Error syncing questions with Firebase: $e');
      throw e; // Propagate error to handle fallback
    }
  }

  static Future<List<Map<String, dynamic>>> getOfflineQuestions(
    String className,
    List<String> subjects,
    List<int> questionCounts,
  ) async {
    try {
      // First try to read from local storage
      final file = await localFile;
      Map<String, dynamic> jsonData;

      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        jsonData = json.decode(jsonString);
        print('Reading from local storage');
      } else {
        // Fall back to asset file
        final String jsonString =
            await rootBundle.loadString('assets/quiz_data/offline_quiz.json');
        jsonData = json.decode(jsonString);
        print('Reading from assets');

        // Save to local storage for future use
        await file.writeAsString(jsonString);
      }

      if (!jsonData.containsKey(className)) {
        print('No questions found for $className');
        return [];
      }

      List<Map<String, dynamic>> selectedQuestions = [];

      // Get questions for each subject
      for (int i = 0; i < subjects.length; i++) {
        String subject = subjects[i];
        int count = questionCounts[i];

        if (jsonData[className].containsKey(subject) &&
            jsonData[className][subject] is List &&
            (jsonData[className][subject] as List).isNotEmpty) {
          List<dynamic> subjectQuestions =
              List.from(jsonData[className][subject]);
          subjectQuestions.shuffle();

          int questionsToAdd = count.clamp(0, subjectQuestions.length);
          print('Adding $questionsToAdd questions from $subject');

          for (int j = 0; j < questionsToAdd; j++) {
            selectedQuestions.add({
              ...subjectQuestions[j] as Map<String, dynamic>,
              'subject': subject,
            });
          }
        } else {
          print('No questions found for $subject in $className');
        }
      }

      print('Selected ${selectedQuestions.length} questions in total');
      selectedQuestions.shuffle();
      return selectedQuestions;
    } catch (e) {
      print('Error loading offline questions: $e');
      print(e.toString());
      return [];
    }
  }
}
