import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/analysis.dart';

/// Persists past analyses. Records live in SharedPreferences as JSON; the
/// specimen photographs are copied into the app's documents directory so the
/// originals can move or be deleted without breaking the library.
class HistoryStore extends ChangeNotifier {
  HistoryStore(this._prefs) {
    _load();
  }

  static const String _key = 'analysis_history';

  final SharedPreferences _prefs;
  List<AnalysisRecord> _records = <AnalysisRecord>[];

  /// Newest first.
  List<AnalysisRecord> get records => List<AnalysisRecord>.unmodifiable(_records);

  bool get isEmpty => _records.isEmpty;

  int get humanCount =>
      _records.where((AnalysisRecord r) => r.result.isHuman).length;

  int get flaggedCount => _records
      .where((AnalysisRecord r) => r.result.damage.flagged.isNotEmpty)
      .length;

  void _load() {
    final List<String> raw = _prefs.getStringList(_key) ?? <String>[];
    _records = raw
        .map((String s) {
          try {
            return AnalysisRecord.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AnalysisRecord>()
        .toList()
      ..sort((AnalysisRecord a, AnalysisRecord b) =>
          b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _records.map((AnalysisRecord r) => jsonEncode(r.toJson())).toList(),
    );
    notifyListeners();
  }

  /// Copies [sources] into permanent storage and returns their new paths, in
  /// order. Photos already there (a saved record's, when angles are added to
  /// it) stay where they are.
  Future<List<String>> archiveImages(List<File> sources, String id) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory specimens = Directory('${dir.path}/specimens');
    if (!await specimens.exists()) {
      await specimens.create(recursive: true);
    }
    final String stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final List<String> paths = <String>[];
    for (int i = 0; i < sources.length; i++) {
      final File source = sources[i];
      if (source.parent.path == specimens.path) {
        paths.add(source.path);
        continue;
      }
      final String ext = source.path.split('.').last;
      final File dest = File('${specimens.path}/${id}_${stamp}_$i.$ext');
      await source.copy(dest.path);
      paths.add(dest.path);
    }
    return paths;
  }

  Future<void> add(AnalysisRecord record) async {
    _records = <AnalysisRecord>[record, ..._records];
    await _persist();
  }

  bool contains(String id) => _records.any((AnalysisRecord r) => r.id == id);

  /// Replaces the stored version of [record]. Photos the old version had and
  /// the new one dropped are deleted.
  Future<void> update(AnalysisRecord record) async {
    final int i = _records.indexWhere((AnalysisRecord r) => r.id == record.id);
    if (i == -1) return;
    final AnalysisRecord old = _records[i];
    _records = List<AnalysisRecord>.from(_records)..[i] = record;
    await _persist();
    await _deletePhotos(
        old.imagePaths.where((String p) => !record.imagePaths.contains(p)));
  }

  Future<void> _deletePhotos(Iterable<String> paths) async {
    for (final String path in paths) {
      final File f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  Future<void> remove(String id) async {
    final AnalysisRecord? gone = _records
        .cast<AnalysisRecord?>()
        .firstWhere((AnalysisRecord? r) => r?.id == id, orElse: () => null);
    _records = _records.where((AnalysisRecord r) => r.id != id).toList();
    await _persist();
    if (gone != null) await _deletePhotos(gone.imagePaths);
  }

  Future<void> clear() async {
    for (final AnalysisRecord r in _records) {
      await _deletePhotos(r.imagePaths);
    }
    _records = <AnalysisRecord>[];
    await _persist();
  }

  /// Whole library as a JSON document, for the export row in Settings.
  String exportJson() => const JsonEncoder.withIndent('  ').convert(
        <String, dynamic>{
          'exported_at': DateTime.now().toIso8601String(),
          'count': _records.length,
          'records':
              _records.map((AnalysisRecord r) => r.toJson()).toList(),
        },
      );
}
