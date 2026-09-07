# -*- coding: utf-8 -*-
"""Luau 寄存器压力: 每个函数 proto 的存活 local 峰值 (上限 200)。

嵌套函数体有独立 200 格; 但 `local function` 名字本身占父函数一格。
do-end 结束后可释放存活集 (近似 Luau 生命周期分配)。
"""
from __future__ import annotations

import io
import sys

KEYWORDS = {
    "if", "then", "elseif", "else", "end", "for", "while", "do", "function",
    "local", "repeat", "until", "return", "break", "continue", "true", "false",
    "nil", "and", "or", "not", "in", "goto",
}


def tokenize(src: str):
    toks = []
    i, n, line = 0, len(src), 1
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r":
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            if i + 2 < n and src[i + 2] == "[":
                eq = 0
                j = i + 3
                while j < n and src[j] == "=":
                    eq += 1
                    j += 1
                if j < n and src[j] == "[":
                    close = "]" + "=" * eq + "]"
                    ep = src.find(close, j + 1)
                    if ep == -1:
                        break
                    line += src.count("\n", i, ep)
                    i = ep + len(close)
                    continue
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "[" and i + 1 < n and src[i + 1] in "=[":
            eq = 0
            j = i + 1
            while j < n and src[j] == "=":
                eq += 1
                j += 1
            if j < n and src[j] == "[":
                close = "]" + "=" * eq + "]"
                ep = src.find(close, j + 1)
                if ep == -1:
                    break
                line += src.count("\n", i, ep)
                toks.append(("str", "", line))
                i = ep + len(close)
                continue
        if c in "'\"":
            q = c
            j = i + 1
            while j < n and src[j] != q:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == "\n":
                    break
                j += 1
            line += src.count("\n", i, j + 1)
            toks.append(("str", "", line))
            i = j + 1
            continue
        if c.isalpha() or c == "_":
            j = i
            while j < n and (src[j].isalnum() or src[j] == "_"):
                j += 1
            w = src[i:j]
            toks.append(("kw" if w in KEYWORDS else "name", w, line))
            i = j
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            j = i
            while j < n and (src[j].isalnum() or src[j] in "_.xXpP"):
                j += 1
            toks.append(("num", "", line))
            i = j
            continue
        toks.append(("sym", c, line))
        i += 1
    return toks


class Frame:
    def __init__(self, kind: str, name: str, line: int):
        self.kind = kind
        self.name = name
        self.line = line
        self.alive = set()
        self.blocks = [set()]
        self.peak = 0
        self.peak_line = line
        self.declared = []

    def bump(self, line: int):
        n = len(self.alive)
        if n > self.peak:
            self.peak = n
            self.peak_line = line

    def add(self, name: str, line: int):
        self.alive.add(name)
        self.blocks[-1].add(name)
        self.declared.append((name, line))
        self.bump(line)

    def push_block(self):
        self.blocks.append(set())

    def pop_block(self):
        if len(self.blocks) <= 1:
            return
        gone = self.blocks.pop()
        self.alive -= gone


def _skip_func_name(toks, i):
    n = len(toks)
    name_parts = []
    if i < n and toks[i][0] == "name":
        name_parts.append(toks[i][1])
        i += 1
        while i + 1 < n and toks[i][1] in (".", ":") and toks[i + 1][0] == "name":
            name_parts.append(toks[i + 1][1])
            i += 2
    return i, ".".join(name_parts) if name_parts else "(anon)"


def _parse_params(toks, i):
    n = len(toks)
    names = []
    if i >= n or toks[i][1] != "(":
        return i, names
    i += 1
    while i < n and toks[i][1] != ")":
        if toks[i][0] == "name":
            names.append(toks[i][1])
        elif toks[i][1] == "...":
            names.append("...")
        i += 1
    if i < n and toks[i][1] == ")":
        i += 1
    return i, names


