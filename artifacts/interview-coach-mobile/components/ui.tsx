import { Feather } from '@expo/vector-icons';
import React from 'react';
import { Pressable, StyleSheet, Text, TextInput, View, type TextInputProps, type ViewStyle } from 'react-native';
import { useColors } from '@/hooks/useColors';

export function Screen({ children, style, scroll = true }: { children: React.ReactNode; style?: ViewStyle; scroll?: boolean }) {
  const colors = useColors();
  const content = <View style={[styles.screen, { backgroundColor: colors.background }, style]}>{children}</View>;
  if (!scroll) return content;
  const { ScrollView } = require('react-native') as typeof import('react-native');
  return <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent} style={{ backgroundColor: colors.background }}>{children}</ScrollView>;
}

export function AppHeader({ title, subtitle, onBack, right }: { title: string; subtitle?: string; onBack?: () => void; right?: React.ReactNode }) {
  const colors = useColors();
  return (
    <View style={styles.header}>
      <View style={styles.headerSide}>
        {onBack ? <Pressable accessibilityLabel="Go back" onPress={onBack} style={styles.iconButton}><Feather name="arrow-left" size={20} color={colors.foreground} /></Pressable> : null}
      </View>
      <View style={styles.headerTitle}>
        <Text style={[styles.headerText, { color: colors.foreground }]}>{title}</Text>
        {subtitle ? <Text style={[styles.headerSubtitle, { color: colors.mutedForeground }]}>{subtitle}</Text> : null}
      </View>
      <View style={[styles.headerSide, styles.headerRight]}>{right}</View>
    </View>
  );
}

export function Button({ label, onPress, variant = 'primary', icon, disabled = false }: { label: string; onPress: () => void; variant?: 'primary' | 'secondary' | 'ghost'; icon?: keyof typeof Feather.glyphMap; disabled?: boolean }) {
  const colors = useColors();
  const backgroundColor = variant === 'primary' ? colors.primary : variant === 'secondary' ? colors.secondary : 'transparent';
  const textColor = variant === 'primary' ? colors.primaryForeground : colors.secondaryForeground;
  return (
    <Pressable accessibilityRole="button" disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.button, { backgroundColor, borderColor: colors.border, opacity: disabled ? 0.45 : pressed ? 0.78 : 1 }, variant === 'ghost' && styles.ghostButton]}>
      {icon ? <Feather name={icon} size={17} color={textColor} /> : null}
      <Text style={[styles.buttonText, { color: textColor }]}>{label}</Text>
    </Pressable>
  );
}

export function SectionTitle({ title, action, onAction }: { title: string; action?: string; onAction?: () => void }) {
  const colors = useColors();
  return <View style={styles.sectionTitle}><Text style={[styles.sectionText, { color: colors.foreground }]}>{title}</Text>{action ? <Pressable onPress={onAction}><Text style={[styles.actionText, { color: colors.primary }]}>{action}</Text></Pressable> : null}</View>;
}

export function Pill({ label, tone = 'muted' }: { label: string; tone?: 'muted' | 'success' | 'coral' | 'violet' }) {
  const colors = useColors();
  const palette = { muted: [colors.secondary, colors.secondaryForeground], success: [colors.accent, colors.accentForeground], coral: [colors.coral, colors.ink], violet: [colors.violet, colors.ink] } as const;
  const [backgroundColor, color] = palette[tone];
  return <View style={[styles.pill, { backgroundColor }]}><Text style={[styles.pillText, { color }]}>{label}</Text></View>;
}

export function ProgressBar({ value, color }: { value: number; color?: string }) {
  const colors = useColors();
  return <View style={[styles.progressTrack, { backgroundColor: colors.muted }]}><View style={[styles.progressFill, { width: `${Math.min(100, Math.max(0, value))}%`, backgroundColor: color ?? colors.primary }]} /></View>;
}

export function Stat({ label, value, change, icon }: { label: string; value: string; change?: string; icon: keyof typeof Feather.glyphMap }) {
  const colors = useColors();
  return <View style={[styles.stat, { backgroundColor: colors.card, borderColor: colors.border }]}><View style={[styles.statIcon, { backgroundColor: colors.secondary }]}><Feather name={icon} size={16} color={colors.primary} /></View><Text style={[styles.statValue, { color: colors.foreground }]}>{value}</Text><Text style={[styles.statLabel, { color: colors.mutedForeground }]}>{label}</Text>{change ? <Text style={[styles.statChange, { color: colors.success }]}>{change}</Text> : null}</View>;
}

