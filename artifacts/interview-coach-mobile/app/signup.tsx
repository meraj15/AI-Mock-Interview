import { router } from 'expo-router';
import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { AppHeader, Button, Field } from '@/components/ui';
import { useApp } from '@/context/AppContext';
import { useColors } from '@/hooks/useColors';

export default function Signup() {
  const colors = useColors();
  const { signIn } = useApp();
  const [name, setName] = useState('Meraj Khan');
  const [email, setEmail] = useState('meraj.khan@email.com');
  const submit = () => { signIn(); router.replace('/(tabs)'); };
  return <View style={[styles.container, { backgroundColor: colors.background }]}><AppHeader title="Create account" onBack={() => router.back()} /><View style={styles.copy}><Text style={[styles.title, { color: colors.foreground }]}>Build your edge</Text><Text style={[styles.subtitle, { color: colors.mutedForeground }]}>A few details and we’ll tailor every practice session to you.</Text></View><Text style={[styles.label, { color: colors.foreground }]}>Your name</Text><Field value={name} onChangeText={setName} placeholder="Full name" /><Text style={[styles.label, { color: colors.foreground }]}>Email address</Text><Field value={email} onChangeText={setEmail} placeholder="you@example.com" keyboardType="email-address" /><Text style={[styles.label, { color: colors.foreground }]}>Password</Text><Field value="password" onChangeText={() => {}} placeholder="Create a password" secureTextEntry /><View style={styles.spacer} /><Button label="Create my account" onPress={submit} icon="arrow-right" /></View>;
}
const styles = StyleSheet.create({ container: { flex: 1, paddingHorizontal: 24 }, copy: { marginTop: 48, marginBottom: 30 }, title: { fontFamily: 'Inter_700Bold', fontSize: 31 }, subtitle: { fontFamily: 'Inter_400Regular', fontSize: 14, lineHeight: 21, marginTop: 9 }, label: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginBottom: 8 }, spacer: { flex: 1 } });