def analyze_source(src: str) -> dict:
    toks = tokenize(src)
    n = len(toks)
    frames = [Frame("chunk", "<main>", 1)]
    reports = []
    pending_loop = 0
    i = 0
    while i < n:
        k, t, ln = toks[i]
        frames[-1].bump(ln)

        if k == "kw" and t in ("for", "while"):
            pending_loop += 1
            if t == "for":
                j = i + 1
                while j < n and toks[j][1] not in ("=", "in", "do"):
                    if toks[j][0] == "name":
                        frames[-1].add(toks[j][1], toks[j][2])
                    j += 1
        elif k == "kw" and t == "do":
            frames[-1].push_block()
            if pending_loop > 0:
                pending_loop -= 1
        elif k == "kw" and t in ("if", "repeat"):
            frames[-1].push_block()
        elif k == "kw" and t in ("elseif", "else"):
            frames[-1].pop_block()
            frames[-1].push_block()
        elif k == "kw" and t == "function":
            is_local = i > 0 and toks[i - 1][1] == "local"
            j, fname = _skip_func_name(toks, i + 1)
            j, params = _parse_params(toks, j)
            child = Frame("function", fname, ln)
            for p in params:
                child.add(p, ln)
            if not is_local and fname != "(anon)" and "." not in fname and frames[-1].kind == "chunk":
                # 裸 function foo() 在主块是全局, 不占 local; 表字段 function T.x 也不占
                pass
            frames.append(child)
            i = j - 1
        elif k == "kw" and t == "end":
            top = frames[-1]
            if len(top.blocks) > 1:
                top.pop_block()
            else:
                if len(frames) > 1:
                    done = frames.pop()
                    reports.append(done)
        elif k == "kw" and t == "until":
            frames[-1].pop_block()
        elif k == "kw" and t == "local":
            j = i + 1
            if j < n and toks[j][1] == "function":
                nm = toks[j + 1][1] if j + 1 < n else "(anon)"
                frames[-1].add(nm, ln)
                i = j - 1
            else:
                while j < n:
                    kj, tj, lj = toks[j]
                    if tj == ",":
                        j += 1
                        continue
                    if tj == "=":
                        break
                    if kj == "name":
                        frames[-1].add(tj, lj)
                        j += 1
                        continue
                    break
                i = j - 1
        i += 1

    while len(frames) > 1:
        reports.append(frames.pop())
    main = frames[0]
    reports.append(main)

    reports.sort(key=lambda f: -f.peak)
    return {
        "main_peak": main.peak,
        "main_peak_line": main.peak_line,
        "main_local_fns": sum(1 for n, _ in main.declared),
        "functions": [
            {
                "name": f.name,
                "line": f.line,
                "peak": f.peak,
                "peak_line": f.peak_line,
                "kind": f.kind,
            }
            for f in reports
        ],
    }


def analyze_path(path: str) -> dict:
    src = io.open(path, "r", encoding="utf-8-sig").read()
    out = analyze_source(src)
    out["path"] = path
    return out


def format_report(result: dict, warn_at: int = 160, top_n: int = 12) -> str:
    lines = []
    lines.append(f"{result.get('path', '')}")
    lines.append(f"主块峰值: {result['main_peak']} @ 行 {result['main_peak_line']}  (上限 200, 告警 {warn_at})")
    hot = [f for f in result["functions"] if f["peak"] >= min(40, warn_at // 4)]
    lines.append("函数峰值 (高→低):")
    for f in hot[:top_n]:
        mark = " FAIL" if f["peak"] >= 195 else (" WARN" if f["peak"] >= warn_at else "")
        lines.append(
            f"  {f['peak']:3d}  {f['name']:<28} 定义@{f['line']} 峰值行@{f['peak_line']}{mark}"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python tools/luau_reg_pressure.py <file.luau>")
        sys.exit(2)
    r = analyze_path(sys.argv[1])
    print(format_report(r))
    sys.exit(1 if any(f["peak"] >= 195 for f in r["functions"]) else 0)
