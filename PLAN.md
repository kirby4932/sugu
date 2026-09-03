# GitHub Workflows Enhancement Plan

## Current State

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| gradle.yml | Push/PR to master | Builds fat JAR (no tests) |
| docker.yml | Push of a `v*` tag, or manual dispatch | Builds & pushes Docker image to `registry.lunareclipse.ch/sugu` |
| dependency-review.yml | PR to master | Scans for vulnerable dependencies |

---

## Proposed Changes

### Priority 1: Quick Wins (Low Effort, High Value)

#### 1.1 Add Dependabot
**File:** `.github/dependabot.yml`

Auto-creates PRs when dependencies have updates. Zero maintenance.

```yaml
version: 2
updates:
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

#### 1.2 Run Tests in CI
**File:** `.github/workflows/gradle.yml`

Change `./gradlew customFatJar` → `./gradlew build`

This runs tests (JUnit 5 is already configured in build.gradle) before building the JAR.

#### 1.3 Add CodeQL Security Scanning
**File:** `.github/workflows/codeql.yml`

GitHub's static analysis. Catches:
- SQL injection
- Path traversal
- Hardcoded credentials
- Other OWASP issues

```yaml
name: CodeQL

on:
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6am

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: java
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
```

---

### Priority 2: Improved Release Process (Medium Effort)

#### 2.1 Auto-Release on Tag
**File:** `.github/workflows/release.yml`

Currently: Manual GitHub Release → triggers docker.yml

Proposed: Push git tag → auto-create GitHub Release → triggers docker.yml

```yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 23
        uses: actions/setup-java@v4
        with:
          java-version: '23'
          distribution: 'temurin'

      - name: Build fat JAR
        run: |
          chmod +x ./gradlew
          ./gradlew customFatJar

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: build/libs/sugu-*.jar
```

Workflow: `git tag v1.1.0 && git push --tags` → Release created → Docker image built

#### 2.2 Version from Git Tag
**File:** `build.gradle` modification

Replace hardcoded `version = '1.0-SNAPSHOT'` with dynamic version from git tag or environment variable. Ensures JAR and Docker image versions match git tags.

---

### Priority 3: Quality Gates (Medium Effort)

#### 3.1 SpotBugs Static Analysis
**File:** `build.gradle` addition + CI integration

Catches common Java bugs at compile time.

```gradle
plugins {
    id 'com.github.spotbugs' version '6.0.7'
}

spotbugs {
    effort = 'max'
    reportLevel = 'medium'
}
```

#### 3.2 Checkstyle (Optional)
Enforces code style. Only if you want consistent formatting.

---

### Priority 4: Future Considerations (Higher Effort)

| Feature | Effort | Value | Notes |
|---------|--------|-------|-------|
| Test coverage reporting | Medium | Medium | Requires writing tests first |
| Multi-arch Docker build | Low | Medium | `linux/amd64,linux/arm64` for ARM servers |
| Scheduled nightly build | Low | Low | Catches broken deps early |
| Integration tests with Testcontainers | High | High | Test DB interactions with real MariaDB |

---

## Recommended Implementation Order

1. **Dependabot** - 5 min, immediate value
2. **Run tests in CI** - 1 min change
3. **CodeQL** - 10 min, free security scanning
4. **Auto-release on tag** - 15 min, simplifies releases
5. **SpotBugs** - 10 min, catches bugs

---

## Summary

| Change | New File | Effort | Value |
|--------|----------|--------|-------|
| Dependabot | `.github/dependabot.yml` | 5 min | High |
| Tests in CI | Edit `gradle.yml` | 1 min | High |
| CodeQL | `.github/workflows/codeql.yml` | 10 min | High |
| Auto-release | `.github/workflows/release.yml` | 15 min | Medium |
| SpotBugs | Edit `build.gradle` | 10 min | Medium |
