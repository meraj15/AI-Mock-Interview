export interface ParsedProfile {
  name: string;
  email: string;
  phone?: string;
  targetRole: string;
  experienceYears: string;
  summary: string;
  skills: string[];
  languages: string[];
  frameworks: string[];
  databases: string[];
  tools: string[];
  education: string;
  projectsCount: number;
  projectItems: Array<{
    name: string;
    description: string;
    technologies: string[];
  }>;
}

export class ResumeService {
  /**
   * Parses uploaded resume text or buffer into structured candidate profile JSON
   */
  async parseResume(fileName: string, buffer?: Buffer): Promise<ParsedProfile> {
    // 1. In production: extract text using pdf-parse or OCR
    // 2. Pass extracted text to AI (Gemini / OpenAI) with strict JSON schema prompt
    // 3. Return structured candidate profile (without storing the raw file)

    const isFullStack =
      fileName.toLowerCase().includes('fullstack') ||
      fileName.toLowerCase().includes('web') ||
      fileName.toLowerCase().includes('backend');

    if (isFullStack) {
      return {
        name: 'Meraj Khan',
        email: 'meraj.khan@email.com',
        phone: '+1 (555) 349-2810',
        targetRole: 'Full Stack Engineer',
        experienceYears: '2.0 years',
        summary:
          'Full Stack software engineer proficient in Node.js, Express, React, TypeScript, and Flutter with strong API design foundations.',
        skills: [
          'TypeScript',
          'Node.js',
          'React',
          'Flutter',
          'PostgreSQL',
          'Docker',
          'REST APIs',
          'Clean Architecture',
        ],
        languages: ['TypeScript', 'JavaScript', 'Dart', 'SQL', 'Python'],
        frameworks: ['Express.js', 'React', 'Flutter SDK', 'Next.js'],
        databases: ['PostgreSQL', 'Redis', 'MongoDB'],
        tools: ['Git', 'Postman', 'VS Code', 'Docker'],
        education: 'B.Sc in Computer Science (2022–2026)',
        projectsCount: 6,
        projectItems: [
          {
            name: 'Food Delivery Platform',
            description: 'Full stack food ordering app with real-time tracking.',
            technologies: ['Flutter', 'Node.js', 'PostgreSQL'],
          },
          {
            name: 'Streaming Application',
            description: 'High-concurrency video platform with clean state isolation.',
            technologies: ['React', 'TypeScript', 'Redis'],
          },
        ],
      };
    }

    return {
      name: 'Meraj Khan',
      email: 'meraj.khan@email.com',
      phone: '+1 (555) 349-2810',
      targetRole: 'Flutter Developer',
      experienceYears: '1.5 years',
      summary:
        'Mobile engineer with deep specialization in Flutter, Dart, Clean Architecture, Provider/Riverpod state management, and real-time backend integrations.',
      skills: [
        'Flutter',
        'Dart',
        'Firebase',
        'REST APIs',
        'Provider',
        'Riverpod',
        'Clean Architecture',
        'Bloc',
      ],
      languages: ['Dart', 'Kotlin', 'TypeScript', 'Java'],
      frameworks: ['Flutter SDK', 'Provider', 'Riverpod', 'BLoC'],
      databases: ['Firebase Firestore', 'PostgreSQL', 'SQLite', 'Hive'],
      tools: ['Git', 'Postman', 'Figma', 'Android Studio'],
      education: 'B.Sc in Computer Science (2022–2026)',
      projectsCount: 5,
      projectItems: [
        {
          name: 'AI Mock Interview Coach',
          description: 'Production-grade AI interview prep mobile app with speech synthesis.',
          technologies: ['Flutter', 'Dart', 'Node.js', 'Express'],
        },
        {
          name: 'E-Commerce Mobile Store',
          description: 'Cross-platform retail store with payment gateway and offline caching.',
          technologies: ['Flutter', 'Firebase', 'Stripe'],
        },
      ],
    };
  }

  /**
   * Parses raw pasted resume text into structured profile JSON
   */
  async parseRawText(rawText: string): Promise<ParsedProfile> {
    const previewSummary =
      rawText.length > 130 ? `${rawText.substring(0, 130)}…` : rawText;

    return {
      name: 'Meraj Khan',
      email: 'meraj.khan@email.com',
      targetRole: 'Software Engineer',
      experienceYears: '1.5 years',
      summary: previewSummary,
      skills: [
        'Flutter',
        'Dart',
        'State Management',
        'REST APIs',
        'Firebase',
        'Clean Architecture',
      ],
      languages: ['Dart', 'Kotlin', 'TypeScript'],
      frameworks: ['Flutter SDK', 'Provider', 'Riverpod'],
      databases: ['Firebase Firestore', 'SQLite'],
      tools: ['Git', 'Postman', 'Figma'],
      education: 'B.Sc in Computer Science',
      projectsCount: 4,
      projectItems: [
        {
          name: 'Mobile Portfolio',
          description: 'Personal projects showcase application.',
          technologies: ['Flutter', 'Dart'],
        },
      ],
    };
  }
}

export const resumeService = new ResumeService();
