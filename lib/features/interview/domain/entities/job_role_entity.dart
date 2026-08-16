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

  const JobRoleEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.defaultExperience,
    required this.coreSkills,
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
            ),
            JobRoleEntity(
              id: 'android_dev',
              title: 'Android Developer',
              category: 'Mobile Development',
              defaultExperience: '2–4 years',
              coreSkills: ['Kotlin', 'Jetpack Compose', 'Coroutines', 'Room', 'Dagger Hilt'],
            ),
            JobRoleEntity(
              id: 'ios_dev',
              title: 'iOS Developer',
              category: 'Mobile Development',
              defaultExperience: '2–4 years',
              coreSkills: ['Swift', 'SwiftUI', 'Combine', 'UIKit', 'CoreData'],
            ),
            JobRoleEntity(
              id: 'react_native_dev',
              title: 'React Native Developer',
              category: 'Mobile Development',
              defaultExperience: '1–3 years',
              coreSkills: ['React Native', 'TypeScript', 'Redux Toolkit', 'Expo', 'Jest'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'backend',
          name: 'Backend & Cloud',
          roles: [
            JobRoleEntity(
              id: 'node_dev',
              title: 'Node.js Developer',
              category: 'Backend & Cloud',
              defaultExperience: '2–4 years',
              coreSkills: ['Node.js', 'Express', 'TypeScript', 'PostgreSQL', 'Docker', 'Redis'],
            ),
            JobRoleEntity(
              id: 'python_backend',
              title: 'Python Backend Engineer',
              category: 'Backend & Cloud',
              defaultExperience: '2–5 years',
              coreSkills: ['Python', 'FastAPI', 'Django', 'PostgreSQL', 'Celery', 'AWS'],
            ),
            JobRoleEntity(
              id: 'java_dev',
              title: 'Java Spring Engineer',
              category: 'Backend & Cloud',
              defaultExperience: '3–5 years',
              coreSkills: ['Java', 'Spring Boot', 'Microservices', 'Kafka', 'Kubernetes'],
            ),
            JobRoleEntity(
              id: 'devops_eng',
              title: 'DevOps & Cloud Engineer',
              category: 'Backend & Cloud',
              defaultExperience: '3–6 years',
              coreSkills: ['AWS', 'Terraform', 'CI/CD', 'Kubernetes', 'Docker', 'Prometheus'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'frontend',
          name: 'Frontend & Full Stack',
          roles: [
            JobRoleEntity(
              id: 'react_dev',
              title: 'React / Next.js Developer',
              category: 'Frontend & Full Stack',
              defaultExperience: '2–4 years',
              coreSkills: ['React', 'Next.js', 'TypeScript', 'TailwindCSS', 'GraphQL'],
            ),
            JobRoleEntity(
              id: 'fullstack_dev',
              title: 'Full Stack Engineer',
              category: 'Frontend & Full Stack',
              defaultExperience: '3–5 years',
              coreSkills: ['TypeScript', 'React', 'Node.js', 'PostgreSQL', 'System Design'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'ai_data',
          name: 'AI & Data Engineering',
          roles: [
            JobRoleEntity(
              id: 'ai_eng',
              title: 'AI / LLM Engineer',
              category: 'AI & Data Engineering',
              defaultExperience: '2–5 years',
              coreSkills: ['Python', 'LangChain', 'OpenAI APIs', 'Vector Databases', 'RAG'],
            ),
            JobRoleEntity(
              id: 'data_scientist',
              title: 'Data Scientist',
              category: 'AI & Data Engineering',
              defaultExperience: '2–5 years',
              coreSkills: ['Python', 'PyTorch', 'Pandas', 'Scikit-learn', 'SQL', 'A/B Testing'],
            ),
          ],
        ),
        JobCategoryEntity(
          id: 'product_design',
          name: 'Product & Design',
          roles: [
            JobRoleEntity(
              id: 'uiux_designer',
              title: 'Product / UI-UX Designer',
              category: 'Product & Design',
              defaultExperience: '2–5 years',
              coreSkills: ['Figma', 'User Research', 'Design Systems', 'Prototyping', 'Wireframing'],
            ),
            JobRoleEntity(
              id: 'product_mgr',
              title: 'Product Manager',
              category: 'Product & Design',
              defaultExperience: '3–6 years',
              coreSkills: ['Roadmapping', 'User Stories', 'Metrics & KPIs', 'Agile', 'Market Analysis'],
            ),
          ],
        ),
      ];
}
