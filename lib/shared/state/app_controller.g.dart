// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transcriptRepository)
final transcriptRepositoryProvider = TranscriptRepositoryProvider._();

final class TranscriptRepositoryProvider
    extends
        $FunctionalProvider<
          TranscriptRepository,
          TranscriptRepository,
          TranscriptRepository
        >
    with $Provider<TranscriptRepository> {
  TranscriptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptRepositoryHash();

  @$internal
  @override
  $ProviderElement<TranscriptRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranscriptRepository create(Ref ref) {
    return transcriptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptRepository>(value),
    );
  }
}

String _$transcriptRepositoryHash() =>
    r'd20bceaad449ac617290127b8fa3399a118c4350';

@ProviderFor(transcriptionService)
final transcriptionServiceProvider = TranscriptionServiceProvider._();

final class TranscriptionServiceProvider
    extends
        $FunctionalProvider<
          TranscriptionService,
          TranscriptionService,
          TranscriptionService
        >
    with $Provider<TranscriptionService> {
  TranscriptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptionServiceHash();

  @$internal
  @override
  $ProviderElement<TranscriptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranscriptionService create(Ref ref) {
    return transcriptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptionService>(value),
    );
  }
}

String _$transcriptionServiceHash() =>
    r'9b62d17bf0d6dbfeb4862473ce421b8ba4a428d3';

@ProviderFor(audioRecordingService)
final audioRecordingServiceProvider = AudioRecordingServiceProvider._();

final class AudioRecordingServiceProvider
    extends
        $FunctionalProvider<
          RecordingService,
          RecordingService,
          RecordingService
        >
    with $Provider<RecordingService> {
  AudioRecordingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioRecordingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioRecordingServiceHash();

  @$internal
  @override
  $ProviderElement<RecordingService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordingService create(Ref ref) {
    return audioRecordingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingService>(value),
    );
  }
}

String _$audioRecordingServiceHash() =>
    r'deb4e6394494942e88d264c810bf77359663b8d8';

@ProviderFor(summaryService)
final summaryServiceProvider = SummaryServiceProvider._();

final class SummaryServiceProvider
    extends $FunctionalProvider<SummaryService, SummaryService, SummaryService>
    with $Provider<SummaryService> {
  SummaryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summaryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summaryServiceHash();

  @$internal
  @override
  $ProviderElement<SummaryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SummaryService create(Ref ref) {
    return summaryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SummaryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SummaryService>(value),
    );
  }
}

String _$summaryServiceHash() => r'9632167ded56c990f3c4e3b9ff86a6de5f31ee93';
