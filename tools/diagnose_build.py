#!/usr/bin/env python3
"""Summarize xcodebuild failures without requiring manual screenshots."""
import json, pathlib, re, sys
source = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else "retroarch-ios-build.log")
out = pathlib.Path("diagnostics")
out.mkdir(exist_ok=True)
text = source.read_text(errors="replace") if source.exists() else "Build log missing"
lines = text.splitlines()
patterns = {
    "compiler_errors": re.compile(r"(?:^|\s)(?:fatal )?error:|\*\* BUILD FAILED \*\*", re.I),
    "warnings": re.compile(r"\bwarning:", re.I),
    "linker": re.compile(r"undefined symbols|ld: |linker command failed|library not found", re.I),
    "codesigning": re.compile(r"code.?sign|provisioning profile|certificate", re.I),
    "failed_commands": re.compile(r"CompileC |SwiftCompile |Ld |PhaseScriptExecution |\(.*failures?\)", re.I),
}
summary = {"log": str(source), "total_lines": len(lines), "categories": {}}
for category, regex in patterns.items():
    matches = []
    for i, line in enumerate(lines):
        if regex.search(line):
            matches.append({"line": i+1, "text": line[:1200], "context": "\n".join(lines[max(0,i-3):min(len(lines),i+4)])[:3500]})
    summary["categories"][category] = matches[:120]
(out/"summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
with (out/"summary.md").open("w") as f:
    f.write("# RetroBox i1 - Build Diagnostics\n\n")
    f.write(f"Log lines: {len(lines)}\n\n")
    for category, matches in summary["categories"].items():
        f.write(f"## {category} ({len(matches)})\n\n")
        for item in matches[:40]:
            f.write(f"- Line {item['line']}: `{item['text'].replace(chr(96), chr(39))}`\n")
        f.write("\n")
print((out/"summary.md").read_text()[:24000])
