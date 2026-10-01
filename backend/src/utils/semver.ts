/**
 * Semantic Versioning (SemVer) Utility
 * 
 * Provides strict validation and numerical comparison according to SemVer 2.0.0.
 * Ensures version comparisons like 1.4.10 > 1.4.9 evaluate correctly (not lexical).
 */

const SEMVER_REGEX = /^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$/;

export interface ParsedSemver {
  major: number;
  minor: number;
  patch: number;
  prerelease?: string;
  build?: string;
  normalized: string;
}

/**
 * Validates whether a version string matches standard semantic versioning.
 * Accepts formats: "1.0.0", "v1.2.3", "1.4.10", "2.0.0-beta.1", "1.0.0+42"
 */
export function isValidSemver(version: string): boolean {
  if (typeof version !== 'string') return false;
  return SEMVER_REGEX.test(version.trim());
}

/**
 * Parses a semantic version string into its numeric components.
 */
export function parseSemver(version: string): ParsedSemver | null {
  if (!version || typeof version !== 'string') return null;
  const match = version.trim().match(SEMVER_REGEX);
  if (!match) return null;

  const major = parseInt(match[1], 10);
  const minor = parseInt(match[2], 10);
  const patch = parseInt(match[3], 10);
  const prerelease = match[4];
  const build = match[5];

  return {
    major,
    minor,
    patch,
    prerelease,
    build,
    normalized: `${major}.${minor}.${patch}${prerelease ? `-${prerelease}` : ''}`,
  };
}

/**
 * Compares two semantic version strings.
 * 
 * @returns 
 *  -1 if v1 < v2
 *   0 if v1 === v2
 *   1 if v1 > v2
 * 
 * @throws Error if either version is not a valid semantic version.
 */
export function compareSemver(v1: string, v2: string): number {
  const p1 = parseSemver(v1);
  const p2 = parseSemver(v2);

  if (!p1) {
    throw new Error(`Invalid semantic version: "${v1}"`);
  }
  if (!p2) {
    throw new Error(`Invalid semantic version: "${v2}"`);
  }

  // Compare Major
  if (p1.major !== p2.major) {
    return p1.major > p2.major ? 1 : -1;
  }

  // Compare Minor
  if (p1.minor !== p2.minor) {
    return p1.minor > p2.minor ? 1 : -1;
  }

  // Compare Patch
  if (p1.patch !== p2.patch) {
    return p1.patch > p2.patch ? 1 : -1;
  }

  // Pre-release comparisons:
  // Normal version has higher precedence than pre-release version: 1.0.0 > 1.0.0-alpha
  if (!p1.prerelease && p2.prerelease) return 1;
  if (p1.prerelease && !p2.prerelease) return -1;
  if (p1.prerelease && p2.prerelease) {
    if (p1.prerelease === p2.prerelease) return 0;
    return p1.prerelease.localeCompare(p2.prerelease);
  }

  return 0;
}
