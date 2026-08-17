class JobCategoryEntity {
  final String id;
  final String name;
  final List<JobRoleEntity> roles;

  const JobCategoryEntity({
    required this.id,
    required this.name,
    required this.roles,
  });

  static List<JobCategoryEntity> get defaultCategories => JobRoleEntity.defaultCategories;
}

class JobRoleEntity {
  final String id;
  final String title;
  final String category;
  final String defaultExperience;
  final List<String> coreSkills;
  final String description;
  final List<String> focusAreas;
  final List<String> typicalRounds;

  const JobRoleEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.defaultExperience,
    required this.coreSkills,
    this.description = 'Architect, build, and scale resilient software applications.',
    this.focusAreas = const ['Architecture & Design Patterns', 'Code Quality & Performance', 'Problem Solving & Debugging'],
    this.typicalRounds = const ['Technical Screen', 'Live Coding / System Design', 'Behavioral / Culture Fit'],
  });

  static List<JobCategoryEntity> get defaultCategories => const [
        JobCategoryEntity(
          id: 'mobile',
          name: 'Mobile Development',
          roles: [
            JobRoleEntity(
              id: 'flutter_dev',
              title: 'Flutter Developer',
              category: 'Mobile Development',
              defaultExperience: '1–3 years',
              coreSkills: ['Flutter', 'Dart', 'Provider', 'Riverpod', 'Clean Architecture', 'REST APIs'],
              description: 'Build performant, cross-platform mobile apps for iOS and Android with beautiful 60fps UIs.',
              focusAreas: ['Widget Lifecycle & State Management', 'Clean Architecture & Repositories', 'Platform Channels & Caching'],
            ),
            JobRoleEntity(
              id: 'android_dev',
              title: 'Android Developer',
              category: 'Mobile Development',
              defaultExperience: '2–4 years',
              coreSkills: ['Kotlin', 'Jetpack Compose', 'Coroutines', 'Room', 'Dagger Hilt'],
              description: 'Develop native modern Android applications using Kotlin and Jetpack libraries.',
              focusAreas: ['Compose State & Recomposition', 'Background Workers & Services', 'Architecture Components (MVVM)'],
            ),
            JobRoleEntity(
              id: 'ios_dev',
              title: 'iOS Developer',
              category: 'Mobile Development',
              defaultExperience: '2–4 years',
              coreSkills: ['Swift', 'SwiftUI', 'Combine', 'UIKit', 'CoreData'],
              description: 'Create native Apple platform applications with high graphical fidelity and smooth transitions.',
              focusAreas: ['Memory Management (ARC)', 'Swift Concurrency (Async/Await)', 'SwiftUI View Graph'],
            ),
            JobRoleEntity(
              id: 'react_native_dev',
              title: 'React Native Developer',
              category: 'Mobile Development',
              defaultExperience: '1–3 years',
              coreSkills: ['React Native', 'TypeScript', 'Redux Toolkit', 'Native Modules', 'Hermes'],
              description: 'Deliver cross-platform experiences utilizing modern React primitives and native bridges.',
              focusAreas: ['Bridge Architecture & JSI', 'Performance Optimization', 'State Synchronization'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'frontend',
          name: 'Frontend Development',
          roles: [
            JobRoleEntity(
              id: 'react_dev',
              title: 'React Developer',
              category: 'Frontend Development',
              defaultExperience: '2–4 years',
              coreSkills: ['React.js', 'Next.js', 'TypeScript', 'Tailwind CSS', 'Redux Toolkit'],
              description: 'Build fast, accessible, and SEO-friendly responsive web frontends.',
              focusAreas: ['Server Components & SSR', 'State Normalization', 'Web Core Vitals'],
            ),
            JobRoleEntity(
              id: 'vue_dev',
              title: 'Vue.js Developer',
              category: 'Frontend Development',
              defaultExperience: '1–3 years',
              coreSkills: ['Vue.js', 'Nuxt.js', 'Pinia', 'TypeScript', 'Vite'],
              description: 'Design dynamic web applications with reactive component architectures.',
              focusAreas: ['Composition API', 'Reactivity System', 'Nuxt SSR & Routing'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'backend',
          name: 'Backend Development',
          roles: [
            JobRoleEntity(
              id: 'node_dev',
              title: 'Node.js Developer',
              category: 'Backend Development',
              defaultExperience: '2–5 years',
              coreSkills: ['Node.js', 'Express.js', 'NestJS', 'PostgreSQL', 'Redis', 'Docker'],
              description: 'Architect scalable, high-throughput microservices and RESTful / GraphQL APIs.',
              focusAreas: ['Event Loop & Non-Blocking I/O', 'Database Indexing & Transactions', 'Distributed Caching'],
            ),
            JobRoleEntity(
              id: 'java_dev',
              title: 'Java / Spring Boot Developer',
              category: 'Backend Development',
              defaultExperience: '3–6 years',
              coreSkills: ['Java', 'Spring Boot', 'Microservices', 'Hibernate / JPA', 'Kafka'],
              description: 'Engineer enterprise-grade resilient backend systems with Spring framework.',
              focusAreas: ['Concurrency & Thread Pools', 'Spring Dependency Injection', 'Event-Driven Architectures with Kafka'],
            ),
            JobRoleEntity(
              id: 'python_dev',
              title: 'Python Backend Engineer',
              category: 'Backend Development',
              defaultExperience: '2–4 years',
              coreSkills: ['Python', 'FastAPI', 'Django', 'PostgreSQL', 'Celery', 'Redis'],
              description: 'Build clean, high-performance async APIs and background worker systems.',
              focusAreas: ['Asyncio & Coroutines', 'ORM Optimization', 'Background Task Queues'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'fullstack',
          name: 'Full Stack Development',
          roles: [
            JobRoleEntity(
              id: 'fullstack_js',
              title: 'Full Stack JavaScript Engineer',
              category: 'Full Stack Development',
              defaultExperience: '2–5 years',
              coreSkills: ['TypeScript', 'React', 'Node.js', 'PostgreSQL', 'Next.js', 'Docker'],
              description: 'Own end-to-end features from database schema design to frontend UI delivery.',
              focusAreas: ['End-to-End Type Safety', 'API Design & Integration', 'CI/CD & Deployment'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'ai_data',
          name: 'AI & Data Science',
          roles: [
            JobRoleEntity(
              id: 'ai_engineer',
              title: 'AI / LLM Engineer',
              category: 'AI & Data Science',
              defaultExperience: '2–4 years',
              coreSkills: ['Python', 'LangChain', 'OpenAI APIs', 'Vector DBs', 'RAG Pipelines', 'Fine-Tuning'],
              description: 'Implement Generative AI, Retrieval-Augmented Generation, and agentic workflows.',
              focusAreas: ['Prompt Engineering & Evaluation', 'Vector Embeddings & Semantic Search', 'Agent Tool Calling'],
            ),
            JobRoleEntity(
              id: 'data_scientist',
              title: 'Data Scientist',
              category: 'AI & Data Science',
              defaultExperience: '2–5 years',
              coreSkills: ['Python', 'Pandas', 'Scikit-Learn', 'SQL', 'PyTorch', 'Statistical Modeling'],
              description: 'Extract statistical insights, build predictive models, and validate business hypotheses.',
              focusAreas: ['Exploratory Data Analysis', 'Model Validation & Metrics', 'Feature Engineering'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'devops',
          name: 'DevOps & Cloud',
          roles: [
            JobRoleEntity(
              id: 'devops_engineer',
              title: 'DevOps / Cloud Engineer',
              category: 'DevOps & Cloud',
              defaultExperience: '3–6 years',
              coreSkills: ['AWS', 'Kubernetes', 'Docker', 'Terraform', 'CI/CD', 'Prometheus'],
              description: 'Manage cloud infrastructure, container orchestration, and automated delivery pipelines.',
              focusAreas: ['Infrastructure as Code (IaC)', 'Kubernetes Cluster Management', 'Observability & SRE'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'qa_testing',
          name: 'QA & Test Automation',
          roles: [
            JobRoleEntity(
              id: 'qa_automation',
              title: 'QA Automation Engineer',
              category: 'QA & Test Automation',
              defaultExperience: '2–4 years',
              coreSkills: ['Appium', 'Selenium', 'Playwright', 'Jest', 'CI/CD Pipelines'],
              description: 'Design robust automated test suites ensuring zero-regression releases.',
              focusAreas: ['E2E Testing Architectures', 'Test Pyramid & Coverage', 'Flaky Test Remediation'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'product_design',
          name: 'Product & Design',
          roles: [
            JobRoleEntity(
              id: 'product_manager',
              title: 'Technical Product Manager',
              category: 'Product & Design',
              defaultExperience: '3–6 years',
              coreSkills: ['Roadmapping', 'Agile / Scrum', 'User Stories', 'A/B Testing', 'Data Analytics'],
              description: 'Drive product vision, prioritize roadmap initiatives, and align cross-functional teams.',
              focusAreas: ['Product Strategy & Metrics', 'Prioritization Frameworks (RICE)', 'Stakeholder Management'],
            ),
            JobRoleEntity(
              id: 'ui_ux_designer',
              title: 'Product Designer (UI/UX)',
              category: 'Product & Design',
              defaultExperience: '2–5 years',
              coreSkills: ['Figma', 'Design Systems', 'User Research', 'Prototyping', 'Usability Testing'],
              description: 'Craft intuitive, beautiful user flows and maintain scalable design token systems.',
              focusAreas: ['Information Architecture', 'Design System Governance', 'User Research & Wireframing'],
            ),
          ],
        ),
      ];
}
