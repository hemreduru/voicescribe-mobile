import 'package:voicescribe_mobile/shared/models/domain.dart';

class SpeakerController {
  List<SpeakerProfile> speakers = [];

  void hydrate(List<SpeakerProfile> saved) {
    speakers = saved;
    if (speakers.isEmpty) {
      speakers = [
        SpeakerProfile(
          id: 'speaker-1',
          name: 'Konuşmacı 1',
          embedding: const [],
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  void addSpeaker(String name, {String? userId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    speakers = [
      ...speakers,
      SpeakerProfile(
        id: 'speaker-${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        embedding: const [],
        createdAt: DateTime.now(),
        userId: userId,
      ),
    ];
  }

  void updateSpeaker(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    speakers = speakers
        .map(
          (speaker) => speaker.id == id
              ? speaker.copyWith(
                  name: trimmed,
                  syncStatus: SyncStatus.pending,
                  clearSyncError: true,
                )
              : speaker,
        )
        .toList();
  }

  void deleteSpeaker(String id) {
    speakers = speakers.where((speaker) => speaker.id != id).toList();
  }
}
