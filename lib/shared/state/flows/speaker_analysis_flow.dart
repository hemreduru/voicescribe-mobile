part of '../app_controller.dart';

class SpeakerAnalysisFlow {
  const SpeakerAnalysisFlow();

  Future<void> recoverPendingProcessingJobs(AppController app) async {
    final restored = <ProcessingJob>[];
    for (final job in app.processingJobs) {
      if (job.status == ProcessingJobStatus.running &&
          job.type == ProcessingJobType.speakerAnalysis) {
        final pendingJob = job.copyWith(
          status: ProcessingJobStatus.pending,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        restored.add(pendingJob);
        await app._persist(app._repository.saveProcessingJob(pendingJob));
      } else {
        restored.add(job);
      }
    }
    app.processingJobs = restored;
    await runSpeakerAnalysisJobs(app);
  }

  Future<void> enqueueSpeakerAnalysisIfReady(
    AppController app,
    String transcriptId,
  ) async {
    final transcript = app.transcripts
        .where((item) => item.id == transcriptId)
        .firstOrNull;
    if (transcript == null ||
        transcript.status != TranscriptStatus.transcriptionCompleted) {
      return;
    }
    await enqueueSpeakerAnalysisJob(app, transcriptId);
  }

  Future<void> enqueueSpeakerAnalysisJob(
    AppController app,
    String transcriptId,
  ) async {
    final hasJob = app.processingJobs.any(
      (job) =>
          job.transcriptId == transcriptId &&
          job.type == ProcessingJobType.speakerAnalysis &&
          job.deletedAt == null &&
          (job.status == ProcessingJobStatus.pending ||
              job.status == ProcessingJobStatus.running),
    );
    if (hasJob) {
      return;
    }

    final now = DateTime.now();
    final job = ProcessingJob(
      id: 'job-${now.microsecondsSinceEpoch}',
      transcriptId: transcriptId,
      type: ProcessingJobType.speakerAnalysis,
      status: ProcessingJobStatus.pending,
      lastProcessedChunkIndex: 0,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    app.processingJobs = [job, ...app.processingJobs];
    await app._persist(app._repository.saveProcessingJob(job));
    await updateTranscriptStatus(
      app,
      transcriptId,
      TranscriptStatus.speakerAnalysisPending,
    );
    app._notify();
    await runSpeakerAnalysisJobs(app);
  }

  Future<void> runSpeakerAnalysisJobs(AppController app) async {
    if (app._speakerAnalysisInProgress) {
      return;
    }
    app._speakerAnalysisInProgress = true;

    try {
      final jobs =
          app.processingJobs
              .where(
                (job) =>
                    job.type == ProcessingJobType.speakerAnalysis &&
                    job.deletedAt == null &&
                    (job.status == ProcessingJobStatus.pending ||
                        job.status == ProcessingJobStatus.running),
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final job in jobs) {
        final calibrationSamples = <SpeakerEmbeddingSample>[];
        var workingJob = job.copyWith(
          status: ProcessingJobStatus.running,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clearSyncError: true,
        );
        replaceJob(app, workingJob);
        await app._persist(app._repository.saveProcessingJob(workingJob));
        await updateTranscriptStatus(
          app,
          job.transcriptId,
          TranscriptStatus.speakerAnalysisRunning,
        );

        final chunks = app.transcriptController.chunksFor(job.transcriptId);
        if (chunks.isEmpty) {
          workingJob = workingJob.copyWith(
            status: ProcessingJobStatus.completed,
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          );
          replaceJob(app, workingJob);
          await app._persist(app._repository.saveProcessingJob(workingJob));
          await updateTranscriptStatus(
            app,
            job.transcriptId,
            TranscriptStatus.speakerAnalysisCompleted,
          );
          continue;
        }

        try {
          for (
            var index = workingJob.lastProcessedChunkIndex;
            index < chunks.length;
            index++
          ) {
            final chunk = app.transcriptController
                .chunksFor(job.transcriptId)
                .elementAt(index);
            final runningChunk = chunk.copyWith(
              speakerAnalysisStatus: SpeakerAnalysisStatus.running,
              syncStatus: SyncStatus.pending,
              clearSyncError: true,
            );
            app.transcriptController.replaceChunk(runningChunk);
            await app._persist(app._repository.saveChunk(runningChunk));
            TranscriptChunk nextChunk;
            Object? chunkError;
            try {
              if (app._speakerAnalysisService.shouldSkipChunk(runningChunk)) {
                nextChunk = runningChunk.copyWith(
                  speakerAnalysisStatus: SpeakerAnalysisStatus.skipped,
                  syncStatus: SyncStatus.pending,
                );
              } else {
                final embedding = await app._speakerAnalysisService
                    .embeddingForChunk(runningChunk);
                final match = app._speakerAnalysisService.matchSpeaker(
                  chunkEmbedding: embedding,
                  speakers: app.speakers,
                );
                final matchedSpeaker = await _resolveMatchedSpeaker(
                  app,
                  matchSpeakerId: match.speakerId,
                  embedding: embedding,
                );
                calibrationSamples.add(
                  SpeakerEmbeddingSample(
                    speakerId: matchedSpeaker.id,
                    embedding: embedding,
                  ),
                );
                nextChunk = runningChunk.copyWith(
                  speakerId: matchedSpeaker.id,
                  speakerLabel: matchedSpeaker.name,
                  speakerConfidence: match.confidence,
                  speakerAnalysisStatus: SpeakerAnalysisStatus.completed,
                  syncStatus: SyncStatus.pending,
                );
              }
            } catch (error) {
              chunkError = error;
              nextChunk = runningChunk.copyWith(
                speakerAnalysisStatus: SpeakerAnalysisStatus.failed,
                syncStatus: SyncStatus.pending,
              );
            }

            app.transcriptController.replaceChunk(nextChunk);
            await app._persist(app._repository.saveChunk(nextChunk));
            if (chunkError == null) {
              await cleanupChunkAudio(app, nextChunk);
            }

            workingJob = workingJob.copyWith(
              status: ProcessingJobStatus.running,
              lastProcessedChunkIndex: index + 1,
              retryCount: chunkError == null
                  ? workingJob.retryCount
                  : workingJob.retryCount + 1,
              error: chunkError?.toString(),
              updatedAt: DateTime.now(),
              syncStatus: SyncStatus.pending,
              clearError: chunkError == null,
            );
            replaceJob(app, workingJob);
            await app._persist(app._repository.saveProcessingJob(workingJob));
          }

          workingJob = workingJob.copyWith(
            status: ProcessingJobStatus.completed,
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clearError: true,
          );
          replaceJob(app, workingJob);
          await app._persist(app._repository.saveProcessingJob(workingJob));
          await _applyCalibrationSamples(app, calibrationSamples);
          await updateTranscriptStatus(
            app,
            job.transcriptId,
            TranscriptStatus.speakerAnalysisCompleted,
          );
        } catch (error) {
          workingJob = workingJob.copyWith(
            status: ProcessingJobStatus.failed,
            retryCount: workingJob.retryCount + 1,
            error: error.toString(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          );
          replaceJob(app, workingJob);
          await app._persist(app._repository.saveProcessingJob(workingJob));
          await updateTranscriptStatus(
            app,
            job.transcriptId,
            TranscriptStatus.speakerAnalysisPending,
          );
        }
      }
    } finally {
      app._speakerAnalysisInProgress = false;
      app._notify();
      await app._safeTriggerSync();
    }
  }

  Future<void> cleanupChunkAudio(
    AppController app,
    TranscriptChunk chunk,
  ) async {
    final path = chunk.audioPath;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      final cleaned = chunk.copyWith(
        clearAudioPath: true,
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
      app.transcriptController.replaceChunk(cleaned);
      await app._persist(app._repository.saveChunk(cleaned));
    } catch (_) {
      // ignore chunk cleanup failures
    }
  }

  Future<SpeakerProfile> createAutoSpeaker(
    AppController app,
    List<double> embedding,
  ) async {
    final existingAutoCount = app.speakers
        .where((item) => !item.isUserNamed)
        .length;
    final speaker = SpeakerProfile(
      id: 'speaker-${DateTime.now().microsecondsSinceEpoch}',
      userId: app.currentUserId,
      name: 'Konuşmacı ${existingAutoCount + 1}',
      embedding: embedding,
      recordings: 1,
      hasVoiceSample: true,
      createdAt: DateTime.now(),
    );
    app.speakerController.speakers = [...app.speakers, speaker];
    await app._persist(app._repository.saveSpeaker(speaker));
    return speaker;
  }

  Future<SpeakerProfile> _resolveMatchedSpeaker(
    AppController app, {
    required String? matchSpeakerId,
    required List<double> embedding,
  }) async {
    final matched = matchSpeakerId == null
        ? null
        : app.speakers.where((item) => item.id == matchSpeakerId).firstOrNull;
    if (matched == null) {
      return createAutoSpeaker(app, embedding);
    }
    final updatedSpeaker = matched.copyWith(
      embedding: _blendEmbeddings(
        base: matched.embedding,
        incoming: embedding,
        baseRecordings: matched.recordings,
      ),
      recordings: matched.recordings + 1,
      hasVoiceSample: true,
      syncStatus: SyncStatus.pending,
      clearSyncError: true,
    );
    app.speakerController.speakers = app.speakers
        .map((item) => item.id == updatedSpeaker.id ? updatedSpeaker : item)
        .toList();
    await app._persist(app._repository.saveSpeaker(updatedSpeaker));
    return updatedSpeaker;
  }

  List<double> _blendEmbeddings({
    required List<double> base,
    required List<double> incoming,
    required int baseRecordings,
  }) {
    if (base.isEmpty) {
      return incoming;
    }
    if (incoming.isEmpty) {
      return base;
    }

    final length = math.min(base.length, incoming.length);
    final weight = baseRecordings <= 0 ? 1.0 : baseRecordings.toDouble();

    return List<double>.generate(length, (index) {
      final previous = base[index];
      final next = incoming[index];
      return (previous * weight + next) / (weight + 1);
    }, growable: false);
  }

  Future<void> archiveDuplicateSpeakerAnalysisJobs(AppController app) async {
    final byTranscript = <String, List<ProcessingJob>>{};
    for (final job in app.processingJobs) {
      if (job.type != ProcessingJobType.speakerAnalysis ||
          job.deletedAt != null) {
        continue;
      }
      byTranscript.putIfAbsent(job.transcriptId, () => []).add(job);
    }

    final archivedIds = <String>{};
    final now = DateTime.now();

    for (final entry in byTranscript.entries) {
      final jobs = [...entry.value]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (jobs.length <= 1) {
        continue;
      }

      final keep = jobs.firstWhere(
        (job) =>
            job.status == ProcessingJobStatus.pending ||
            job.status == ProcessingJobStatus.running,
        orElse: () => jobs.first,
      );

      for (final job in jobs) {
        if (job.id == keep.id) {
          continue;
        }
        final archived = job.copyWith(
          deletedAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
          clearSyncError: true,
        );
        await app._repository.saveProcessingJob(archived);
        archivedIds.add(job.id);
      }
    }

    if (archivedIds.isEmpty) {
      return;
    }

    app.processingJobs = app.processingJobs
        .where((job) => !archivedIds.contains(job.id))
        .toList();
  }

  Future<void> updateTranscriptStatus(
    AppController app,
    String transcriptId,
    TranscriptStatus status,
  ) async {
    final transcript = app.transcripts
        .where((item) => item.id == transcriptId)
        .firstOrNull;
    if (transcript == null || transcript.status == status) {
      return;
    }

    final updatedTranscript = transcript.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      clearSyncError: true,
    );
    app.transcriptController.replaceTranscript(updatedTranscript);
    await app._persist(app._repository.saveTranscript(updatedTranscript));
    app._notify();
  }

  void replaceJob(AppController app, ProcessingJob job) {
    final index = app.processingJobs.indexWhere((item) => item.id == job.id);
    if (index == -1) {
      app.processingJobs = [job, ...app.processingJobs];
      return;
    }
    final next = [...app.processingJobs];
    next[index] = job;
    app.processingJobs = next;
  }

  Future<double?> calibrateThreshold(AppController app) async {
    final labeledChunks = app.allChunks.where(
      (chunk) =>
          chunk.speakerId != null &&
          chunk.audioPath != null &&
          chunk.audioPath!.trim().isNotEmpty,
    );
    final samples = <SpeakerEmbeddingSample>[];
    for (final chunk in labeledChunks) {
      try {
        final embedding = await app._speakerAnalysisService.embeddingForChunk(
          chunk,
        );
        samples.add(
          SpeakerEmbeddingSample(
            speakerId: chunk.speakerId!,
            embedding: embedding,
          ),
        );
      } catch (_) {
        // ignore unusable chunk files during calibration
      }
    }
    return _applyCalibrationSamples(app, samples);
  }

  Future<double?> _applyCalibrationSamples(
    AppController app,
    List<SpeakerEmbeddingSample> samples,
  ) async {
    final threshold = app._speakerAnalysisService.calibrateSimilarityThreshold(
      samples: samples,
    );
    if (threshold == null) {
      return null;
    }
    await app._repository.saveSetting(
      'speakerSimilarityThreshold',
      threshold.toStringAsFixed(4),
    );
    return threshold;
  }
}
