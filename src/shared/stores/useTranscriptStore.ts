import { create } from 'zustand';
import type { Transcript, TranscriptChunk } from '../types';

interface TranscriptStoreState {
  transcripts: Transcript[];
  currentTranscript: Transcript | null;
  currentChunks: TranscriptChunk[];
  allChunks: TranscriptChunk[];
  isLoading: boolean;

  setTranscripts: (transcripts: Transcript[]) => void;
  addTranscript: (transcript: Transcript) => void;
  setCurrentTranscript: (transcript: Transcript | null) => void;
  setCurrentChunks: (chunks: TranscriptChunk[]) => void;
  setAllChunks: (chunks: TranscriptChunk[]) => void;
  appendChunk: (chunk: TranscriptChunk) => void;
  updateChunkTextByAudioPath: (audioPath: string, text: string) => void;
  updateTranscript: (id: string, updates: Partial<Transcript>) => void;
  removeTranscript: (id: string) => void;
  setLoading: (loading: boolean) => void;
  reset: () => void;
}

export const useTranscriptStore = create<TranscriptStoreState>((set) => ({
  transcripts: [],
  currentTranscript: null,
  currentChunks: [],
  allChunks: [],
  isLoading: false,

  setTranscripts: (transcripts) => set({ transcripts }),

  addTranscript: (transcript) =>
    set((state) => ({
      transcripts: [transcript, ...state.transcripts],
    })),

  setCurrentTranscript: (transcript) =>
    set({ currentTranscript: transcript }),

  setCurrentChunks: (chunks) => set({ currentChunks: chunks }),

  setAllChunks: (chunks) => set({ allChunks: chunks }),

  appendChunk: (chunk) =>
    set((state) => ({
      currentChunks: [...state.currentChunks, chunk],
      allChunks: state.allChunks.some((existingChunk) => existingChunk.id === chunk.id)
        ? state.allChunks
        : [...state.allChunks, chunk],
    })),

  updateChunkTextByAudioPath: (audioPath, text) =>
    set((state) => ({
      currentChunks: state.currentChunks.map((chunk) =>
        chunk.audioPath === audioPath ? { ...chunk, text } : chunk,
      ),
      allChunks: state.allChunks.map((chunk) =>
        chunk.audioPath === audioPath ? { ...chunk, text } : chunk,
      ),
    })),

  updateTranscript: (id, updates) =>
    set((state) => ({
      transcripts: state.transcripts.map((t) =>
        t.id === id ? { ...t, ...updates } : t,
      ),
    })),

  removeTranscript: (id) =>
    set((state) => ({
      transcripts: state.transcripts.filter((t) => t.id !== id),
    })),

  setLoading: (loading) => set({ isLoading: loading }),

  reset: () =>
    set({
      transcripts: [],
      currentTranscript: null,
      currentChunks: [],
      allChunks: [],
      isLoading: false,
    }),
}));

export const serializeTranscriptStoreState = (
  state: Pick<TranscriptStoreState, 'transcripts' | 'currentTranscript' | 'currentChunks' | 'allChunks'>,
): string => {
  return JSON.stringify({
    transcripts: state.transcripts,
    currentTranscript: state.currentTranscript,
    currentChunks: state.currentChunks,
    allChunks: state.allChunks,
  });
};

export const parseTranscriptStoreState = (
  raw: string,
): Pick<TranscriptStoreState, 'transcripts' | 'currentTranscript' | 'currentChunks' | 'allChunks'> | null => {
  if (!raw || raw.trim().length === 0) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as Partial<TranscriptStoreState>;
    return {
      transcripts: Array.isArray(parsed.transcripts) ? parsed.transcripts : [],
      currentTranscript: (parsed.currentTranscript as Transcript | null) ?? null,
      currentChunks: Array.isArray(parsed.currentChunks) ? parsed.currentChunks : [],
      allChunks: Array.isArray(parsed.allChunks) ? parsed.allChunks : [],
    };
  } catch {
    return null;
  }
};
