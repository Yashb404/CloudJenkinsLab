# FestPass CI Assignment Submission Evidence

**Course**: Cloud Automation & Jenkins (CSE4141)  
**Student Name**: Yashaswi Bhardwaj  
**Git Author Name / Alias**: `yashb404`  
**Git Author Email**: `yashbhardwaj7890@gmail.com`  
**Class Code**: `class-1`  
**Challenge Code**: `00666`  
**Submission Date**: October 29, 2026  

---

## 1. Jenkins SCM Job & Agent Setup (20 Points)

- **Job Name**: `festpass-ci`
- **Job Type**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `git://127.0.0.1:9418/festpass-java` (Served via loopback `git daemon`)
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`
- **Build Agent**: Dedicated inbound permanent node `student-laptop` running on WebSocket protocol with 1 executor and mode set to `EXCLUSIVE` (Built-In Node executors set to 0).

---

## 2. Trigger Configuration & Automatic Red Build (25 Points)

### SCM Polling Trigger
Added to `festpass-java/Jenkinsfile` within the `pipeline` block:
```groovy
triggers {
    pollSCM('* * * * *')
}
```
Bootstrapped via initial commit `fa98c6b` and manual run **Build 3**.

### Red Build Details (Build 4)
- **Trigger Cause**: `Started by an SCM change`
- **Commit ID**: `5877f92a0ccbb1d356cf7feb9db4d95d227561e5`
- **Commit Message**: `Personalize my help introduction`
- **Personalized Change**: Updated `FestPass.java` usage header to include Git author alias:  
  `FestPass - campus event registration (maintained by yashb404)`
- **Result**: `FAILURE` (RED)
- **Gated / Skipped Stages**: `Build JAR`, `Smoke test JAR`, `Save artifact` were skipped due to test failures. No JAR was published.
- **Evidence CSV**: Archived as `submission-evidence.csv`. Saved locally to `submission/build-red/submission-evidence.csv`.

### Failed Assertions in Build 4
1. **`cancellationFreesSeat`**:
   ```text
   java.lang.IllegalArgumentException: SOLD OUT. Even the developer needs a ticket.
       at BookingService.book(BookingService.java:60)
       at FestPassTest.cancellation(FestPassTest.java:147)
       at FestPassTest.main(FestPassTest.java:71)
   ```
2. **`cancellationsSurviveReload`**:
   ```text
   java.lang.AssertionError: Cancellation was lost
       at FestPassTest.check(FestPassTest.java:343)
       at FestPassTest.lambda$persistCancellation$0(FestPassTest.java:207)
   ```
3. **`cliWorkflowPersistsAcrossCommands`**:
   ```text
   java.lang.AssertionError: List does not reflect persisted cancellation
       at FestPassTest.check(FestPassTest.java:343)
       at FestPassTest.lambda$cliWorkflow$0(FestPassTest.java:237)
   ```

---

## 3. Bug Diagnosis & Minimal Repair (30 Points)

### Diagnosis
In `BookingService.java`, the `cancel(String eventId, String studentId)` method validated that the target event existed and that the student ID was registered in `event.students`, but failed to actually mutate the registration set. Because `event.students.remove(studentId)` was omitted:
1. The student remained in `event.students`, leaving `event.students.size()` unchanged at full capacity.
2. When the test cancelled a ticket and attempted to re-book the freed seat (`service.book("music", "S2")`), `FestPass.canBook(event.students.size(), event.capacity)` evaluated to `false`, throwing the `SOLD OUT` exception.
3. During persistence operations, the un-removed booking was serialized back to disk, causing reload assertions to fail.

### Minimal Application Fix
Applied in `festpass-java/src/main/java/BookingService.java` at line 71:
```diff
     public void cancel(String eventId, String studentId) {
         validateId(studentId);
         Registration event = requireEvent(eventId);
         if (!event.students.contains(studentId)) {
             throw new IllegalArgumentException("No booking for student: " + studentId);
         }
+        event.students.remove(studentId);
     }
```
*Note: All 28 test cases, pipeline assertions, and build verification files remained 100% unchanged.*

---

## 4. Automatic Green Build & Artifacts (15 Points)

### Green Build Details (Build 5)
- **Trigger Cause**: `Started by an SCM change` (Automatic via SCM polling, no manual build clicked)
- **Commit ID**: `259902d9b5fe20ce78ef618840db325ae4fc9b21`
- **Commit Message**: `Fix cancellation to remove student from event roster and free seat`
- **Result**: `SUCCESS` (GREEN)
- **Test Summary**: **28 tests executed, 28 passed, 0 failures, 0 errors, 0 skipped**.
- **Completed Stages**: `Checkout` -> `Submission setup` -> `Test` -> `Build JAR` -> `Smoke test JAR` -> `Save artifact`.
- **Archived Artifacts**:
  - `festpass.jar`
  - `build-info.txt`
  - `smoke-test.txt`
  - `submission-evidence.csv`

---

## 5. Artifact & Execution Evidence (10 Points)

### Artifact Verification
- **Artifact Path**: `submission/build-green/festpass.jar`
- **SHA-256**: `e12ba18c01e5b934a8e211b8a4fbf5416d8ffb6215a88d392a9014907cb5d782`
- **Matching Evidence CSV JarSha256**: `e12ba18c01e5b934a8e211b8a4fbf5416d8ffb6215a88d392a9014907cb5d782`

### Run Evidence
Executed locally in `submission/build-green/`:

```bash
$ java -jar festpass.jar help
FestPass - campus event registration (maintained by yashb404)
Usage: java -jar build/festpass.jar [--data FILE] COMMAND
  add-event ID "TITLE" CAPACITY
  list
  book EVENT_ID STUDENT_ID
  cancel EVENT_ID STUDENT_ID
  roster EVENT_ID
  summary
  help
Default data file: data/festpass.tsv
IDs are case-sensitive. Use synthetic student IDs, not personal data.
Exit codes: 0 success, 2 invalid request, 3 storage failure.

$ java -jar festpass.jar add-event java "Java Workshop" 1
EVENT CREATED: java

$ java -jar festpass.jar book java S1
BOOKING ACCEPTED: S1 -> java

$ java -jar festpass.jar book java S2
Invalid input: SOLD OUT. Even the developer needs a ticket.

$ java -jar festpass.jar cancel java S1
BOOKING CANCELLED: S1 -> java

$ java -jar festpass.jar book java S2
BOOKING ACCEPTED: S2 -> java

$ java -jar festpass.jar summary
Events: 1 | Booked: 1 | Available: 0

$ java -jar festpass.jar list
ID | TITLE | BOOKED/CAPACITY | AVAILABLE
java | Java Workshop | 1/1 | 0
```

---

## 6. Submission Directory Structure

```text
submission/
├── SUBMISSION.md
├── jar-run-evidence.txt
├── build-red/
│   └── submission-evidence.csv
└── build-green/
    ├── build-info.txt
    ├── festpass.jar
    ├── smoke-test.txt
    └── submission-evidence.csv
```
