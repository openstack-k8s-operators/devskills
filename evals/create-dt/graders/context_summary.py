import re


def get_assert(output, context):
    text = output.lower()
    checks = {
        "has_services": r"nova|glance|cinder|heat|manila|swift|services",
        "has_storage": r"ceph|rbd|storage",
        "has_network": r"nncp|network|vlan|metallb|ctlplane|ipv4",
        "has_nodes": r"node|compute|edpm",
        "has_context_summary": r"context.*summary|summary|analysis|overview",
    }
    matched = []
    score = 0.0
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.2
            matched.append(name)
    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
