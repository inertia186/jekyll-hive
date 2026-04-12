#!/usr/bin/env python3
import json
import sys


def main() -> int:
    try:
        from diff_match_patch import diff_match_patch
    except Exception as exc:
        print(json.dumps({
            "available": False,
            "engine": "python3_diff_match_patch",
            "reason": f"python diff_match_patch unavailable: {exc}"
        }))
        return 75

    payload = json.load(sys.stdin)
    dmp = diff_match_patch()

    results = []
    for vector in payload.get("vectors", []):
        entry = {
            "name": vector.get("name"),
            "parsed": False,
            "applied": False,
            "final_text": None,
            "error": None
        }

        try:
            patches = dmp.patch_fromText(vector.get("patch_text", ""))
            entry["parsed"] = True
            final_text, applied_flags = dmp.patch_apply(patches, vector.get("base_text", ""))
            entry["applied"] = all(bool(flag) for flag in applied_flags)
            entry["final_text"] = final_text
            entry["applied_flags"] = [bool(flag) for flag in applied_flags]
        except Exception as exc:
            entry["error"] = str(exc)

        results.append(entry)

    print(json.dumps({
        "available": True,
        "engine": "python3_diff_match_patch",
        "results": results
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
