import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Modal,
  SafeAreaView,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import {
  ArrowLeft,
  User,
  LogOut,
  Trash2,
  Globe,
  Cpu,
  FileText,
  HardDrive,
  Cloud,
  RefreshCw,
  Download,
  Sun,
  Moon,
  Monitor,
  Bell,
  Shield,
  HelpCircle,
  ChevronRight,
} from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { SettingsRow, SectionCard, ToggleSwitch } from '../../../../shared/components';
import { ScreenHeader } from '../../../../shared/components/ScreenHeader';
import { useColors, useTheme } from '../../../../shared/theme';
import { spacing, fontSize, borderRadius } from '../../../../shared/theme/tokens';
import { useSettingsStore } from '../../../../shared/stores/useSettingsStore';
import { useAuthStore } from '../../../../shared/stores/useAuthStore';
import { useTranslation, useI18n } from '../../../../shared/i18n';

export const SettingsScreen: React.FC = () => {
  const colors = useColors();
  const { mode, setMode } = useTheme();
  const settingsStore = useSettingsStore();
  const { user, clearAuth } = useAuthStore();
  const navigation = useNavigation<any>();
  const t = useTranslation();
  const { locale, setLocale } = useI18n();
  const [showThemeModal, setShowThemeModal] = useState(false);
  const [showLanguageModal, setShowLanguageModal] = useState(false);

  const handleLogout = () => {
    clearAuth();
  };

  const handleDeleteAccount = () => {
    // TODO: Implement delete account logic
  };

  const handleManualSync = () => {
    // TODO: Implement manual sync logic
  };

  const getThemeIcon = () => {
    switch (mode) {
      case 'light':
        return <Sun size={20} color={colors.text} />;
      case 'dark':
        return <Moon size={20} color={colors.text} />;
      default:
        return <Monitor size={20} color={colors.text} />;
    }
  };

  const getThemeText = () => {
    switch (mode) {
      case 'light':
        return t.themeLight;
      case 'dark':
        return t.themeDark;
      default:
        return t.themeSystem;
    }
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <View style={[styles.header, { backgroundColor: colors.background }]}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={colors.text} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.text }]}>{t.settings}</Text>
        <View style={styles.backButton} />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Profil Section */}
        <SectionCard title={t.profile}>
          <View style={styles.profileCard}>
            <View style={styles.profileAvatar}>
              <User size={32} color="#ffffff" />
            </View>
            <View style={styles.profileInfo}>
              <Text style={[styles.profileName, { color: colors.text }]}>
                {user?.name || t.profile}
              </Text>
              <Text style={[styles.profileEmail, { color: colors.textSecondary }]}>
                {user?.email || ''}
              </Text>
            </View>
          </View>
          <SettingsRow
            icon={<LogOut size={20} color={colors.error} />}
            title={t.logout}
            onPress={handleLogout}
            danger
          />
          <SettingsRow
            icon={<Trash2 size={20} color={colors.error} />}
            title={t.deleteAccount}
            onPress={handleDeleteAccount}
            danger
          />
        </SectionCard>

        {/* Transkripsiyon Section */}
        <SectionCard title={t.transcription}>
          <SettingsRow
            icon={<Globe size={20} color={colors.text} />}
            title={t.language}
            subtitle="Türkçe"
            showChevron
          />
          <SettingsRow
            icon={<Cpu size={20} color={colors.text} />}
            title={t.model}
            subtitle={settingsStore.whisperModel === 'base' ? 'Base' : 'Tiny'}
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title={t.autoTranscription}
            subtitle={t.autoTranscriptionDesc}
            rightElement={
              <ToggleSwitch
                value={false}
                onValueChange={() => {}}
              />
            }
          />
        </SectionCard>

        {/* Özetleme Section */}
        <SectionCard title={t.summarization}>
          <SettingsRow
            icon={<HardDrive size={20} color={colors.text} />}
            title={t.localSummary}
            subtitle={t.localSummaryDesc}
            rightElement={
              <ToggleSwitch
                value={false}
                onValueChange={() => {}}
              />
            }
          />
          <SettingsRow
            icon={<Cloud size={20} color={colors.text} />}
            title={t.cloudSummary}
            subtitle={t.cloudSummaryDesc}
            rightElement={
              <ToggleSwitch
                value={settingsStore.cloudSummarizationEnabled}
                onValueChange={settingsStore.setCloudSummarization}
              />
            }
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title={t.defaultSummaryLength}
            subtitle={t.medium}
            showChevron
          />
          <SettingsRow
            icon={<Cpu size={20} color={colors.text} />}
            title="LLM Provider"
            subtitle="OpenAI GPT-4"
            showChevron
          />
        </SectionCard>

        {/* Senkronizasyon Section */}
        <SectionCard title={t.sync}>
          <SettingsRow
            icon={<RefreshCw size={20} color={colors.text} />}
            title={t.autoSync}
            subtitle={t.autoSyncDesc}
            rightElement={
              <ToggleSwitch
                value={settingsStore.syncEnabled}
                onValueChange={settingsStore.setSyncEnabled}
              />
            }
          />
          <SettingsRow
            icon={<Cloud size={20} color={colors.text} />}
            title={t.manualSync}
            rightElement={<RefreshCw size={20} color={colors.primary} />}
            onPress={handleManualSync}
          />
        </SectionCard>

        {/* Uygulama Section */}
        <SectionCard title={t.app}>
          <SettingsRow
            icon={getThemeIcon()}
            title={t.theme}
            subtitle={getThemeText()}
            onPress={() => setShowThemeModal(true)}
            showChevron
          />
          <SettingsRow
            icon={<Globe size={20} color={colors.text} />}
            title={t.appLanguage}
            subtitle={locale === 'tr' ? 'Türkçe' : 'English'}
            onPress={() => setShowLanguageModal(true)}
            showChevron
          />
          <SettingsRow
            icon={<Bell size={20} color={colors.text} />}
            title={t.notifications}
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title={t.version}
            subtitle="1.0.0"
          />
        </SectionCard>

        {/* Hakkında Section */}
        <SectionCard title={t.about}>
          <SettingsRow
            icon={<Shield size={20} color={colors.text} />}
            title={t.privacyPolicy}
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title={t.termsOfUse}
            showChevron
          />
          <SettingsRow
            icon={<HelpCircle size={20} color={colors.text} />}
            title={t.helpSupport}
            showChevron
          />
        </SectionCard>
      </ScrollView>

      {/* Theme Selection Modal */}
      <Modal
        visible={showThemeModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowThemeModal(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowThemeModal(false)}
        >
          <View style={[styles.modalContent, { backgroundColor: colors.surface }]}>
            <Text style={[styles.modalTitle, { color: colors.text }]}>
              {t.selectTheme}
            </Text>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => { setMode('light'); setShowThemeModal(false); }}
            >
              <Sun size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>{t.themeLight}</Text>
              {mode === 'light' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => { setMode('dark'); setShowThemeModal(false); }}
            >
              <Moon size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>{t.themeDark}</Text>
              {mode === 'dark' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => { setMode('system'); setShowThemeModal(false); }}
            >
              <Monitor size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>{t.themeSystem}</Text>
              {mode === 'system' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>

      {/* Language Selection Modal */}
      <Modal
        visible={showLanguageModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowLanguageModal(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowLanguageModal(false)}
        >
          <View style={[styles.modalContent, { backgroundColor: colors.surface }]}>
            <Text style={[styles.modalTitle, { color: colors.text }]}>
              {t.appLanguage}
            </Text>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => { setLocale('tr'); setShowLanguageModal(false); }}
            >
              <Text style={styles.flagEmoji}>🇹🇷</Text>
              <Text style={[styles.themeOptionText, { color: colors.text }]}>Türkçe</Text>
              {locale === 'tr' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => { setLocale('en'); setShowLanguageModal(false); }}
            >
              <Text style={styles.flagEmoji}>🇬🇧</Text>
              <Text style={[styles.themeOptionText, { color: colors.text }]}>English</Text>
              {locale === 'en' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    height: 60,
  },
  backButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: fontSize.xl,
    fontWeight: '600',
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: spacing.md,
    paddingBottom: 100,
  },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    gap: spacing.md,
  },
  profileAvatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#db2777',
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    marginBottom: 2,
  },
  profileEmail: {
    fontSize: fontSize.sm,
  },
  storageSection: {
    padding: spacing.md,
    gap: spacing.sm,
  },
  storageHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  storageLabel: {
    fontSize: fontSize.md,
    fontWeight: '500',
  },
  storageValue: {
    fontSize: fontSize.sm,
  },
  progressBarContainer: {
    marginTop: spacing.xs,
  },
  progressBarBg: {
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 4,
    backgroundColor: '#db2777',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    borderTopLeftRadius: borderRadius.xxl,
    borderTopRightRadius: borderRadius.xxl,
    padding: spacing.lg,
    paddingBottom: spacing.xxl,
  },
  modalTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    marginBottom: spacing.lg,
    textAlign: 'center',
  },
  themeOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.md,
    borderRadius: borderRadius.md,
  },
  themeOptionText: {
    fontSize: fontSize.md,
    flex: 1,
  },
  flagEmoji: {
    fontSize: 24,
  },
});