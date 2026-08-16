import { Redirect } from 'expo-router';
import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { useApp } from '@/context/AppContext';
import { useColors } from '@/hooks/useColors';

export default function Entry() {
  const { onboardingComplete, authenticated } = useApp();
  const colors = useColors();
  if (!onboardingComplete) return <Redirect href="/onboarding" />;
  if (!authenticated) return <Redirect href="/login" />;
  return <Redirect href="/(tabs)" />;
}