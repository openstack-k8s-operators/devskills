import re


def get_assert(output, context):
    text = output.lower()

    # Step 0 / menu fallback without a tour is a common failure mode.
    if re.search(
        r'pick a number|how familiar are you|operator_knowledge|reply with a number',
        text,
    ):
        if not re.search(r'\bnova\b|\bglanceapi\b', text):
            return {
                "pass": False,
                "score": 0.0,
                "reason": "Stopped at Step 0 menu instead of giving repo tour",
            }

    score = 0.0
    checks = {
        "cr_catalog": r'\bnova\b|\bglanceapi\b|two crs',
        "directory_layout": r'internal/controller|api/.*/v1beta1|directory layout',
        "reconcile_path": r'reconcil|reconcile cycle|request path|watch|enqueue',
        "tour_framing": r'repo tour|onboarding tour|custom resource|directory layout',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    # Require CR catalog — the core signal for a real repo tour.
    if "cr_catalog" not in matched:
        return {
            "pass": False,
            "score": score,
            "reason": f"Missing CR catalog (Nova/GlanceAPI) — matched: {', '.join(matched) or 'none'}",
        }

    deep_trace = bool(re.search(
        r'reconcile loop always follows|detailed trace|step-by-step.*reconcil',
        text,
    ))
    has_tour = "cr_catalog" in matched and "directory_layout" in matched
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
