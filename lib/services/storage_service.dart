abstract class BaseStorage {
  Future<void> init();
  
  /// Retrieves a value from the specified box.
  T? get<T>(String key, {String? boxName});
  
  /// Saves a value to the specified box.
  Future<void> set<T>(String key, T value, {String? boxName});
  
  /// Removes a key from the specified box.
  Future<void> remove(String key, {String? boxName});
  
  /// Returns all keys present in the specified box.
  List<String> getKeys({String? boxName});
  
  /// Closes the storage.
  Future<void> close();

  /// Exports all data as a JSON string.
  Future<String> exportData();

  /// Imports data from a JSON string. Returns true if successful.
  Future<bool> importData(String json);
}
