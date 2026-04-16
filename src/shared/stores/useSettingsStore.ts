import { create } from 'zustand';

type ThemeMode = 'light' | 'dark' | 'system';

interface SettingsStoreState {
  cloudSummarizationEnabled: boolean;
  syncEnabled: boolean;
  whisperModel: 'tiny' | 'base';
  chunkDurationSeconds: number;
  darkMode: boolean;
  themeMode: ThemeMode;
  locale: 'en' | 'tr';

  setCloudSummarization: (enabled: boolean) => void;
  setSyncEnabled: (enabled: boolean) => void;
  setWhisperModel: (model: 'tiny' | 'base') => void;
  setChunkDuration: (seconds: number) => void;
  setDarkMode: (enabled: boolean) => void;
  setThemeMode: (mode: ThemeMode) => void;
  setLocale: (locale: 'en' | 'tr') => void;
  reset: () => void;
}

export const useSettingsStore = create<SettingsStoreState>((set) => ({
  cloudSummarizationEnabled: false,
  syncEnabled: false,
  whisperModel: 'tiny',
  chunkDurationSeconds: 10,
  darkMode: false,
  themeMode: 'system',
  locale: 'tr',

  setCloudSummarization: (enabled) =>
    set({ cloudSummarizationEnabled: enabled }),

  setSyncEnabled: (enabled) => set({ syncEnabled: enabled }),

  setWhisperModel: (model) => set({ whisperModel: model }),

  setChunkDuration: (seconds) => set({ chunkDurationSeconds: seconds }),

  setDarkMode: (enabled) => set({ darkMode: enabled }),

  setThemeMode: (mode) => set({ themeMode: mode }),

  setLocale: (locale) => set({ locale }),

  reset: () =>
    set({
      cloudSummarizationEnabled: false,
      syncEnabled: false,
      whisperModel: 'tiny',
      chunkDurationSeconds: 10,
      darkMode: false,
      themeMode: 'system',
      locale: 'tr',
    }),
}));
