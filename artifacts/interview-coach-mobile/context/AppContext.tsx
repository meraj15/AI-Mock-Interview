import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';

export type AppTheme = 'system' | 'light' | 'dark';
export type InterviewConfig = {
  role: string;
  company: string;
  experience: string;
  difficulty: string;
  type: string;
  questions: number;
};
export type ResumeState = {
  name: string;
  source: 'upload' | 'paste';
  status: 'ready' | 'analyzing';
  skills: string[];
  experience: string;
  projects: number;
};

type AppContextValue = {
  onboardingComplete: boolean;
  authenticated: boolean;
  theme: AppTheme;
  setTheme: (theme: AppTheme) => void;
  completeOnboarding: () => void;
  signIn: () => void;
  signOut: () => void;
  config: InterviewConfig;
  setConfig: (config: Partial<InterviewConfig>) => void;
  resume: ResumeState;
  saveResume: (resume: Partial<ResumeState>) => void;
  interviewActive: boolean;
  startInterview: () => void;
  finishInterview: () => void;
};

const defaultConfig: InterviewConfig = {
  role: 'Flutter Developer',
  company: 'General interview',
  experience: '1–2 years',
  difficulty: 'Adaptive',
  type: 'Technical interview',
  questions: 10,
};
const defaultResume: ResumeState = {
  name: 'Meraj_Resume.pdf',
  source: 'upload',
  status: 'ready',
  skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase'],
  experience: '1.2 years',
  projects: 5,
};

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [onboardingComplete, setOnboardingComplete] = useState(false);
  const [authenticated, setAuthenticated] = useState(false);
  const [theme, setThemeState] = useState<AppTheme>('system');
  const [config, setConfigState] = useState<InterviewConfig>(defaultConfig);
  const [resume, setResumeState] = useState<ResumeState>(defaultResume);
  const [interviewActive, setInterviewActive] = useState(false);

  useEffect(() => {
    Promise.all([
      AsyncStorage.getItem('interview-coach-onboarding'),
      AsyncStorage.getItem('interview-coach-auth'),
      AsyncStorage.getItem('interview-coach-theme'),
    ]).then(([onboarded, auth, storedTheme]) => {
      if (onboarded === 'true') setOnboardingComplete(true);
      if (auth === 'true') setAuthenticated(true);
      if (storedTheme === 'light' || storedTheme === 'dark' || storedTheme === 'system') {
        setThemeState(storedTheme);
      }
    });
  }, []);

  const value = useMemo<AppContextValue>(() => ({
    onboardingComplete,
    authenticated,
    theme,
    setTheme: (nextTheme) => {
      setThemeState(nextTheme);
      void AsyncStorage.setItem('interview-coach-theme', nextTheme);
    },
    completeOnboarding: () => {
      setOnboardingComplete(true);
      void AsyncStorage.setItem('interview-coach-onboarding', 'true');
    },
    signIn: () => {
      setAuthenticated(true);
      void AsyncStorage.setItem('interview-coach-auth', 'true');
    },
    signOut: () => {
      setAuthenticated(false);
      void AsyncStorage.removeItem('interview-coach-auth');
    },
    config,
    setConfig: (nextConfig) => setConfigState((current) => ({ ...current, ...nextConfig })),
    resume,
    saveResume: (nextResume) => setResumeState((current) => ({ ...current, ...nextResume })),
    interviewActive,
    startInterview: () => setInterviewActive(true),
    finishInterview: () => setInterviewActive(false),
  }), [authenticated, config, interviewActive, onboardingComplete, theme]);

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used inside AppProvider');
  return context;
}