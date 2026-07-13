import re


def get_assert(output, context):
    text = output.lower()
    checks = {
        "identifies_base": r"va/hci|nova-hci\d|based?\s+on|model.*based|similar|identical|existing.*hci",
        "scores_candidates": r"score|rank|match|overlap|candidate|closest|compar",
        "identifies_ceph": r"ceph|hci.*storage|pre-ceph|post-ceph",
        "notes_va_vs_dt": r"va.*dt|dt.*va|production.*test|test.*production|new\s+dt",
    }
    matched = []
    score = 0.0
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
