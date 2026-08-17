import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

enum CompanyCategory {
  bigTech,
  startup,
  fintech,
  enterprise,
  ecommerce,
  healthcare,
}

class CompanyProfileEntity {
  final String id;
  final String name;
  final CompanyCategory category;
  final String industry;
  final String interviewFocus;
  final List<String> cultureTags;
  final List<String> typicalQuestionTypes;
  final IconData icon;

  const CompanyProfileEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.industry,
    required this.interviewFocus,
    required this.cultureTags,
    required this.typicalQuestionTypes,
    required this.icon,
  });

  static List<CompanyProfileEntity> get defaultCompanies => const [
        CompanyProfileEntity(
          id: 'google',
          name: 'Google',
          category: CompanyCategory.bigTech,
          industry: 'Cloud & Consumer Tech',
          interviewFocus: 'Scalability, clean architecture, algorithm efficiency, and edge case recovery.',
          cultureTags: ['Googliness', 'High Scalability', 'Testing Rigor'],
          typicalQuestionTypes: ['System Design', 'Core DSA', 'Clean Architecture', 'Situational Scenarios'],
          icon: FeatherIcons.globe,
        ),
        CompanyProfileEntity(
          id: 'microsoft',
          name: 'Microsoft',
          category: CompanyCategory.bigTech,
          industry: 'Enterprise Software & Cloud',
          interviewFocus: 'Design patterns, maintainability, cross-platform performance, and engineering trade-offs.',
          cultureTags: ['Growth Mindset', 'System Reliability', 'Collaboration'],
          typicalQuestionTypes: ['API Design', 'Architecture Trade-offs', 'Behavioral (STAR)'],
          icon: FeatherIcons.layers,
        ),
        CompanyProfileEntity(
          id: 'amazon',
          name: 'Amazon',
          category: CompanyCategory.bigTech,
          industry: 'E-commerce & Cloud Services',
          interviewFocus: 'Leadership Principles (Customer Obsession, Ownership, Bias for Action) & deep technical dives.',
          cultureTags: ['Leadership Principles', 'Operational Excellence', 'Frugality'],
          typicalQuestionTypes: ['STAR Behavioral', 'High-Scale Architecture', 'Failure Handling'],
          icon: FeatherIcons.shoppingCart,
        ),
        CompanyProfileEntity(
          id: 'stripe',
          name: 'Stripe',
          category: CompanyCategory.fintech,
          industry: 'Financial Infrastructure',
          interviewFocus: 'API ergonomics, transactional consistency, idempotent endpoints, and security compliance.',
          cultureTags: ['Developer Experience', 'High Security', 'Pragmatism'],
          typicalQuestionTypes: ['API Usability', 'Data Integrity', 'Edge-Case Debugging'],
          icon: FeatherIcons.creditCard,
        ),
        CompanyProfileEntity(
          id: 'fast_startup',
          name: 'High-Growth Startup',
          category: CompanyCategory.startup,
          industry: 'Fast-Paced SaaS',
          interviewFocus: 'Velocity, practical trade-offs, owning end-to-end features, and rapid problem-solving.',
          cultureTags: ['Speed & Execution', 'Full Ownership', 'Agility'],
          typicalQuestionTypes: ['Rapid Feature Prototyping', 'State Management', 'Pragmatic Trade-offs'],
          icon: FeatherIcons.zap,
        ),
        CompanyProfileEntity(
          id: 'tcs_infosys',
          name: 'TCS / Infosys',
          category: CompanyCategory.enterprise,
          industry: 'IT Consulting & Services',
          interviewFocus: 'Object-oriented fundamentals, database querying, lifecycle methods, and client communication.',
          cultureTags: ['Structured Delivery', 'Process Compliance', 'Teamwork'],
          typicalQuestionTypes: ['Core Language Fundamentals', 'SQL & Databases', 'Client Scenarios'],
          icon: FeatherIcons.briefcase,
        ),
      ];
}
