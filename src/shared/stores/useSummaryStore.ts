import { create } from 'zustand';
import type { Summary } from '../types';

interface SummaryStoreState {
  summaries: Summary[];
  currentSummary: Summary | null;
  isGenerating: boolean;
  preferLocal: boolean;

  setSummaries: (summaries: Summary[]) => void;
  addSummary: (summary: Summary) => void;
  setCurrentSummary: (summary: Summary | null) => void;
  setGenerating: (generating: boolean) => void;
  setPreferLocal: (preferLocal: boolean) => void;
  reset: () => void;
}

export const useSummaryStore = create<SummaryStoreState>((set) => ({
  summaries: [],
  currentSummary: null,
  isGenerating: false,
  preferLocal: true,

  setSummaries: (summaries) => set({ summaries }),

  addSummary: (summary) =>
    set((state) => ({
      summaries: [summary, ...state.summaries],
    })),

  setCurrentSummary: (summary) => set({ currentSummary: summary }),

  setGenerating: (generating) => set({ isGenerating: generating }),

  setPreferLocal: (preferLocal) => set({ preferLocal }),

  reset: () =>
    set({
      summaries: [],
      currentSummary: null,
      isGenerating: false,
      preferLocal: true,
    }),
}));
