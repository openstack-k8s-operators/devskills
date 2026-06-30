import re


def get_assert(output, context):
    text = output.lower()

    score = 0.0
    checks = {
        "cr_catalog": r'\bnova\b|\bglanceapi\b|custom resource|two crs',
        "directory_layout": r'internal/controller|api/.*/v1beta1|directory layout',
        "reconcile_path": r'reconcil|reconcile cycle|request path|watch|enqueue',
        "tour_framing": r'repo tour|onboarding tour|custom resource|directory layout',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    deep_trace = bool(re.search(
        r'reconcile loop always follows|detailed trace|step-by-step.*reconcil',
        text,
    ))
    has_tour = "cr_catalog" in matched or "tour_framing" in matched
    if deep_trace and not has_tour:
        return {
            "pass": False,
            "score": score,
            "reason": "Deep reconciler trace without repo tour signals",
        }

    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.2f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
