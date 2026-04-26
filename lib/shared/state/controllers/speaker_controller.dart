import 'package:voicescribe_mobile/shared/models/domain.dart';

class SpeakerController {
  List<SpeakerProfile> speakers = [];
  bool recognitionEnabled = true;

  void hydrate(List<SpeakerProfile> saved, {required bool recognitionEnabled}) {
    speakers = saved;
    this.recognitionEnabled = recognitionEnabled;
    if (speakers.isEmpty) {
      speakers = [
        SpeakerProfile(
          id: 'speaker-1',
          name: 'Konusmaci 1',
          embedding: const [],
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // Controller methods intentionally keep mutation explicit for AppController.
  // ignore: use_setters_to_change_properties
  void applyRecognitionEnabled({required bool value}) {
    recognitionEnabled = value;
  }

  void addSpeaker(String name) {
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
          (speaker) =>
              speaker.id == id ? speaker.copyWith(name: trimmed) : speaker,
        )
        .toList();
  }

  void deleteSpeaker(String id) {
    speakers = speakers.where((speaker) => speaker.id != id).toList();
  }
}
