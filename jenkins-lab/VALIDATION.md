# Validation performed

Tested on Windows with Temurin JDK 21 and Jenkins LTS 2.580.1.

The results below validate the completed pipeline WITH the pollSCM trigger added and sample submission codes filled as instructed in the assignment. The distributed student Jenkinsfile intentionally omits that trigger; it does not auto-build until students configure, commit, and bootstrap it. The shipped application is intentionally the failing version, with 25 passing and 3 failing tests; the private validation repair passes all 28. Student documents do not disclose the repair.

- Jenkins build 1: FAILURE; 25 passed, 3 failed.
- Jenkins build 2: FAILURE; 25 passed, 3 failed.
- Jenkins build 3: SUCCESS; 28 passed, 0 failed.

The personalization and fix builds were triggered by real SCM polling after local commits, not by manually pressing Build Now. Successful builds archived a runnable JAR; failed builds published submission evidence only, not a JAR. The built-in controller node had zero executors; a separate local agent performed the builds.

Upgraded starter: 28 registered tests and a seven-command real-JAR smoke stage. Successful builds also publish smoke-test.txt; a failed test stage blocks packaging, smoke testing, and product artifact publication. Evidence is always archived. These end-to-end Jenkins runs preceded the Git-author alias revision. That revision was separately validated in an isolated Git checkout: the recorded author follows HEAD rather than a stale alias property or agent-local user.name, changes only with a new authored commit, and does not include the author's email. Application tests and pipeline stages remain unchanged by the alias revision. PowerShell launchers were syntax checked; the Git server and agent launcher were exercised. Bash launchers were syntax checked with Git Bash. macOS and Linux end-to-end execution was not performed; those instructions/scripts use the same Java project and standard Bash, curl, and Git interfaces.

This is a trusted, loopback-only teaching lab, not a production security baseline.
