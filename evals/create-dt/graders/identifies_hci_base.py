import re


def get_assert(output, context):
    text = output
    checks = {
        "mentions_va_hci": bool(re.search(r'va/hci|va\.hci', text, re.IGNORECASE)),
        "scores_candidates": bool(re.search(
            r'score|rank|match|overlap|candidate', text, re.IGNORECASE
        )),
        "identifies_ceph": bool(re.search(r'ceph\s*hci', text, re.IGNORECASE)),
        "notes_va_vs_dt": bool(re.search(
            r'va.*dt|dt.*va|production.*test|test.*production', text, re.IGNORECASE
        )),
    }
    matched = [k for k, v in checks.items() if v]
    score = len(matched) / len(checks)
    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.2f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
