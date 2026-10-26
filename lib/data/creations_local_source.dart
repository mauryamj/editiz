import 'package:hive_ce/hive.dart';

// Class: data source for persisting creations in Hive box 'creations'.
class CreationsLocalSource {
  // Field: box name constant.
  static const String boxName = 'creations';

  // Getter/helper: safely accesses or opens the Hive box.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  // Method: stores a creation map using its id string as the key.
  Future<void> addCreation(Map<String, dynamic> creationMap) async {
    final box = await _getBox();
    final id = creationMap['id'];
    await box.put(id.toString(), creationMap);
  }

  // Method: retrieves all creation records as a list of maps.
  List<Map<dynamic, dynamic>> getAllCreations() {
    if (!Hive.isBoxOpen(boxName)) {
      return [];
    }
    return Hive.box(boxName).values.cast<Map<dynamic, dynamic>>().toList();
  }

  // Method: removes a creation record by ID string.
  Future<void> deleteCreation(int id) async {
    final box = await _getBox();
    await box.delete(id.toString());
  }
}
