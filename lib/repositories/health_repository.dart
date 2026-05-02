import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weight_record_model.dart';

/// Repository for upcoming pet-care reminders.
///
/// Backs the "Today" strip on the dashboard. Each reminder belongs to
/// a user (`userId`) and a pet (`petId`). Queries are filtered to the
/// current signed-in user; mutations require auth.
class RemindersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('reminders');

  String get _uid {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null) {
      throw StateError(
        'RemindersRepository accessed without a signed-in user.',
      );
    }
    return id;
  }

  /// Fetch upcoming, not-yet-completed reminders for the current user.
  /// Returns at most [limit] items, soonest first.
  Future<List<ReminderModel>> getUpcoming({int limit = 5}) async {
    try {
      // No composite-index dependency: filter on userId + isCompleted,
      // then sort/slice in memory. Reminders are small in count.
      final snap = await _collection
          .where('userId', isEqualTo: _uid)
          .where('isCompleted', isEqualTo: false)
          .get();

      final items = snap.docs
          .map((d) => ReminderModel.fromFirestore(
                d.data() as Map<String, dynamic>,
                d.id,
              ))
          .toList();
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return items.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Fetch upcoming reminders for a single pet.
  Future<List<ReminderModel>> getUpcomingForPet(
    String petId, {
    int limit = 5,
  }) async {
    try {
      final snap = await _collection
          .where('userId', isEqualTo: _uid)
          .where('petId', isEqualTo: petId)
          .where('isCompleted', isEqualTo: false)
          .get();
      final items = snap.docs
          .map((d) => ReminderModel.fromFirestore(
                d.data() as Map<String, dynamic>,
                d.id,
              ))
          .toList();
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return items.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Mark a reminder as completed. Best-effort — returns false on error.
  Future<bool> markComplete(String reminderId) async {
    try {
      await _collection.doc(reminderId).update({
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Add a new reminder. Returns the new doc id, or null on error.
  Future<String?> add(ReminderModel reminder) async {
    try {
      final doc = await _collection.add({
        ...reminder.toFirestore(),
        'userId': _uid,
      });
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  /// Delete a reminder by id.
  Future<bool> delete(String reminderId) async {
    try {
      await _collection.doc(reminderId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Repository for weight records. Backs the dashboard weight-trend
/// sparkline and the "log weight" quick-action.
class WeightRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection('weight_records');

  String get _uid {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null) {
      throw StateError(
        'WeightRepository accessed without a signed-in user.',
      );
    }
    return id;
  }

  /// All weight logs for a pet, oldest-first. Suitable for charting.
  Future<List<WeightRecordModel>> getPetWeights(String petId) async {
    try {
      final snap = await _collection
          .where('userId', isEqualTo: _uid)
          .where('petId', isEqualTo: petId)
          .get();
      final items = snap.docs
          .map((d) => WeightRecordModel.fromFirestore(
                d.data() as Map<String, dynamic>,
                d.id,
              ))
          .toList();
      items.sort((a, b) => a.date.compareTo(b.date));
      return items;
    } catch (_) {
      return const [];
    }
  }

  /// Most recent weight log for a pet, or null if none.
  Future<WeightRecordModel?> getLatest(String petId) async {
    final all = await getPetWeights(petId);
    return all.isEmpty ? null : all.last;
  }

  /// Log a new weight reading. Throws on failure so the caller can
  /// surface the real error (commonly Firestore rules / permissions)
  /// in the UI instead of a generic "Try again" snackbar.
  Future<String> add({
    required String petId,
    required double weight,
    DateTime? date,
    String? notes,
  }) async {
    final record = WeightRecordModel(
      petId: petId,
      weight: weight,
      date: date ?? DateTime.now(),
      notes: notes,
    );
    final doc = await _collection.add({
      ...record.toFirestore(),
      'userId': _uid,
    });
    return doc.id;
  }
}
