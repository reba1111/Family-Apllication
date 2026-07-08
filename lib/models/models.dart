import 'package:cloud_firestore/cloud_firestore.dart';

export 'relationship_stats.dart';
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
  final String? phone;
  final String? note;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.birthday,
    required this.addedBy,
    this.phone,
    this.note,
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] ?? '',
      relation: data['relation'] ?? '',
      birthday: (data['birthday'] as Timestamp?)?.toDate(),
      addedBy: data['addedBy'] ?? '',
      phone: data['phone'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'relation': relation,
        'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
        'addedBy': addedBy,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

class MemoryModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;

  const MemoryModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
    required this.createdBy,
    required this.createdAt,
  });

  factory MemoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(date),
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  MemoryModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    DateTime? date,
  }) {
    return MemoryModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

class NoteModel {
  final String id;
  final String content;
  final String createdBy;
  final DateTime unlockDate;
  final bool isRead;
  final DateTime createdAt;

  const NoteModel({
    required this.id,
    required this.content,
    required this.createdBy,
    required this.unlockDate,
    this.isRead = false,
    required this.createdAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      content: data['content'] ?? '',
      createdBy: data['createdBy'] ?? '',
      unlockDate: (data['unlockDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'content': content,
        'createdBy': createdBy,
        'unlockDate': Timestamp.fromDate(unlockDate),
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NoteModel copyWith({
    String? content,
    DateTime? unlockDate,
    bool? isRead,
  }) {
    return NoteModel(
      id: id,
      content: content ?? this.content,
      createdBy: createdBy,
      unlockDate: unlockDate ?? this.unlockDate,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String icon; // Emoji icon
  final DateTime targetDate;
  final String currency; // "$" or "IQD"
  final String createdBy;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.icon,
    required this.targetDate,
    this.currency = '\$', // Default to USD for old entries
    required this.createdBy,
    required this.createdAt,
  });

  bool get isCompleted => currentAmount >= targetAmount;
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      title: data['title'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      icon: data['icon'] ?? '🎯',
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: data['currency'] ?? '\$',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'icon': icon,
        'targetDate': Timestamp.fromDate(targetDate),
        'currency': currency,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  GoalModel copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    DateTime? targetDate,
    String? currency,
  }) {
    return GoalModel(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      targetDate: targetDate ?? this.targetDate,
      currency: currency ?? this.currency,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

class GoalTransactionModel {
  final String id;
  final double amount;
  final String userId;
  final DateTime createdAt;

  const GoalTransactionModel({
    required this.id,
    required this.amount,
    required this.userId,
    required this.createdAt,
  });

  factory GoalTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalTransactionModel(
      id: doc.id,
      amount: (data['amount'] ?? 0).toDouble(),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class ShoppingItemModel {
  final String id;
  final String name;
  final bool isBought;
  final String addedBy;
  final DateTime createdAt;

  const ShoppingItemModel({
    required this.id,
    required this.name,
    this.isBought = false,
    required this.addedBy,
    required this.createdAt,
  });

  factory ShoppingItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      isBought: data['isBought'] ?? false,
      addedBy: data['addedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'isBought': isBought,
        'addedBy': addedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ShoppingItemModel copyWith({bool? isBought, String? name}) => ShoppingItemModel(
        id: id,
        name: name ?? this.name,
        isBought: isBought ?? this.isBought,
        addedBy: addedBy,
        createdAt: createdAt,
      );
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // e.g., 'birthday', 'anniversary', 'appointment', 'trip', 'other'
  final String icon;
  final bool notify;
  final String createdBy;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.type,
    required this.icon,
    this.notify = true,
    required this.createdBy,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'other',
      icon: data['icon'] ?? '📅',
      notify: data['notify'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'type': type,
        'icon': icon,
        'notify': notify,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? type,
    String? icon,
    bool? notify,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      notify: notify ?? this.notify,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
