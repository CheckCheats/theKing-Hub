# -*- coding: utf-8 -*-
"""RCWTK 静态门: 寄存器压力 + 常见会编不过/假死的写法。

用法:
    python tools/check_hub.py games/dungeon-raiders/hub.luau
    python tools/check_hub.py --all
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from luau_reg_pressure import analyze_path, format_report

ROOT = Path(__file__).resolve().parent.parent
WARN_REGS = 160
FAIL_REGS = 195

WAIT_RE = re.compile(
    r""":WaitForChild\(\s*(['"][^'"]+['"]|[A-Za-z_][\w.]*)\s*\)"""
)
DRAWING_NEW_RE = re.compile(r"\bDrawing\s*\.\s*new\s*\(")
NAKED_WHILE_RE = re.compile(r"task\.spawn\s*\(\s*function\s*\(\s*\)[\s\S]{0,80}?while\s+true\s+do", re.M)
IIFE_RE = re.compile(r"\)\s*\(\s*function\s*\(\s*\)|\(function\s*\(\s*\)")


def scan_text(src: str) -> list[tuple[str, int, str]]:
    issues = []
    for i, line in enumerate(src.splitlines(), 1):
        if "--" in line:
            code = line.split("--", 1)[0]
        else:
            code = line
        if WAIT_RE.search(code):
            issues.append(("warn", i, "WaitForChild 无 timeout, 游戏更新后会假死; 写成 WaitForChild(名, 10)"))
        if DRAWING_NEW_RE.search(code):
            issues.append(("warn", i, "Drawing.new 在部分注入器隐形/崩溃; 用 TheKing.Draw (ScreenGui)"))
    if NAKED_WHILE_RE.search(src):
        issues.append(("warn", 0, "发现 task.spawn + while true; 循环必须 StartLoop/StopLoop"))
    return issues


def check_file(path: Path) -> int:
    src = path.read_text(encoding="utf-8-sig")
    result = analyze_path(str(path))
    print(format_report(result, WARN_REGS))
    rc = 0
    for f in result["functions"]:
        if f["peak"] >= FAIL_REGS:
            print(f"ERROR 函数 {f['name']} 峰值 {f['peak']} ≥ {FAIL_REGS}: Luau 会编不过 (limit 200)")
            print("  收法: 1) 整段包进 (function() ... end)()  2) 相关状态收单表  3) 方法写成 function T.foo() 而不是再 local function")
            rc = 1
        elif f["peak"] >= WARN_REGS:
            print(f"WARN  函数 {f['name']} 峰值 {f['peak']} ≥ {WARN_REGS}: 再加功能前先收表/拆闭包")
    if result["main_peak"] >= 80 and not IIFE_RE.search(src):
        print("WARN  主块峰值较高且未见 IIFE; 骨架请用 ;(function() ... end)() 包业务")
    for level, ln, msg in scan_text(src):
        loc = f"{path.name}:{ln}" if ln else path.name
        print(f"{level.upper():5} {loc}  {msg}")
        if level == "error":
            rc = 1
    if rc == 0:
        print("静态门通过")
    return rc


def main(argv: list[str]) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if len(argv) >= 2 and argv[1] == "--all":
        files = sorted((ROOT / "games").glob("*/hub.luau"))
        files.append(ROOT / "lib" / "theking.luau")
        worst = 0
        for f in files:
            if not f.exists():
                continue
            print("=" * 60)
            worst = max(worst, check_file(f))
        return worst
    if len(argv) < 2:
        print("用法: python tools/check_hub.py <hub.luau> | --all")
        return 2
    return check_file(Path(argv[1]))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
