---
name: analyze-zuul-ci-logs
description: Produce an analysis of observed problems in downloaded Zuul CI logs
argument-hint: "<path>"
user-invocable: true
allowed-tools: ["Bash", "Read", "Grep"]
context: fork
---

# Analyze Zuul CI logs

## General rules

- If something prevents you from taking meaningful steps forward, stop and report the problem to the user.

- Consider the logs read-only. Do not edit anything in them.

- Even if you have tools like `oc` or `ssh` available, don't do direct cluster examination during the analysis. Stick to just analyzing the logs. If you find that it would be helpful to have some more information, which is missing from the report but could be obtained by directly inspecting OpenShift or OpenStack or the underlying servers, highlight that in your analysis.

- Try to match LLM context usage with the severity of the issue being investigated. Investigate serious problems first. If a problem looks serious, feel free to use more effort in investigating it. If an error is transient or of low severity, still make a note in your analysis but don't spend too much effort on hunting down the root cause.

- You MUST NOT use any command whose purpose is to communicate over network.

## Zuul CI logs structure hints

- `job-output.txt` or `job-output.txt.gz` is the outermost log file that should be looked at first. If there is an error that failed the job, it should be somewere towards the end of that log file.

- There should be an `openstack-must-gather` directory which should contain various logs from the environment (e.g. from OpenShift pods). Look at the `analyze-must-gather` skill for hints on how to analyze a must-gather report.

## Analysis workflow

1. Locate `job-output.txt` or `job-output.txt.gz` inside the logs directory and see if there is an error somewere towards the end of that log file. This can give you a good clue for further investigation.

2. Scan the logs for signs of problems with tools like `grep` or `ripgrep`. The words to look for include but may not be limited to "error", "fail", "failure", "fatal", "restart".

3. If the problem scan highlighted obvious problems, read more info to help understand the problem and its cause better (larger file chunks or whole files). Try to get to the root cause, but even if that doesn't seem possible, gathering more clues is still helpful. (Feel free to use `ls` more than in step 1, in case it seems helpful.)

4. If the previous steps didn't yield any obvious problems, repeat the step "scan the report for signs of problems" but widen the search to words like "warn", "warning". If that yields something, do the step "read more info to help understand the problem".

5. Don't just settle for finding symptoms, try to find the root causes of the main problems.

6. Output a structured analysis of the observed problems and ideally also their causes. Start with the most severe issues first. Write the analysis into `./workdir/zuul-logs-analysis.md`.
