import { Feather } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import React from 'react';
import { useColors } from '@/hooks/useColors';

export default function TabLayout() {
  const colors = useColors();
  return <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: colors.primary, tabBarInactiveTintColor: colors.mutedForeground, tabBarStyle: { backgroundColor: colors.card, borderTopColor: colors.border, height: 78, paddingBottom: 12, paddingTop: 8 }, tabBarLabelStyle: { fontFamily: 'Inter_600SemiBold', fontSize: 10 } }}>
    <Tabs.Screen name="index" options={{ title: 'Home', tabBarIcon: ({ color }) => <Feather name="home" size={20} color={color} /> }} />
    <Tabs.Screen name="interviews" options={{ title: 'Interviews', tabBarIcon: ({ color }) => <Feather name="layers" size={20} color={color} /> }} />
    <Tabs.Screen name="practice" options={{ title: 'Practice', tabBarIcon: ({ color }) => <Feather name="target" size={20} color={color} /> }} />
    <Tabs.Screen name="analytics" options={{ title: 'Analytics', tabBarIcon: ({ color }) => <Feather name="bar-chart-2" size={20} color={color} /> }} />
    <Tabs.Screen name="profile" options={{ title: 'Profile', tabBarIcon: ({ color }) => <Feather name="user" size={20} color={color} /> }} />
  </Tabs>;
}
