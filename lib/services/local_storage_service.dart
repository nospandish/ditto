import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/saved_plan.dart';

class LocalStorageService {
  LocalStorageService(this._preferences);

  static const _tasksKey = 'ditto.tasks.v1';
  static const _availableTimeKey = 'ditto.available_time.v1';
  static const _hasGeneratedPlanKey = 'ditto.has_generated_plan.v1';
  static const _savedPlansKey = 'ditto.saved_plans.v1';
  static const _activePlanIdKey = 'ditto.active_plan_id.v1';

  final SharedPreferences _preferences;

  static Future<LocalStorageService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStorageService(preferences);
  }

  Future<void> saveTasks(List<DittoTask> tasks) async {
    final value = jsonEncode(tasks.map((task) => task.toJson()).toList());
    final saved = await _preferences.setString(_tasksKey, value);
    if (!saved) throw StateError('Could not save tasks.');
  }

  List<DittoTask> loadTasks() {
    return _loadList(_tasksKey, DittoTask.fromJson);
  }

  Future<void> saveAvailableTime(List<AvailableTimeBlock> blocks) async {
    final value = jsonEncode(blocks.map((block) => block.toJson()).toList());
    final saved = await _preferences.setString(_availableTimeKey, value);
    if (!saved) throw StateError('Could not save available time.');
  }

  List<AvailableTimeBlock> loadAvailableTime() {
    return _loadList(_availableTimeKey, AvailableTimeBlock.fromJson);
  }

  Future<void> saveHasGeneratedPlan(bool value) async {
    final saved = await _preferences.setBool(_hasGeneratedPlanKey, value);
    if (!saved) throw StateError('Could not save generated-plan state.');
  }

  bool loadHasGeneratedPlan() {
    return _preferences.getBool(_hasGeneratedPlanKey) ?? false;
  }

  Future<void> savePlans(List<SavedPlan> plans) async {
    final value = jsonEncode(plans.map((plan) => plan.toJson()).toList());
    final saved = await _preferences.setString(_savedPlansKey, value);
    if (!saved) throw StateError('Could not save plans.');
  }

  List<SavedPlan> loadPlans() {
    return _loadList(_savedPlansKey, SavedPlan.fromJson);
  }

  Future<void> saveActivePlanId(String? planId) async {
    final saved = planId == null
        ? await _preferences.remove(_activePlanIdKey)
        : await _preferences.setString(_activePlanIdKey, planId);
    if (!saved && planId != null) {
      throw StateError('Could not save the selected plan.');
    }
  }

  String? loadActivePlanId() {
    return _preferences.getString(_activePlanIdKey);
  }

  Future<void> clearAllData() async {
    final results = await Future.wait([
      _preferences.remove(_tasksKey),
      _preferences.remove(_availableTimeKey),
      _preferences.remove(_hasGeneratedPlanKey),
      _preferences.remove(_savedPlansKey),
      _preferences.remove(_activePlanIdKey),
    ]);
    if (results.any((removed) => !removed)) {
      throw StateError('Could not clear saved data.');
    }
  }

  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final storedValue = _preferences.getString(key);
    if (storedValue == null) return [];

    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is! List) return [];

      final items = <T>[];
      for (final item in decoded) {
        try {
          if (item is! Map) continue;
          items.add(fromJson(Map<String, dynamic>.from(item)));
        } on Object {
          // Keep valid records even if one stored record is malformed.
        }
      }
      return items;
    } on Object {
      return [];
    }
  }
}
