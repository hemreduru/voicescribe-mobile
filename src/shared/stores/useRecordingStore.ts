import { create } from 'zustand';

interface RecordingStoreState {
  isRecording: boolean;
  isPaused: boolean;
  durationSeconds: number;
  chunkCount: number;
  currentTranscriptId: string | null;

  startRecording: (transcriptId: string) => void;
  stopRecording: () => void;
  pauseRecording: () => void;
  resumeRecording: () => void;
  incrementDuration: () => void;
  incrementChunkCount: () => void;
  reset: () => void;
}

export const useRecordingStore = create<RecordingStoreState>((set) => ({
  isRecording: false,
  isPaused: false,
  durationSeconds: 0,
  chunkCount: 0,
  currentTranscriptId: null,

  startRecording: (transcriptId: string) =>
    set({
      isRecording: true,
      isPaused: false,
      durationSeconds: 0,
      chunkCount: 0,
      currentTranscriptId: transcriptId,
    }),

  stopRecording: () =>
    set({
      isRecording: false,
      isPaused: false,
      currentTranscriptId: null,
    }),

  pauseRecording: () => set({ isPaused: true }),

  resumeRecording: () => set({ isPaused: false }),

  incrementDuration: () =>
    set((state) => ({ durationSeconds: state.durationSeconds + 1 })),

  incrementChunkCount: () =>
    set((state) => ({ chunkCount: state.chunkCount + 1 })),

  reset: () =>
    set({
      isRecording: false,
      isPaused: false,
      durationSeconds: 0,
      chunkCount: 0,
      currentTranscriptId: null,
    }),
}));
