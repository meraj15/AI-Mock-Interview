import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import React, { useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { Button, Field } from '@/components/ui';
import { useApp } from '@/context/AppContext';
import { useColors } from '@/hooks/useColors';

export default function Login() {
  const colors = useColors();
  const { signIn } = useApp();
  const [email, setEmail] = useState('meraj.khan@email.com');
  const [password, setPassword] = useState('password');
  const submit = () => { signIn(); router.replace('/(tabs)'); };
  return <View style={[styles.container, { backgroundColor: colors.background }]}>
    <View style={styles.brand}><Image source={require('../assets/images/icon.png')} style={styles.logo} /><Text style={[styles.brandName, { color: colors.foreground }]}>Interview Coach</Text></View>
    <View style={styles.copy}><Text style={[styles.title, { color: colors.foreground }]}>Welcome back</Text><Text style={[styles.subtitle, { color: colors.mutedForeground }]}>Your next great interview starts with one good answer.</Text></View>
    <View><Text style={[styles.label, { color: colors.foreground }]}>Email address</Text><Field value={email} onChangeText={setEmail} placeholder="you@example.com" keyboardType="email-address" autoCapitalize="none" /><Text style={[styles.label, { color: colors.foreground }]}>Password</Text><Field value={password} onChangeText={setPassword} placeholder="Your password" secureTextEntry /><Pressable style={styles.forgot} onPress={() => router.push('/forgot-password')}><Text style={[styles.forgotText, { color: colors.primary }]}>Forgot password?</Text></Pressable><Button label="Sign in" onPress={submit} icon="arrow-right" /></View>
    <View style={styles.divider}><View style={[styles.line, { backgroundColor: colors.border }]} /><Text style={[styles.or, { color: colors.mutedForeground }]}>or continue with</Text><View style={[styles.line, { backgroundColor: colors.border }]} /></View>
    <View style={styles.socialRow}><Pressable style={[styles.social, { backgroundColor: colors.card, borderColor: colors.border }]} onPress={submit}><Feather name="chrome" size={17} color={colors.foreground} /><Text style={[styles.socialText, { color: colors.foreground }]}>Google</Text></Pressable><Pressable style={[styles.social, { backgroundColor: colors.card, borderColor: colors.border }]} onPress={submit}><Feather name="smartphone" size={17} color={colors.foreground} /><Text style={[styles.socialText, { color: colors.foreground }]}>Apple</Text></Pressable></View>
    <View style={styles.bottom}><Text style={[styles.bottomText, { color: colors.mutedForeground }]}>New here?</Text><Pressable onPress={() => router.push('/signup')}><Text style={[styles.bottomLink, { color: colors.primary }]}> Create an account</Text></Pressable></View>
  </View>;
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: 24, paddingTop: 70, paddingBottom: 24 },
  brand: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  logo: { width: 38, height: 38, borderRadius: 12 },
  brandName: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  copy: { marginTop: 66, marginBottom: 32 },
  title: { fontFamily: 'Inter_700Bold', fontSize: 32 },
  subtitle: { fontFamily: 'Inter_400Regular', fontSize: 14, lineHeight: 21, marginTop: 9, maxWidth: 290 },
  label: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginBottom: 8 },
  forgot: { alignSelf: 'flex-end', marginBottom: 22, marginTop: 0 },
  forgotText: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  divider: { flexDirection: 'row', alignItems: 'center', gap: 10, marginVertical: 26 },
  line: { height: 1, flex: 1 },
  or: { fontFamily: 'Inter_400Regular', fontSize: 11 },
  socialRow: { flexDirection: 'row', gap: 10 },
  social: { flex: 1, height: 50, borderRadius: 15, borderWidth: 1, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 8 },
  socialText: { fontFamily: 'Inter_600SemiBold', fontSize: 13 },
  bottom: { flexDirection: 'row', justifyContent: 'center', marginTop: 'auto' },
  bottomText: { fontFamily: 'Inter_400Regular', fontSize: 13 },
  bottomLink: { fontFamily: 'Inter_600SemiBold', fontSize: 13 },
});