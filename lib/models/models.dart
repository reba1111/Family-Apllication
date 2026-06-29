import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dateTime;
  final int notifyMinutesBefore;
  final String createdBy;

  const LessonModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dateTime,
    this.notifyMinutesBefore = 15,
    required this.createdBy,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      notifyMinutesBefore: data['notifyMinutesBefore'] ?? 15,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subject': subject,
        'dateTime': Timestamp.fromDate(dateTime),
        'notifyMinutesBefore': notifyMinutesBefore,
        'createdBy': createdBy,
      };
}

enum TaskPriority { high, normal, low }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedBy;
  final DateTime dueDate;
  final bool isDone;
  final DateTime createdAt;
  final TaskPriority priority;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.assignedTo,
    required this.assignedBy,
    required this.dueDate,
    this.isDone = false,
    required this.createdAt,
    this.priority = TaskPriority.normal,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final p = data['priority'] as String?;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: p == 'high'
          ? TaskPriority.high
          : p == 'low'
              ? TaskPriority.low
              : TaskPriority.normal,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'assignedBy': assignedBy,
        'dueDate': Timestamp.fromDate(dueDate),
        'isDone': isDone,
        'createdAt': Timestamp.fromDate(createdAt),
        'priority': priority.name,
      };

  TaskModel copyWith({bool? isDone}) => TaskModel(
        id: id,
        title: title,
        description: description,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        dueDate: dueDate,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
        priority: priority,
      );
}

class QuizModel {
  final String id;
  final String question;
  final String answer;
  final String createdBy;
  final String? answeredBy;
  final String? userAnswer;
  final bool? isCorrect;
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdBy,
    this.answeredBy,
    this.userAnswer,
    this.isCorrect,
    required this.createdAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      createdBy: data['createdBy'] ?? '',
      answeredBy: data['answeredBy'],
      userAnswer: data['userAnswer'],
      isCorrect: data['isCorrect'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'question': question,
        'answer': answer,
        'createdBy': createdBy,
        'answeredBy': answeredBy,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final DateTime? birthday;
  final String addedBy;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.birthday,
    required this.addedBy,
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] ?? '',
      relation: data['relation'] ?? '',
      birthday: (data['birthday'] as Timestamp?)?.toDate(),
      addedBy: data['addedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'relation': relation,
        'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
        'addedBy': addedBy,
      };
}
