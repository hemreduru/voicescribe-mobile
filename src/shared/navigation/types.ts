/**
 * Navigation type definitions for type-safe navigation.
 */

export type RootTabParamList = {
  RecordingTab: undefined;
  TranscriptTab: undefined;
  SummaryTab: undefined;
  HistoryTab: undefined;
  SpeakerTab: undefined;
};

export type RecordingStackParamList = {
  Recording: undefined;
  Settings: undefined;
};

export type TranscriptStackParamList = {
  TranscriptList: undefined;
  TranscriptDetail: { transcriptId: string };
};

export type SummaryStackParamList = {
  SummaryList: undefined;
  SummaryDetail: { summaryId: string };
};

export type HistoryStackParamList = {
  HistoryList: undefined;
  HistoryDetail: { transcriptId: string };
};

export type SpeakerStackParamList = {
  SpeakerList: undefined;
  SpeakerEnroll: undefined;
  SpeakerDetail: { profileId: string };
};
