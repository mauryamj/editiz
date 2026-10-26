import 'package:hive_ce/hive.dart';

// Class: data source for persisting creations in Hive box 'creations'.
class CreationsLocalSource {
  // Field: box name constant.
  static const String boxName = 'creations';

  // Getter: lazily accesses the opened Hive box.
  Box get _box => Hive.box(boxName);

  // Method: stores a creation map using its id as the key.
  Future<void> addCreation(Map<String, dynamic> creationMap) async {
    final id = creationMap['id'];
    await _box.put(id, creationMap);
  }

  // Method: retrieves all creation records as a list of maps.
  List<Map<dynamic, dynamic>> getAllCreations() {
    return _box.values.cast<Map<dynamic, dynamic>>().toList();
  }

  // Method: removes a creation record by ID.
  Future<void> deleteCreation(int id) async {
    await _box.delete(id);
  }
}
