# Development Version and Branch Handling

This document describes the branching strategy, version numbering, and CI/CD pipeline for the EMF GenModel Generator project.

## Branches

The project follows a GitFlow-based branching model. Each branch type has a specific purpose and lifecycle:

```mermaid
gitGraph
    commit id: "initial"
    branch develop
    checkout develop
    commit id: "dev work"
    branch feature/JNG-1
    commit id: "feature 1"
    checkout develop
    branch feature/JNG-2
    commit id: "feature 2"
    checkout develop
    merge feature/JNG-1
    merge feature/JNG-2
    branch release/1.0-beta1
    commit id: "release prep"
    branch bugfix/JNG-4
    commit id: "fix"
    checkout release/1.0-beta1
    merge bugfix/JNG-4
    checkout main
    merge release/1.0-beta1 id: "v1.0-beta1"
    checkout develop
    merge release/1.0-beta1
    commit id: "continue dev"
```

| Branch Pattern | Base | Purpose |
|---------------|------|---------|
| `develop` | — | Main development branch. Contains latest development sources for the active version. |
| `feature/JNG-xxx_summary` | `develop` | New features being developed. Merged back into `develop` when complete. |
| `release/x.y.z` or `x_y_z` | `develop` | Release stabilization. Bug fixes are applied here before merging to `master`. The `release/` prefix is reserved for CI. |
| `bugfix/JNG-xxx_summary` | release branch | Fixes found during release testing. Must be applied to both the release branch and newer development branches. |
| `support/JNG-xxx_summary` | release branch | Minor changes for a previous release. Merged back to the release branch when the update ships. |
| `hotfix/JNG-xxx_summary` | `master` | Urgent fixes for production. Applied to both `master` and `develop`. |
| `master` | — | Latest released sources. Only receives merges from release and hotfix branches. |

## Version Numbers

Versions follow semantic versioning with these rules:

| Event | Version Change | Example |
|-------|---------------|---------|
| Start feature branch | No change | — |
| Start release branch | Bump 2nd number on `develop` | `1.1.0-SNAPSHOT` → `1.2.0-SNAPSHOT` |
| Start bugfix branch | No change | Applied during release testing |
| Start support branch | Bump 3rd number | `1.0.0` → `1.0.1` |
| Start hotfix branch | Bump 4th number | `1.0.0` → `1.0.0.1` |

## GitHub Actions Workflows

The CI/CD system is composed of several interconnected workflows. Each workflow triggers the next based on branch and tag conventions.

### build.yml — Main Build Pipeline

This is the primary workflow, triggered on every push to `develop` and on pull requests targeting `develop`, `master`, `increment/*`, or `release/*` branches.

```mermaid
flowchart TD
    Trigger["Push to develop<br/>or PR to develop/master/<br/>increment/release branches"]
    Trigger --> CheckBranch{Branch type?}

    CheckBranch -->|"master, release/*"| VersionClean["Version = pom.xml<br/>(without -SNAPSHOT)"]
    CheckBranch -->|"develop, increment/*"| VersionDev["Version = major.minor.qualifier<br/>.date_commitId_branch"]

    VersionClean --> Build
    VersionDev --> Build

    Build["Maven Build<br/>mvn clean install<br/>profiles: sign-artifacts,<br/>release-judong"]

    Build --> Tag["Create git tag<br/>v{version}"]

    Tag --> IsPR{Is increment/*<br/>or release/*?}
    IsPR -->|Yes| MergeTag["Create tag<br/>merge-pr/{version}"]
    MergeTag --> TriggerMerge["Triggers<br/>merge-pr-tagged.yml"]

    Tag --> IsDevelop{Is develop?}
    IsDevelop -->|Yes| Changelog["Build changelog"]
    Changelog --> Release["Create GitHub<br/>pre-release"]

    Build --> IsRelease{Is release branch?}
    IsRelease -->|Yes| Central["Deploy to<br/>Maven Central"]

    IsDevelop -->|Yes| Sonar["SonarQube<br/>analysis"]
```

### merge-pr-tagged.yml — Automatic PR Merge

Triggered when a `merge-pr/*` tag is pushed (by `build.yml`). Determines whether to merge to `master` or squash to `develop` based on the version format.

```mermaid
flowchart TD
    Trigger["Tag push:<br/>merge-pr/{version}"]
    Trigger --> Parse["Extract version<br/>from tag name"]
    Parse --> Check{Version format?}

    Check -->|"major.minor.qualifier<br/>(release)"| MergeMaster["Merge PR<br/>to master"]
    MergeMaster --> TriggerRelease["Triggers<br/>create-release-on-master.yml"]

    Check -->|"Other format<br/>(dev snapshot)"| SquashDevelop["Squash PR<br/>to develop"]
    SquashDevelop --> TriggerBuild["Triggers<br/>build.yml"]

    MergeMaster --> Cleanup["Delete<br/>merge-pr tag"]
    SquashDevelop --> Cleanup
```

### create-release-on-master.yml — Production Release

Triggered when code is pushed to `master` (typically via merge from a release branch). Creates the final GitHub release with a changelog.

```mermaid
flowchart TD
    Trigger["Push to master"]
    Trigger --> GetVersion["Get version<br/>from tag"]
    GetVersion --> Changelog["Build changelog"]
    Changelog --> Release["Create GitHub release<br/>(latest)"]
```

### release.yml — Release Orchestration

Manually triggered workflow that automates the release process. Accepts a version parameter (`auto` uses the POM version).

```mermaid
flowchart TD
    Trigger["Manual trigger<br/>with version param"]
    Trigger --> Check{Version = 'auto'?}

    Check -->|Yes| FromPom["Release version =<br/>pom.xml without -SNAPSHOT"]
    Check -->|No| Given["Release version =<br/>given version"]

    FromPom --> CalcNext
    Given --> CalcNext["Next version =<br/>qualifier + 1"]

    CalcNext --> PRMaster["Create PR to master<br/>with release version"]
    CalcNext --> PRDevelop["Create PR to develop<br/>with next version"]

    PRMaster --> BuildMaster["Triggers build.yml"]
    PRDevelop --> BuildDevelop["Triggers build.yml"]
```

### Other Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build-dependabot.yml` | Dependabot PRs | Separate handling for dependency update PRs |
| `bump-version.yml` | Manual | Updates POM versions across all modules |
| `create-release-tagged.yml` | Tag creation | Creates releases from tags |
| `delete-old-draft-releases.yml` | Scheduled | Cleans up stale draft releases |
| `jira-description-to-pr.yml` | PR events | Copies JIRA ticket descriptions into PR body |
| `sync-labels.yml` | Manual/scheduled | Syncs GitHub labels from `labels.yml` |

## Development Rules

> **Important:** Every commit must reference a JIRA ticket number. Use the format `JNG-xxx` in your commit message or PR title.

For issue tracking, the project uses [JIRA](https://blackbelt.atlassian.net/jira/dashboards).
