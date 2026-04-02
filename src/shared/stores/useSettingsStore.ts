import { create } from 'zustand';

interface SettingsStoreState {
  cloudSummarizationEnabled: boolean;
  syncEnabled: boolean;
  whisperModel: 'tiny' | 'base';
  chunkDurationSeconds: number;
  darkMode: boolean;
  locale: 'en' | 'tr';

  setCloudSummarization: (enabled: boolean) => void;
  setSyncEnabled: (enabled: boolean) => void;
  setWhisperModel: (model: 'tiny' | 'base') => void;
  setChunkDuration: (seconds: number) => void;
  setDarkMode: (enabled: boolean) => void;
  setLocale: (locale: 'en' | 'tr') => void;
  reset: () => void;
}

export const useSettingsStore = create<SettingsStoreState>((set) => ({
  cloudSummarizationEnabled: false,
  syncEnabled: false,
  whisperModel: 'tiny',
  chunkDurationSeconds: 10,
  darkMode: true,
  locale: 'en',

  setCloudSummarization: (enabled) =>
    set({ cloudSummarizationEnabled: enabled }),

  setSyncEnabled: (enabled) => set({ syncEnabled: enabled }),

  setWhisperModel: (model) => set({ whisperModel: model }),

  setChunkDuration: (seconds) => set({ chunkDurationSeconds: seconds }),

  setDarkMode: (enabled) => set({ darkMode: enabled }),

  setLocale: (locale) => set({ locale }),

  reset: () =>
    set({
      cloudSummarizationEnabled: false,
      syncEnabled: false,
      whisperModel: 'tiny',
      chunkDurationSeconds: 10,
      darkMode: true,
      locale: 'en',
    }),
}));
