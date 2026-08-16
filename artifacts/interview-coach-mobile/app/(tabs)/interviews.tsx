import { Feather } from '@expo/vector-icons';
import React, { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { AppHeader, Pill, Screen, SectionTitle } from '@/components/ui';
import { useColors } from '@/hooks/useColors';

const data = [
  { role: 'Flutter Developer', type: 'Technical interview', date: 'Aug 11, 2026', score: '82', tone: 'success' as const, icon: 'code' as const },
  { role: 'Product Designer', type: 'Portfolio review', date: 'Aug 07, 2026', score: '76', tone: 'violet' as const, icon: 'pen-tool' as const },
  { role: 'Frontend Engineer', type: 'Behavioral interview', date: 'Aug 02, 2026', score: '88', tone: 'coral' as const, icon: 'layout' as const },
  { role: 'Flutter Developer', type: 'System design', date: 'Jul 28, 2026', score: '69', tone: 'muted' as const, icon: 'layers' as const },
];

export default function Interviews() {
  const colors = useColors();
  const [filter, setFilter] = useState('All');
  const filtered = useMemo(() => filter === 'All' ? data : data.filter((item) => item.type.toLowerCase().includes(filter.toLowerCase())), [filter]);
  return <Screen><AppHeader title="My interviews" subtitle="Your practice, over time" right={<Pressable><Feather name="search" size={20} color={colors.foreground} /></Pressable>} /><SectionTitle title="12 completed" action="Newest" /><View style={styles.filters}>{['All', 'Technical', 'Behavioral', 'System'].map((item) => <Pressable key={item} onPress={() => setFilter(item)} style={[styles.filter, { backgroundColor: filter === item ? colors.primary : colors.secondary }]}><Text style={[styles.filterText, { color: filter === item ? colors.primaryForeground : colors.secondaryForeground }]}>{item}</Text></Pressable>)}</View>{filtered.map((item) => <View key={`${item.role}-${item.date}`} style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}><View style={[styles.icon, { backgroundColor: colors.secondary }]}><Feather name={item.icon} size={18} color={colors.primary} /></View><View style={styles.copy}><Text style={[styles.role, { color: colors.foreground }]}>{item.role}</Text><Text style={[styles.meta, { color: colors.mutedForeground }]}>{item.type} · {item.date}</Text><Pill label={item.score === '88' ? 'Strong performance' : item.score === '69' ? 'Keep practicing' : 'Good progress'} tone={item.tone} /></View><View style={styles.score}><Text style={[styles.scoreText, { color: colors.foreground }]}>{item.score}</Text><Text style={[styles.outOf, { color: colors.mutedForeground }]}>/100</Text><Feather name="chevron-right" size={16} color={colors.mutedForeground} /></View></View>)}</Screen>;
}
const styles = StyleSheet.create({ filters: { flexDirection: 'row', gap: 8, marginBottom: 18 }, filter: { paddingHorizontal: 13, paddingVertical: 8, borderRadius: 12 }, filterText: { fontFamily: 'Inter_600SemiBold', fontSize: 11 }, row: { borderRadius: 18, borderWidth: 1, padding: 13, flexDirection: 'row', marginBottom: 10 }, icon: { width: 42, height: 42, borderRadius: 14, alignItems: 'center', justifyContent: 'center' }, copy: { flex: 1, marginLeft: 11 }, role: { fontFamily: 'Inter_600SemiBold', fontSize: 14 }, meta: { fontFamily: 'Inter_400Regular', fontSize: 10, marginTop: 4, marginBottom: 8 }, score: { alignItems: 'flex-end', gap: 2 }, scoreText: { fontFamily: 'Inter_700Bold', fontSize: 20 }, outOf: { fontFamily: 'Inter_400Regular', fontSize: 9 } });