/**
 * Shared domain types used across features.
 */

export interface Transcript {
  id: string;
  localId: string;
  title: string | null;
  durationSeconds: number;
  statusKey: string;
  recordedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TranscriptChunk {
  id: string;
  transcriptId: string;
  chunkIndex: number;
  text: string;
  startTime: number;
  endTime: number;
  speakerLabel: string | null;
  confidence: number | null;
}

export interface Summary {
  id: string;
  transcriptId: string;
  providerKey: string;
  model: string;
  summaryText: string;
  tokenCount: number | null;
  processingTimeMs: number | null;
  createdAt: string;
}

export interface SpeakerProfile {
  id: string;
  name: string;
  embedding: number[];
  createdAt: string;
}

export interface RecordingState {
  isRecording: boolean;
  isPaused: boolean;
  durationSeconds: number;
  chunkCount: number;
}

export interface SyncStatus {
  lastSyncedAt: string | null;
  pendingCount: number;
  isSyncing: boolean;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T | null;
  errors: Record<string, string[]> | null;
  meta: {
    timestamp: string;
    version: string;
  };
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  meta: ApiResponse<T>['meta'] & {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
  };
}

export interface AuthTokens {
  token: string;
}

export interface User {
  id: number;
  name: string;
  email: string;
}
