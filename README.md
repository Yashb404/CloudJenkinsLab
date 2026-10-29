# Cloud Jenkins Lab & FestPass CI Assessment

[![Java](https://img.shields.io/badge/Java-21%2B%20%2F%2027-orange.svg)](#requirements)
[![Jenkins](https://img.shields.io/badge/Jenkins-2.580.x%20LTS-blue.svg)](#jenkins-architecture)
[![Pipeline](https://img.shields.io/badge/Pipeline-Declarative%20SCM-green.svg)](#pipeline-workflow)
[![Tests](https://img.shields.io/badge/Tests-28%20Passed-brightgreen.svg)](#test-suite--defect-diagnosis)
[![License](https://img.shields.io/badge/Academic-Assignment%20Submission-lightgrey.svg)](#submission-evidence)

This repository contains the complete implementation and verified build evidence for the **Cloud Automation & Jenkins (CSE4141)** lab assessment.

The project implements an automated Continuous Integration pipeline using a Jenkins Declarative Pipeline with SCM polling, dedicated build agent execution, strict quality gating, and diagnostic build evidence recording for **FestPass**, an event registration and ticketing application.

---

## Repository Structure

```text
CloudJenkinsLab/
├── README.md                           # Main repository overview and guide
├── .gitignore                          # Strict ignore rules protecting runtime and secrets
├── festpass-java/                      # Application source, tests, and CI definitions
│   ├── Jenkinsfile                     # Declarative Pipeline with SCM polling & artifact gating
│   ├── submission.properties           # Class code and challenge code configuration
│   ├── ci/
│   │   ├── Build.java                  # Standalone compiler, test runner, and packager
│   │   ├── BuildEvidence.java          # Cryptographic evidence collector (CSV)
│   │   └── SmokeTest.java              # Real-JAR end-to-end smoke verification
│   ├── src/
│   │   ├── main/java/                  # Core application (FestPass CLI, BookingService, BookingStore)
│   │   └── test/java/                  # 28 comprehensive unit & integration tests
│   ├── ASSIGNMENT.md                   # Assignment brief and 100-point rubric
│   └── README.md                       # FestPass detailed documentation
├── jenkins-lab/                        # Jenkins environment management scripts
│   ├── start-git-server.sh             # Read-only loopback Git daemon (port 9418)
│   ├── start-jenkins.sh                # Local Jenkins controller startup
│   ├── start-agent.sh                  # Inbound WebSocket agent launcher (student-laptop)
│   └── plugins.txt                     # Pinned plugin dependencies (git, workflow-aggregator, junit)
└── submission/                         # Graded assessment artifacts and evidence
    ├── SUBMISSION.md                   # Detailed rubric evidence report
    ├── jar-run-evidence.txt            # Command log verifying final JAR execution
    ├── build-red/
    │   └── submission-evidence.csv     # Archived CSV from SCM-triggered Red Build 4
    └── build-green/
        ├── festpass.jar                # Final gated executable JAR (verified SHA-256)
        ├── submission-evidence.csv     # Archived CSV from SCM-triggered Green Build 5
        ├── build-info.txt              # Build metadata artifact
        └── smoke-test.txt              # Real-JAR smoke test execution output
```

---

## Jenkins Architecture

```
   +-------------------------------------------------------------+
   |                      Developer Machine                      |
   |                                                             |
   |   Local Git Repo  ====[ git daemon ]====> Git URL:          |
   |   (festpass-java)         (Port 9418)     git://127.0.0.1/  |
   |                                                  |          |
   |                                            pollSCM: * * * * |
   |                                                  v          |
   |                                          +---------------+  |
   |                                          |    Jenkins    |  |
   |                                          |  Controller   |  |
   |                                          | (Executors=0) |  |
   |                                          +---------------+  |
   |                                                  |          |
   |                                              WebSocket      |
   |                                                  v          |
   |                                          +---------------+  |
   |                                          | student-laptop|  |
   |                                          |  Build Agent  |  |
   |                                          | (Executors=1) |  |
   |                                          +---------------+  |
   +-------------------------------------------------------------+
```

1. **Controller Isolation**: The Jenkins Built-In Node is configured with `numExecutors: 0` to prevent unisolated controller builds.
2. **Dedicated Build Agent**: A permanent inbound agent named `student-laptop` with label `student-laptop` and `Mode.EXCLUSIVE` executes all builds via WebSocket connection.
3. **Loopback SCM Serving**: The repository is exported locally via `git daemon` at `git://127.0.0.1:9418/festpass-java`, requiring zero external cloud dependencies or credentials.
4. **SCM Polling**: The pipeline polls the Git daemon once every minute (`pollSCM('* * * * *')`) and triggers builds automatically upon detecting new commits.

---

## Pipeline Workflow & Quality Gating

The [Jenkinsfile](festpass-java/Jenkinsfile) executes the following sequential stages:

```
[ Checkout ] -> [ Submission Setup ] -> [ Test (28 Tests) ] -+
                                                             |
                 +-------------------------------------------+
                 |
     [ Tests Pass? ]
      /           \
   (Yes)          (No)
    /               \
   v                 v
[ Build JAR ]     [ Gated: JAR Skipped ]
   v                 v
[ Smoke Test ]    [ Gated: Smoke Skipped ]
   v                 v
[ Save Artifacts ][ Always: Archive Evidence CSV ]
```

- **Gating Guarantee**: If any test fails during the `Test` stage, compilation of the JAR (`Build JAR`), execution of the JAR (`Smoke test JAR`), and archiving of the runnable binary (`Save artifact`) are strictly blocked.
- **Always-On Diagnostic Evidence**: The `post { always { ... } }` block generates and archives `submission-evidence.csv` for every build, recording test statistics, commit hashes, timestamps, and execution outcomes.

---

## Test Suite & Defect Diagnosis

### Seeded Defect
In the original starter, test `cancellationFreesSeat` failed with:
```text
java.lang.IllegalArgumentException: SOLD OUT. Even the developer needs a ticket.
    at BookingService.book(BookingService.java:60)
    at FestPassTest.cancellation(FestPassTest.java:147)
```
- **Root Cause**: `BookingService.cancel(eventId, studentId)` validated the existing booking but omitted removing the student from the internal `event.students` registration set. The event remained at maximum capacity, preventing subsequent bookings after cancellation and corrupting persisted event state.
- **Minimal Fix**: Added `event.students.remove(studentId);` to `BookingService.java`. All 28 test cases and pipeline assertions remained untouched.

---

## Build Progression Summary

| Build # | Trigger Cause | Commit | Result | Tests | Artifacts Published |
|:---:|:---|:---:|:---:|:---:|:---|
| **Build 3** | Manual (`Started by user yashaswi`) | `fa98c6b` | `FAILURE` | 25 Passed, 3 Failed | `submission-evidence.csv` |
| **Build 4** | Automatic (`Started by an SCM change`) | `5877f92` | `FAILURE` | 25 Passed, 3 Failed | `submission-evidence.csv` |
| **Build 5** | Automatic (`Started by an SCM change`) | `259902d` | `SUCCESS` | **28 Passed, 0 Failed** | `festpass.jar`, `build-info.txt`, `smoke-test.txt`, `submission-evidence.csv` |

---

## Local Verification Commands

To test and build the application locally without Jenkins:

```bash
# Navigate to the project directory
cd festpass-java

# Run the 28-test suite (compilation + execution)
java ci/Build.java test

# Verify all tests, compile, and package the JAR
java ci/Build.java verify

# Execute the 7-scenario real-JAR smoke test suite
java ci/SmokeTest.java

# Run the packaged CLI application
java -jar build/festpass.jar help
```

### Example Walkthrough
```bash
# Create an event with capacity 1
java -jar build/festpass.jar add-event java "Java Workshop" 1

# Book seat S1
java -jar build/festpass.jar book java S1

# Attempt to book seat S2 (fails with exit code 2: SOLD OUT)
java -jar build/festpass.jar book java S2

# Cancel seat S1
java -jar build/festpass.jar cancel java S1

# Book seat S2 (succeeds now that seat is freed)
java -jar build/festpass.jar book java S2

# Display summary and event list
java -jar build/festpass.jar summary
java -jar build/festpass.jar list
```

---

