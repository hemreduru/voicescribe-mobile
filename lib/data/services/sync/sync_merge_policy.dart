import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

enum MergeDecision { insertNew, updateFromServer, keepLocal }

class SyncMergePolicy {
  const SyncMergePolicy();

  Future<MergeDecision> decideMergeForRow({
    required DatabaseExecutor db,
    required String table,
    required Map<String, Object?> serverRow,
  }) async {
    final remoteId = _toText(serverRow['remote_id'] ?? serverRow['id']);
    final clientLocalId = _toText(
      serverRow['client_local_id'] ?? serverRow['local_id'],
    );

    Map<String, Object?>? localRow;
    if (remoteId != null) {
      final rows = await db.query(
        table,
        where: 'remoteId = ?',
        whereArgs: [remoteId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        localRow = rows.first;
      }
    }

    if (localRow == null && clientLocalId != null) {
      final idColumn = table == 'transcripts' ? 'localId' : 'id';
      final rows = await db.query(
        table,
        where: '$idColumn = ? OR id = ?',
        whereArgs: [clientLocalId, clientLocalId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        localRow = rows.first;
      }
    }

    if (localRow == null) {
      return MergeDecision.insertNew;
    }

    final localSyncStatus = SyncStatus.fromKey(
      localRow['syncStatus']?.toString(),
    );
    if (localSyncStatus == SyncStatus.syncing) {
      return MergeDecision.keepLocal;
    }

    final localUpdatedAt = DateTime.tryParse(
      (localRow['updatedAt'] ?? localRow['createdAt'] ?? '').toString(),
    );
    final serverUpdatedAt = DateTime.tryParse(
      _toText(serverRow['updated_at'] ?? serverRow['updatedAt']) ?? '',
    );

    if (serverUpdatedAt == null) {
      return MergeDecision.keepLocal;
    }
    if (localUpdatedAt == null) {
      return MergeDecision.updateFromServer;
    }

    return serverUpdatedAt.isAfter(localUpdatedAt)
        ? MergeDecision.updateFromServer
        : MergeDecision.keepLocal;
  }

  String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
