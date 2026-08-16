import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { AppHeader, Button, Field } from '@/components/ui';
import { useColors } from '@/hooks/useColors';

export default function ForgotPassword() {
  const colors = useColors();
  const [email, setEmail] = useState('meraj.khan@email.com');
  const [sent, setSent] = useState(false);
  return <View style={[styles.container, { backgroundColor: colors.background }]}><AppHeader title="Reset password" onBack={() => router.back()} />{sent ? <View style={styles.sent}><View style={[styles.sentIcon, { backgroundColor: colors.accent }]}><Feather name="mail" size={25} color={colors.accentForeground} /></View><Text style={[styles.title, { color: colors.foreground }]}>Check your inbox</Text><Text style={[styles.body, { color: colors.mutedForeground }]}>We sent a reset link to {email}. It will be valid for 30 minutes.</Text><Button label="Back to sign in" onPress={() => router.replace('/login')} icon="arrow-right" /></View> : <><View style={styles.copy}><Text style={[styles.title, { color: colors.foreground }]}>Forgot your password?</Text><Text style={[styles.body, { color: colors.mutedForeground }]}>No problem. Enter the email you use for Interview Coach and we’ll send a secure reset link.</Text></View><Text style={[styles.label, { color: colors.foreground }]}>Email address</Text><Field value={email} onChangeText={setEmail} placeholder="you@example.com" keyboardType="email-address" autoCapitalize="none" /><Button label="Send reset link" icon="send" onPress={() => setSent(true)} /><Pressable onPress={() => router.back()} style={styles.back}><Text style={[styles.backText, { color: colors.primary }]}>Remembered your password? Sign in</Text></Pressable></>}</View>;
}
const styles = StyleSheet.create({ container: { flex: 1, paddingHorizontal: 24 }, copy: { marginTop: 62, marginBottom: 29 }, title: { fontFamily: 'Inter_700Bold', fontSize: 29, lineHeight: 36 }, body: { fontFamily: 'Inter_400Regular', fontSize: 14, lineHeight: 21, marginTop: 11 }, label: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginBottom: 8 }, back: { alignItems: 'center', marginTop: 24 }, backText: { fontFamily: 'Inter_600SemiBold', fontSize: 12 }, sent: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingBottom: 100 }, sentIcon: { width: 70, height: 70, borderRadius: 24, alignItems: 'center', justifyContent: 'center', marginBottom: 22 } });