import { create } from 'zustand';
import type { Transcript, TranscriptChunk } from '../types';

interface TranscriptStoreState {
  transcripts: Transcript[];
  currentTranscript: Transcript | null;
  currentChunks: TranscriptChunk[];
  isLoading: boolean;

  setTranscripts: (transcripts: Transcript[]) => void;
  addTranscript: (transcript: Transcript) => void;
  setCurrentTranscript: (transcript: Transcript | null) => void;
  setCurrentChunks: (chunks: TranscriptChunk[]) => void;
  appendChunk: (chunk: TranscriptChunk) => void;
  updateTranscript: (id: string, updates: Partial<Transcript>) => void;
  removeTranscript: (id: string) => void;
  setLoading: (loading: boolean) => void;
  reset: () => void;
}

export const useTranscriptStore = create<TranscriptStoreState>((set) => ({
  transcripts: [],
  currentTranscript: null,
  currentChunks: [],
  isLoading: false,

  setTranscripts: (transcripts) => set({ transcripts }),

  addTranscript: (transcript) =>
    set((state) => ({
      transcripts: [transcript, ...state.transcripts],
    })),

  setCurrentTranscript: (transcript) =>
    set({ currentTranscript: transcript }),

  setCurrentChunks: (chunks) => set({ currentChunks: chunks }),

  appendChunk: (chunk) =>
    set((state) => ({
      currentChunks: [...state.currentChunks, chunk],
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
      isLoading: false,
    }),
}));