export function ChoiceRow({ label, detail, selected, onPress, icon }: { label: string; detail?: string; selected: boolean; onPress: () => void; icon?: keyof typeof Feather.glyphMap }) {
  const colors = useColors();
  return <Pressable onPress={onPress} style={({ pressed }) => [styles.choiceRow, { backgroundColor: selected ? colors.secondary : colors.card, borderColor: selected ? colors.primary : colors.border, opacity: pressed ? 0.8 : 1 }]}>{icon ? <View style={[styles.choiceIcon, { backgroundColor: selected ? colors.primary : colors.muted }]}><Feather name={icon} size={17} color={selected ? colors.primaryForeground : colors.mutedForeground} /></View> : null}<View style={styles.choiceCopy}><Text style={[styles.choiceLabel, { color: colors.foreground }]}>{label}</Text>{detail ? <Text style={[styles.choiceDetail, { color: colors.mutedForeground }]}>{detail}</Text> : null}</View><View style={[styles.radio, { borderColor: selected ? colors.primary : colors.input }]}>{selected ? <View style={[styles.radioDot, { backgroundColor: colors.primary }]} /> : null}</View></Pressable>;
}

export function Field({ value, onChangeText, placeholder, multiline = false, ...props }: TextInputProps & { value: string; onChangeText: (value: string) => void }) {
  const colors = useColors();
  return <TextInput value={value} onChangeText={onChangeText} placeholderTextColor={colors.mutedForeground} placeholder={placeholder} multiline={multiline} style={[styles.field, { color: colors.foreground, backgroundColor: colors.card, borderColor: colors.input }, multiline && styles.multiline]} {...props} />;
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 20 },
  scrollContent: { paddingHorizontal: 20, paddingBottom: 120 },
  header: { flexDirection: 'row', alignItems: 'center', minHeight: 62, paddingVertical: 8 },
  headerSide: { width: 42, minHeight: 42, justifyContent: 'center' },
  headerRight: { alignItems: 'flex-end' },
  headerTitle: { flex: 1, alignItems: 'center' },
  headerText: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  headerSubtitle: { fontFamily: 'Inter_400Regular', fontSize: 11, marginTop: 3 },
  iconButton: { width: 42, height: 42, alignItems: 'center', justifyContent: 'center', borderRadius: 14 },
  button: { minHeight: 52, borderRadius: 16, paddingHorizontal: 18, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 9, borderWidth: 1 },
  ghostButton: { borderWidth: 0 },
  buttonText: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  sectionTitle: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, marginTop: 22 },
  sectionText: { fontFamily: 'Inter_700Bold', fontSize: 17 },
  actionText: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  pill: { paddingHorizontal: 9, paddingVertical: 5, borderRadius: 10, alignSelf: 'flex-start' },
  pillText: { fontFamily: 'Inter_600SemiBold', fontSize: 10 },
  progressTrack: { height: 6, borderRadius: 6, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 6 },
  stat: { width: '48%', minHeight: 116, borderRadius: 18, borderWidth: 1, padding: 14, marginBottom: 10 },
  statIcon: { width: 30, height: 30, borderRadius: 10, alignItems: 'center', justifyContent: 'center', marginBottom: 9 },
  statValue: { fontFamily: 'Inter_700Bold', fontSize: 22 },
  statLabel: { fontFamily: 'Inter_500Medium', fontSize: 11, marginTop: 3 },
  statChange: { fontFamily: 'Inter_600SemiBold', fontSize: 10, marginTop: 5 },
  choiceRow: { minHeight: 68, borderRadius: 17, borderWidth: 1, padding: 12, flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  choiceIcon: { width: 38, height: 38, borderRadius: 12, alignItems: 'center', justifyContent: 'center', marginRight: 11 },
  choiceCopy: { flex: 1 },
  choiceLabel: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  choiceDetail: { fontFamily: 'Inter_400Regular', fontSize: 11, marginTop: 3 },
  radio: { width: 21, height: 21, borderWidth: 1.5, borderRadius: 11, alignItems: 'center', justifyContent: 'center', marginLeft: 10 },
  radioDot: { width: 11, height: 11, borderRadius: 6 },
  field: { minHeight: 52, borderRadius: 16, borderWidth: 1, paddingHorizontal: 15, fontFamily: 'Inter_400Regular', fontSize: 14, marginBottom: 12 },
  multiline: { minHeight: 145, textAlignVertical: 'top', paddingTop: 15 },
});