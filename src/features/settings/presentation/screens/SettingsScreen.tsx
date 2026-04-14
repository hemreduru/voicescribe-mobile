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
import { useColors, useTheme } from '../../../../shared/theme';
import { spacing, fontSize, borderRadius } from '../../../../shared/theme/tokens';
import { useSettingsStore } from '../../../../shared/stores/useSettingsStore';
import { useAuthStore } from '../../../../shared/stores/useAuthStore';

export const SettingsScreen: React.FC = () => {
  const colors = useColors();
  const { mode, setMode } = useTheme();
  const insets = useSafeAreaInsets();
  const { user, clearAuth } = useAuthStore();
  const settingsStore = useSettingsStore();
  const [showThemeModal, setShowThemeModal] = useState(false);

  const handleLogout = () => {
    clearAuth();
  };

  const handleDeleteAccount = () => {
    // TODO: Implement delete account logic
  };

  const handleManualSync = () => {
    // TODO: Implement manual sync logic
  };

  const handleClearCache = () => {
    // TODO: Implement clear cache logic
  };

  const handleExportData = () => {
    // TODO: Implement export data logic
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
        return 'Açık';
      case 'dark':
        return 'Koyu';
      default:
        return 'Sistem';
    }
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <View style={[styles.header, { backgroundColor: colors.background }]}>
        <TouchableOpacity style={styles.backButton}>
          <ArrowLeft size={24} color={colors.text} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.text }]}>Ayarlar</Text>
        <View style={styles.backButton} />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Profil Section */}
        <SectionCard title="Profil">
          <View style={styles.profileCard}>
            <View style={styles.profileAvatar}>
              <User size={32} color="#ffffff" />
            </View>
            <View style={styles.profileInfo}>
              <Text style={[styles.profileName, { color: colors.text }]}>
                {user?.name || 'Ahmet Yılmaz'}
              </Text>
              <Text style={[styles.profileEmail, { color: colors.textSecondary }]}>
                {user?.email || 'ahmet@example.com'}
              </Text>
            </View>
          </View>
          <SettingsRow
            icon={<LogOut size={20} color={colors.error} />}
            title="Çıkış Yap"
            onPress={handleLogout}
            danger
          />
          <SettingsRow
            icon={<Trash2 size={20} color={colors.error} />}
            title="Hesabı Sil"
            onPress={handleDeleteAccount}
            danger
          />
        </SectionCard>

        {/* Transkripsiyon Section */}
        <SectionCard title="Transkripsiyon">
          <SettingsRow
            icon={<Globe size={20} color={colors.text} />}
            title="Dil"
            subtitle="Türkçe"
            showChevron
          />
          <SettingsRow
            icon={<Cpu size={20} color={colors.text} />}
            title="Model"
            subtitle={settingsStore.whisperModel === 'base' ? 'Base' : 'Tiny'}
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title="Otomatik Transkripsiyon"
            subtitle="Kayıt sonrası otomatik başlat"
            rightElement={
              <ToggleSwitch
                value={false}
                onValueChange={() => {}}
              />
            }
          />
        </SectionCard>

        {/* Özetleme Section */}
        <SectionCard title="Özetleme">
          <SettingsRow
            icon={<HardDrive size={20} color={colors.text} />}
            title="Yerel Özet"
            subtitle="Cihazda AI ile oluştur"
            rightElement={
              <ToggleSwitch
                value={false}
                onValueChange={() => {}}
              />
            }
          />
          <SettingsRow
            icon={<Cloud size={20} color={colors.text} />}
            title="Cloud Özet"
            subtitle="Bulut AI ile oluştur"
            rightElement={
              <ToggleSwitch
                value={settingsStore.cloudSummarizationEnabled}
                onValueChange={settingsStore.setCloudSummarization}
              />
            }
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title="Varsayılan Özet Uzunluğu"
            subtitle="Orta"
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
        <SectionCard title="Senkronizasyon">
          <SettingsRow
            icon={<RefreshCw size={20} color={colors.text} />}
            title="Otomatik Sync"
            subtitle="Kayıtları otomatik senkronize et"
            rightElement={
              <ToggleSwitch
                value={settingsStore.syncEnabled}
                onValueChange={settingsStore.setSyncEnabled}
              />
            }
          />
          <SettingsRow
            icon={<Cloud size={20} color={colors.text} />}
            title="Manuel Sync"
            subtitle="Son sync: 2 saat önce"
            rightElement={<RefreshCw size={20} color={colors.primary} />}
            onPress={handleManualSync}
          />
        </SectionCard>

        {/* Depolama Section */}
        <SectionCard title="Depolama">
          <View style={styles.storageSection}>
            <View style={styles.storageHeader}>
              <Text style={[styles.storageLabel, { color: colors.text }]}>
                Kullanılan Depolama
              </Text>
              <Text style={[styles.storageValue, { color: colors.textSecondary }]}>
                2.4 GB / 10 GB
              </Text>
            </View>
            <View style={styles.progressBarContainer}>
              <View style={[styles.progressBarBg, { backgroundColor: colors.border }]}>
                <View style={[styles.progressBarFill, { width: '24%' }]} />
              </View>
            </View>
          </View>
          <SettingsRow
            icon={<Trash2 size={20} color={colors.text} />}
            title="Önbelleği Temizle"
            onPress={handleClearCache}
          />
          <SettingsRow
            icon={<Download size={20} color={colors.text} />}
            title="Verileri Dışa Aktar"
            onPress={handleExportData}
          />
        </SectionCard>

        {/* Uygulama Section */}
        <SectionCard title="Uygulama">
          <SettingsRow
            icon={getThemeIcon()}
            title="Tema"
            subtitle={getThemeText()}
            onPress={() => setShowThemeModal(true)}
            showChevron
          />
          <SettingsRow
            icon={<Globe size={20} color={colors.text} />}
            title="Dil"
            subtitle="Türkçe"
            showChevron
          />
          <SettingsRow
            icon={<Bell size={20} color={colors.text} />}
            title="Bildirimler"
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title="Versiyon"
            subtitle="1.0.0"
          />
        </SectionCard>

        {/* Hakkında Section */}
        <SectionCard title="Hakkında">
          <SettingsRow
            icon={<Shield size={20} color={colors.text} />}
            title="Gizlilik Politikası"
            showChevron
          />
          <SettingsRow
            icon={<FileText size={20} color={colors.text} />}
            title="Kullanım Koşulları"
            showChevron
          />
          <SettingsRow
            icon={<HelpCircle size={20} color={colors.text} />}
            title="Yardım & Destek"
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
              Tema Seçin
            </Text>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => {
                setMode('light');
                setShowThemeModal(false);
              }}
            >
              <Sun size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>
                Açık
              </Text>
              {mode === 'light' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => {
                setMode('dark');
                setShowThemeModal(false);
              }}
            >
              <Moon size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>
                Koyu
              </Text>
              {mode === 'dark' && <ChevronRight size={20} color={colors.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.themeOption}
              onPress={() => {
                setMode('system');
                setShowThemeModal(false);
              }}
            >
              <Monitor size={20} color={colors.text} />
              <Text style={[styles.themeOptionText, { color: colors.text }]}>
                Sistem
              </Text>
              {mode === 'system' && <ChevronRight size={20} color={colors.primary} />}
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
});