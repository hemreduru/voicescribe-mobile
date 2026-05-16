import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';

import '../../../helpers/fakes.dart';

void main() {
  blocTest<TranscriptListBloc, TranscriptListState>(
    'filters and sorts transcript list state newest first',
    build: () {
      final now = DateTime.utc(2026, 5, 16, 12);
      return TranscriptListBloc(
        transcriptRepository: FakeTranscriptRepository(
          initial: TranscriptSnapshot(
            transcripts: [
              Transcript(
                id: 'short',
                localId: 'short',
                title: 'Short',
                durationSeconds: 2,
                status: TranscriptStatus.completed,
                recordedAt: now,
                createdAt: now,
                updatedAt: now,
              ),
              Transcript(
                id: 'long',
                localId: 'long',
                title: 'Long',
                durationSeconds: 10,
                status: TranscriptStatus.transcriptionError,
                recordedAt: now.add(const Duration(minutes: 1)),
                createdAt: now.add(const Duration(minutes: 1)),
                updatedAt: now.add(const Duration(minutes: 1)),
              ),
            ],
            chunks: const [],
            summaries: const [],
          ),
        ),
      );
    },
    act: (bloc) async {
      bloc.add(const TranscriptListSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TranscriptListFilterChanged(TranscriptFilter.issue));
      bloc.add(const TranscriptListSortChanged(TranscriptSort.longest));
    },
    verify: (bloc) {
      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.items.single.transcript.id, 'long');
    },
  );

  blocTest<TranscriptListBloc, TranscriptListState>(
    'newest and oldest sort by transcript recency',
    build: () {
      final base = DateTime.utc(2026, 5, 16, 12);
      return TranscriptListBloc(
        transcriptRepository: FakeTranscriptRepository(
          initial: TranscriptSnapshot(
            transcripts: [
              Transcript(
                id: 'older',
                localId: 'older',
                title: 'Older',
                durationSeconds: 4,
                status: TranscriptStatus.completed,
                recordedAt: base,
                createdAt: base,
                updatedAt: base,
              ),
              Transcript(
                id: 'newer',
                localId: 'newer',
                title: 'Newer',
                durationSeconds: 6,
                status: TranscriptStatus.completed,
                recordedAt: base.add(const Duration(minutes: 10)),
                createdAt: base.add(const Duration(minutes: 10)),
                updatedAt: base.add(const Duration(minutes: 10)),
              ),
            ],
            chunks: const [],
            summaries: const [],
          ),
        ),
      );
    },
    act: (bloc) async {
      bloc.add(const TranscriptListSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TranscriptListSortChanged(TranscriptSort.newest));
    },
    verify: (bloc) {
      expect(bloc.state.items.first.transcript.id, 'newer');
      expect(bloc.state.items.last.transcript.id, 'older');
    },
  );

  blocTest<TranscriptListBloc, TranscriptListState>(
    'oldest sort reverses newest order',
    build: () {
      final base = DateTime.utc(2026, 5, 16, 12);
      return TranscriptListBloc(
        transcriptRepository: FakeTranscriptRepository(
          initial: TranscriptSnapshot(
            transcripts: [
              Transcript(
                id: 'older',
                localId: 'older',
                title: 'Older',
                durationSeconds: 4,
                status: TranscriptStatus.completed,
                recordedAt: base,
                createdAt: base,
                updatedAt: base,
              ),
              Transcript(
                id: 'newer',
                localId: 'newer',
                title: 'Newer',
                durationSeconds: 6,
                status: TranscriptStatus.completed,
                recordedAt: base.add(const Duration(minutes: 10)),
                createdAt: base.add(const Duration(minutes: 10)),
                updatedAt: base.add(const Duration(minutes: 10)),
              ),
            ],
            chunks: const [],
            summaries: const [],
          ),
        ),
      );
    },
    act: (bloc) async {
      bloc.add(const TranscriptListSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TranscriptListSortChanged(TranscriptSort.oldest));
    },
    verify: (bloc) {
      expect(bloc.state.items.first.transcript.id, 'older');
      expect(bloc.state.items.last.transcript.id, 'newer');
    },
  );

  test('legacy transcription completed status displays as ready', () {
    expect(
      displayStatusFor(TranscriptStatus.transcriptionCompleted),
      TranscriptDisplayStatus.ready,
    );
  });
}
