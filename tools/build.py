#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RCWTK 单文件构建器 — 把 lib/theking.luau 内嵌进 hub.luau, 产出可分发的独立脚本。

开发态: hub.luau 通过 readfile("lib/theking.luau") 加载运行时库 (依赖本机目录结构)
发布态: 本脚本把库源码内嵌, 产物不依赖任何本地文件 (除 WindUI CDN)

用法:
    python tools/build.py games/sol-rng/hub.luau          # 指定入口
    python tools/build.py --all                           # 构建 games/ 下全部

产物: <hub同目录>/dist/<名字>-single.luau
"""

import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # Windows 控制台中文输出

ROOT = Path(__file__).resolve().parent.parent
LIB_PATH = ROOT / "lib" / "theking.luau"

# 匹配标准加载行: local TheKing = loadstring(readfile("...lib/theking.luau"))(
LOAD_PATTERN = re.compile(
    r'loadstring\s*\(\s*readfile\s*\(\s*["\'][^"\']*lib/theking\.luau["\']\s*\)\s*\)\s*\('
)

# 匹配自定义加载函数调用: local TheKing = loadTheKing()({
# 提取 config 参数的起点: 匹配 <标识符>(({ 中的 "({" 位置
CUSTOM_LOAD_PATTERN = re.compile(
    r"local\s+TheKing\s*=\s*[A-Za-z_][A-Za-z0-9_]*\s*\(\s*\)\s*\("
)

# 匹配变量加载: local TheKing = loadstring(libSource)({  (gakuran / sniper-arena 模式)
VARIABLE_LOAD_PATTERN = re.compile(
    r"local\s+TheKing\s*=\s*loadstring\s*\(\s*[A-Za-z_][A-Za-z0-9_]*\s*\)\s*\("
)

# 开发态库探测: 在 loadstring(libSource) 之前用 isfile 找 theking.luau, 找不到就 error。
# 只替换加载行会把这段留在发布包里 — 别人注入器 workspace 没有该文件, 内嵌库还没跑就炸。
LIB_PROBE_PATTERN = re.compile(
    r"(?:^[ \t]*--[^\n]*\n)*"
    r"local\s+LIB_CANDIDATES\s*=\s*\{[\s\S]*?\}\s*"
    r"local\s+libSource\s*=\s*nil\s*"
    r"for\b[\s\S]*?\bend\s*\bend\s*"
    r"if\s+not\s+libSource\s+then\s+error\([\s\S]*?\)\s*end\s*",
    re.M,
)


def _skip_comment(src: str, i: int) -> int:
    """从 `--` 起跳到注释结束后的位置。"""
    if src.startswith("--[[", i):
        close = src.find("]]", i + 4)
        return len(src) if close < 0 else close + 2
    if src.startswith("--[=[", i):
        close = src.find("]=]", i + 5)
        return len(src) if close < 0 else close + 3
    nl = src.find("\n", i)
    return len(src) if nl < 0 else nl + 1


def _skip_long_string(src: str, i: int) -> int:
    """从 `[[` / `[=[` 起跳到长字符串结束后的位置。"""
    if src.startswith("[=[", i):
        close = src.find("]=]", i + 3)
        return len(src) if close < 0 else close + 3
    close = src.find("]]", i + 2)
    return len(src) if close < 0 else close + 2


def skip_to_config_brace(hub_src: str, start: int):
    """从 start 起跳过空白与注释, 返回配置表 '{' 的下标 (找不到返回 None)。"""
    i = start
    n = len(hub_src)
    while i < n:
        ch = hub_src[i]
        if ch in " \t\r\n":
            i += 1
        elif hub_src.startswith("--", i):
            # 注释: 长注释 --[[ ]] 或行注释 (注释里的括号不参与配平)
            skipped = _skip_comment(hub_src, i)
            i = skipped if skipped > i else i + 1
            continue
        elif ch == "{":
            return i
        else:
            return None  # 不是紧跟配置表, 交给调用方判断
    return None


def find_config_start(hub_src: str):
    """返回 config 参数区起点 (统一指向 '{' 本身) 与加载类型, 找不到返回 (None, None)。

    坑记录: 这里必须指向 '{' 本身, 不能指向 '{' 之后 —— 内嵌模板是
    `_G.RCWTK_LIB_CONFIG = (<args_src>)`, args_src 需要自带外层大括号;
    早期版本对自定义/变量加载返回 '{' 之后的位置, 产物变成
    `_G.RCWTK_LIB_CONFIG = (GameName = "X",)` -> 语法错误。
    """
    # 标准行: loadstring(readfile("...lib/theking.luau"))({
    m = LOAD_PATTERN.search(hub_src)
    if m:
        brace = skip_to_config_brace(hub_src, m.end())
        if brace is not None:
            return brace, None
    # 变量加载: local TheKing = loadstring(libSource)({
    m2 = VARIABLE_LOAD_PATTERN.search(hub_src)
    if m2:
        brace = skip_to_config_brace(hub_src, m2.end())
        if brace is not None:
            return brace, "variable"
    # 自定义加载函数: local TheKing = loadTheKing()({
    m3 = CUSTOM_LOAD_PATTERN.search(hub_src)
    if m3:
        brace = skip_to_config_brace(hub_src, m3.end())
        if brace is not None:
            return brace, "custom"
    return None, None


def build(hub_path: Path, skip_archive: bool = False) -> Path:
    if not LIB_PATH.exists():
        sys.exit(f"[build] 找不到运行时库: {LIB_PATH}")
    if not hub_path.exists():
        sys.exit(f"[build] 找不到入口脚本: {hub_path}")

    lib_src = LIB_PATH.read_text(encoding="utf-8")
    hub_src = hub_path.read_text(encoding="utf-8")

    # 发布态无仓库文件: 把 Logo 的 b64 写进产物, 运行时再解成 theking-mark.png
    b64_file = ROOT / "lib" / "assets" / "theking-mark.b64"
    if b64_file.exists():
        b64 = b64_file.read_text(encoding="ascii").strip()
        lib_src = (
            "-- brand b64 injected by build.py\n"
            "pcall(function()\n"
            "    if type(writefile) == \"function\" then\n"
            f"        writefile(\"theking-mark.b64\", [[{b64}]])\n"
            "    end\n"
            "end)\n"
            + lib_src
        )


    start, load_kind = find_config_start(hub_src)
    if start is None:
        sys.exit("[build] 未找到 theking.luau 标准加载行 (loadstring(readfile(...lib/theking.luau)) 或 local TheKing = loadXxx()({")

    # 提取 loadstring(...)({...}) 的配置参数部分 (括号配平, 跳过注释里的括号)
    depth = 1
    i = start
    in_str = None
    while i < len(hub_src) and depth > 0:
        ch = hub_src[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == in_str:
                in_str = None
        elif hub_src.startswith("--", i):
            # 注释内容不参与配平 (配置表里常写 `-- 与 intel.md 一致 (隔离键)` 这类带括号注释)
            skipped = _skip_comment(hub_src, i)
            i = skipped if skipped > i else i + 1
            continue
        elif hub_src.startswith("[[", i) or hub_src.startswith("[=[", i):
            i = _skip_long_string(hub_src, i)
            continue
        elif ch in "\"'":
            in_str = ch
        elif ch in "({":
            depth += 1
        elif ch in ")}":
            depth -= 1
        i += 1
    if depth != 0:
        sys.exit("[build] 括号配平失败: 加载行参数区无法解析")
    args_src = hub_src[start : i - 1].strip()  # 去掉最外层收尾的 ')'

    # 内嵌模板: IIFE 必须是变参 (function(...) ... end)()
    #   原因: lib/theking.luau 顶层用 local passed = ... 解构配置 (开发态 loadstring(lib)({...}) 走的正是这条路径),
    #   而 ... 只能出现在变参函数里 —— 包进非变参 function() 会让 Luau 在编译期直接报
    #   "Cannot use '...' outside a vararg function" (Real 里被截断显示成 "Canno"), 整个产物 loadstring 直接 nil。
    #   发布态 ... 为空 -> lib 自动回落到下面这行注入的 _G.RCWTK_LIB_CONFIG。
    embedded = (
        "(function(...)\n"
        f"    _G.RCWTK_LIB_CONFIG = ({args_src})\n"
        f"{lib_src}\n"
        "end)()"
    )

    # 防回归: lib 顶层若用 ... 接配置, 内嵌 IIFE 必须是变参, 否则 Luau 编译期直接判死产物
    if re.search(r"^\s*local\s+passed\s*=\s*\.\.\.", lib_src, re.M):
        assert "(function(...)" in embedded, "内嵌模板必须为变参 IIFE, 否则 lib 顶层的 ... 会导致编译失败"

    # 替换整行 (含 local TheKing = ... 或 loadstring 部分)
    if load_kind in ("custom", "variable"):
        # 找到 local TheKing = 的起点
        if load_kind == "custom":
            pat = CUSTOM_LOAD_PATTERN
        else:
            pat = VARIABLE_LOAD_PATTERN
        line_start = hub_src.rfind("\n", 0, pat.search(hub_src).start()) + 1
        prefix = hub_src[:line_start]
        if load_kind == "variable":
            # 探测块和 loadstring(libSource) 之间可能还有别的语句 (如偷看存档),
            # 只删探测, 中间代码保留。
            stripped, n = LIB_PROBE_PATTERN.subn("", prefix, count=1)
            if n:
                prefix = stripped
        out_src = prefix + "local TheKing = " + embedded + hub_src[i:]
    else:
        m = LOAD_PATTERN.search(hub_src)
        out_src = hub_src[: m.start()] + embedded + hub_src[i:]

    if re.search(r'error\(\s*["\']\[TheKing\] 找不到 theking\.luau', out_src):
        sys.exit("[build] 产物仍含开发态库探测 error, 别人注入会找不到 theking.luau")

    # 头部加构建标记
    version_m = re.search(r"TheKing HUB \[([\d.]+)\]", hub_src)
    ver = version_m.group(1) if version_m else "?.?.?"
    header = (
        f"--[[ RCWTK 发布构建 | {hub_path.name} v{ver} | 内嵌 RCWTK lib | "
        f"由 tools/build.py 生成, 请勿手改 ]]\n"
    )

    sidecar = hub_path.parent / "class-archive.luau"
    marker = "local CLASS_ARCHIVE_EMBED = nil"
    if sidecar.exists() and not skip_archive and marker in out_src:
        archive_body = sidecar.read_text(encoding="utf-8")
        if "]===]" in archive_body:
            sys.exit("[build] class-archive.luau 含 ]===], 无法用长字符串内嵌")
        out_src = out_src.replace(
            marker,
            "local CLASS_ARCHIVE_EMBED = [===[" + archive_body + "]===]",
            1,
        )
        print("[build] 已内嵌 class-archive.luau")
    elif skip_archive:
        print("[build] 跳过职业档案内嵌 (--no-class-archive)")
    elif sidecar.exists() and marker not in out_src:
        print("[build] hub 已自带职业表, 跳过 sidecar 内嵌")

    out_dir = hub_path.parent / "dist"
    out_dir.mkdir(exist_ok=True)
    out_path = out_dir / f"{hub_path.stem}-single.luau"
    out_path.write_text(header + out_src, encoding="utf-8")
    print(f"[build] 完成: {out_path} ({out_path.stat().st_size / 1024:.0f} KB)")
    return out_path


def main():
    argv = sys.argv[1:]
    if not argv:
        sys.exit(__doc__)
    if argv[0] == "--all":
        hubs = sorted((ROOT / "games").glob("*/hub.luau"))
        if not hubs:
            sys.exit("[build] games/ 下没有 hub.luau")
        for h in hubs:
            build(h)
    else:
        p = Path(argv[0])
        build(p if p.is_absolute() else ROOT / p)


if __name__ == "__main__":
    main()
