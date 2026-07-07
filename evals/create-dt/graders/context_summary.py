import re


def get_assert(output, context):
    text = output.lower()
    checks = {
        "has_services": r'services?\s*(required)?.*nova|nova.*glance|services',
        "has_storage": r'storage\s*(backend)?.*ceph|ceph\s*hci',
        "has_network": r'network\s*(topology)?.*ipv4|vlan|metallb',
        "has_nodes": r'node\s*(roles)?.*compute|3\s*compute',
        "has_context_summary": r'context\s*summary',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            matched.append(name)
    score = len(matched) / len(checks)
    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
