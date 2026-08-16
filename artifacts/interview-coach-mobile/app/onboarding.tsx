import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import React, { useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Button } from '@/components/ui';
import { useApp } from '@/context/AppContext';
import { useColors } from '@/hooks/useColors';

const slides = [
  { icon: 'message-circle' as const, title: 'Practice interviews with AI', body: 'Build the confidence to speak clearly, think deeply, and show up ready for the room.' },
  { icon: 'file-text' as const, title: 'Make every question relevant', body: 'Practice against your resume, target role, experience level, and the kind of interview you want.' },
  { icon: 'trending-up' as const, title: 'Know exactly what to improve', body: 'Get a clear score, thoughtful feedback, and a next-step plan after every session.' },
];

export default function Onboarding() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { completeOnboarding } = useApp();
  const [index, setIndex] = useState(0);
  const slide = slides[index];
  const finish = () => { completeOnboarding(); router.replace('/login'); };
  return <View style={[styles.container, { backgroundColor: colors.navy, paddingTop: insets.top + 20, paddingBottom: insets.bottom + 18 }]}>
    <View style={styles.top}><View style={styles.logoMark}><Image source={require('../assets/images/icon.png')} style={styles.logoImage} /></View><Pressable onPress={finish}><Text style={styles.skip}>Skip</Text></Pressable></View>
    <View style={styles.illustration}><View style={[styles.glow, { backgroundColor: colors.mint }]} /><View style={[styles.illustrationCard, { backgroundColor: colors.card }]}><View style={[styles.illustrationIcon, { backgroundColor: colors.accent }]}><Feather name={slide.icon} size={32} color={colors.accentForeground} /></View><View style={[styles.fakeLine, { backgroundColor: colors.border, width: '68%' }]} /><View style={[styles.fakeLine, { backgroundColor: colors.border, width: '48%' }]} /><View style={[styles.fakeLine, { backgroundColor: colors.secondary, width: '84%', marginTop: 18 }]} /><View style={[styles.fakeLine, { backgroundColor: colors.secondary, width: '58%' }]} /></View></View>
    <View style={styles.copy}><Text style={styles.eyebrow}>INTERVIEW COACH</Text><Text style={styles.title}>{slide.title}</Text><Text style={styles.body}>{slide.body}</Text></View>
    <View style={styles.footer}><View style={styles.dots}>{slides.map((_, item) => <View key={item} style={[styles.dot, { backgroundColor: item === index ? colors.mint : 'rgba(255,255,255,0.25)', width: item === index ? 24 : 7 }]} />)}</View><Button label={index === slides.length - 1 ? 'Get started' : 'Continue'} icon="arrow-right" onPress={() => index === slides.length - 1 ? finish() : setIndex(index + 1)} /></View>
  </View>;
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: 24 },
  top: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  logoMark: { width: 48, height: 48, borderRadius: 16, overflow: 'hidden' },
  logoImage: { width: 48, height: 48 },
  skip: { color: '#C9D5F0', fontFamily: 'Inter_600SemiBold', fontSize: 13 },
  illustration: { flex: 1, alignItems: 'center', justifyContent: 'center', minHeight: 330 },
  glow: { position: 'absolute', width: 220, height: 220, borderRadius: 110, opacity: 0.2 },
  illustrationCard: { width: '82%', minHeight: 240, borderRadius: 28, padding: 24, transform: [{ rotate: '-3deg' }], shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 20, shadowOffset: { width: 0, height: 10 }, elevation: 7 },
  illustrationIcon: { width: 70, height: 70, borderRadius: 22, alignItems: 'center', justifyContent: 'center', marginBottom: 28 },
  fakeLine: { height: 10, borderRadius: 8, marginBottom: 10 },
  copy: { marginBottom: 30 },
  eyebrow: { color: '#9DE7C8', fontFamily: 'Inter_700Bold', letterSpacing: 1.6, fontSize: 11, marginBottom: 14 },
  title: { color: '#FFFFFF', fontFamily: 'Inter_700Bold', fontSize: 34, lineHeight: 40, maxWidth: 330 },
  body: { color: '#C9D5F0', fontFamily: 'Inter_400Regular', fontSize: 15, lineHeight: 23, marginTop: 14, maxWidth: 330 },
  footer: { gap: 20 },
  dots: { flexDirection: 'row', gap: 7, alignItems: 'center' },
  dot: { height: 7, borderRadius: 4 },
});