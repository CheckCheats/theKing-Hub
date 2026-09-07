#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TheKing Publish v1.2 — RCWTK 一键发布: build → 混淆(v1.4) → 白名单加密 → manifest

流程:
  1. build.py 内嵌 theking.luau 单文件化 (games/<game>/dist/<name>-single.luau)
  2. obfuscate.py v1.4 混淆 (解密器自混淆 + 不透明 key + 数字/垃圾码; rename/虚表默认关)
  3. 全局白名单加密 -> dist/users.enc (默认仅 WoSh1N1D1e)
  4. 生成 dist/manifest.json (游戏清单, Loader 路由用)
  5. (--loader) Loader 单文件化 + 混淆 -> dist/theking-loader.luau

仓库: Gitee CheckCheat/the-king-hub + GitHub CheckCheats/theKing-Hub (均为 master, --push 双路覆盖)

用法:
    python tools/publish.py --loader                # 构建 Loader 单文件
    python tools/publish.py --game dungeon-raiders --no-class-archive --push
    python tools/publish.py --all                   # 发布全部游戏
    python tools/publish.py --all --no-weather      # 关天气播种 (调试)

产物: dist/theking-loader.luau + games/<g>/dist/<n>-single-obf.luau + dist/users.enc + dist/manifest.json
"""

import json
import random
import subprocess
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import build as build_mod
import obfuscate as obf
from repo_config import REPO_BRANCH, REPO_HTTPS, GITHUB_HTTPS, GITHUB_BRANCH, GITHUB_ROOT
import whitelist as wl

# ==================== 白名单 (逻辑在 tools/whitelist.py, 这里只用其接口) ====================
WHITE_KEY = wl.WHITE_KEY  # 白名单密钥 (发布端与 Loader 端必须一致)


def build_loader(use_weather: bool):
    """Loader 单文件化 + 混淆 -> dist/theking-loader.luau。"""
    loader_path = ROOT / "loader" / "theking-loader.luau"
    if not loader_path.exists():
        sys.exit(f"[publish] 找不到 Loader: {loader_path}")
    out_single = build_mod.build(loader_path)
    src = out_single.read_text(encoding="utf-8")
    rng = random.Random()
    obf_src = obf.obfuscate(src, rng, weather=use_weather)
    dist_dir = ROOT / "dist"
    dist_dir.mkdir(exist_ok=True)
    out_final = dist_dir / "theking-loader.luau"
    out_final.write_text(obf_src, encoding="utf-8")
    print(f"[publish] Loader 单文件混淆完成: {out_final} ({len(obf_src)} B)")
    return out_final


def intel_ids(game_dir: Path):
    """从 intel.md front matter 读 universeId / placeId / 分图 placeIds。"""
    import re
    intel = game_dir / "intel.md"
    uid, pid, extra = None, None, []
    if not intel.exists():
        return uid, pid, extra
    text = intel.read_text(encoding="utf-8")
    m = re.search(r"^universeId:\s*(\d+)", text, re.M)
    if m:
        uid = int(m.group(1))
    m = re.search(r"^placeId:\s*(\d+)", text, re.M)
    if m:
        pid = int(m.group(1))
    for key in ("lobbyPlaceId", "afkPlaceId"):
        m = re.search(rf"^{key}:\s*(\d+)", text, re.M)
        if m:
            extra.append(int(m.group(1)))
    return uid, pid, extra


def publish_game(game_dir: Path, use_weather: bool, skip_archive: bool = False):
    hub = game_dir / "hub.luau"
    if not hub.exists():
        print(f"[publish] 跳过 {game_dir.name}: 无 hub.luau")
        return None

    # 1. build
    out_single = build_mod.build(hub, skip_archive=skip_archive)
    print(f"[publish] 1/4 build 完成: {out_single.name}")

    # 2. obfuscate v1.2 (天气播种默认开)
    src = out_single.read_text(encoding="utf-8")
    rng = random.Random()
    obf_src = obf.obfuscate(src, rng, weather=use_weather)
    out_obf = out_single.with_name(out_single.stem + "-obf.luau")
    out_obf.write_text(obf_src, encoding="utf-8")
    print(f"[publish] 2/4 混淆完成: {out_obf.name} ({len(obf_src)} B)")

    # 3. manifest 条目 (合并到全局 manifest)
    uid, pid, extra_pids = intel_ids(game_dir)
    manifest_entry = {
        "game": game_dir.name,
        "universeId": uid,
        "placeId": pid,
        "version": "0.0.0",
        "script": f"games/{game_dir.name}/dist/{out_obf.name}",
    }
    place_ids = []
    if pid:
        place_ids.append(pid)
    for x in extra_pids:
        if x not in place_ids:
            place_ids.append(x)
    if len(place_ids) > 1:
        manifest_entry["placeIds"] = place_ids
    import re
    m = re.search(r"TheKing HUB \[([\d.]+)\]", hub.read_text(encoding="utf-8"))
    if m:
        manifest_entry["version"] = m.group(1)
    return manifest_entry


# 与 Loader EN_SORT 一致: 清单按英文名 A-Z
EN_SORT = {
    "clean-the-world": "Clean the WORLD",
    "cultivation-evermortal": "Cultivation: Evermortal",
    "dungeon-quest-reborn": "Dungeon Quest Reborn",
    "dungeon-raiders": "Dungeon Raiders",
    "fisch": "Fisch",
    "gakuran": "Gakuran",
    "grand-blue": "Grand Blue",
    "heavy-fishing": "Heavy Fishing",
    "heroes-rng": "Heroes RNG",
    "project-aura-rng": "Project Aura RNG",
    "sniper-arena": "Sniper Arena",
}


def manifest_sort_key(entry: dict):
    gid = str(entry.get("game") or "")
    return (EN_SORT.get(gid, gid).lower(), gid)


def merge_manifest(entries, out_path: Path):
    existing = {}
    if out_path.exists():
        try:
            existing = {e.get("game"): e for e in json.loads(out_path.read_text(encoding="utf-8"))}
        except Exception:
            existing = {}
    for e in entries:
        old = existing.get(e["game"], {})
        e["universeId"] = e.get("universeId") or old.get("universeId")
        e["placeId"] = e.get("placeId") or old.get("placeId")
        if old.get("placeIds") and not e.get("placeIds"):
            e["placeIds"] = old.get("placeIds")
        existing[e["game"]] = e
    ordered = sorted(existing.values(), key=manifest_sort_key)
    out_path.write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[publish] manifest 更新: {out_path} ({len(ordered)} 游戏, 英文名 A-Z)")


def iter_publish_files():
    """(源文件, 相对仓库路径) — Gitee / GitHub 同一套产物覆盖写入。"""
    pairs = [
        (ROOT / "dist" / "users.enc", Path("dist/users.enc")),
        (ROOT / "dist" / "manifest.json", Path("dist/manifest.json")),
        (ROOT / "dist" / "theking-loader.luau", Path("dist/theking-loader.luau")),
        (ROOT / "dist" / "run-loader-one-liner.luau", Path("dist/run-loader-one-liner.luau")),
        (ROOT / "windui-dist" / "main.lua", Path("windui-dist/main.lua")),
        (ROOT / "lib" / "vendor" / "rayfield-gen2.lua", Path("lib/vendor/rayfield-gen2.lua")),
        (ROOT / "lib" / "assets" / "theking-mark.png", Path("lib/assets/theking-mark.png")),
        (ROOT / "lib" / "assets" / "theking-mark.b64", Path("lib/assets/theking-mark.b64")),
    ]
    for g in sorted((ROOT / "games").iterdir()):
        if not g.is_dir():
            continue
        obf = g / "dist" / "hub-single-obf.luau"
        if obf.exists():
            pairs.append((obf, Path("games") / g.name / "dist" / "hub-single-obf.luau"))
    return pairs


def _git_no_proxy(co: Path, args: list, check: bool = True, capture: bool = False):
    cmd = [
        "git", "-C", str(co),
        "-c", "credential.helper=",
        "-c", "http.proxy=",
        "-c", "https.proxy=",
        *args,
    ]
    return subprocess.run(cmd, check=check, capture_output=capture, text=capture)


def copy_publish_into(dest_root: Path):
    """覆盖写入 (替换旧混淆包, 不留双份)。"""
    copied = 0
    for src, rel in iter_publish_files():
        if not src.exists():
            print(f"[publish] 跳过缺失文件: {src}")
            continue
        dst = dest_root / rel
        if src.resolve() == dst.resolve():
            copied += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(src.read_bytes())
        copied += 1
    return copied


def _commit_relpaths(co: Path, rels: list, message: str) -> bool:
    rels = [str(r).replace("\\", "/") for r in rels]
    if not rels:
        return False
    _git_no_proxy(co, ["add", "-f", "--", *rels], check=True)
    st = _git_no_proxy(co, ["status", "--short", "--", *rels], check=True, capture=True)
    out = (st.stdout or "").strip()
    if not out:
        print(f"[publish] {co.name or 'github'} 产物无变更")
        return False
    _git_no_proxy(co, ["commit", "-m", message], check=True)
    return True


def sync_and_push(skip_class_archive: bool = False):
    """产物覆盖进 Gitee 检出 + 本仓 GitHub, 两条都推 master。"""
    rels = [rel for src, rel in iter_publish_files() if src.exists()]
    msg = "publish: 替换混淆产物 (loader+games)"

    co = wl.ensure_checkout()
    n = copy_publish_into(co)
    print(f"[publish] Gitee 检出已覆盖 {n} 个文件")
    if _commit_relpaths(co, rels, msg):
        _git_no_proxy(co, ["push", wl.gitee_url_with_creds(), REPO_BRANCH], check=True)
        print(f"[publish] 已推 Gitee {REPO_HTTPS} ({REPO_BRANCH})")
    else:
        print("[publish] Gitee 跳过推送")

    print(f"[publish] GitHub 路径即本仓, 覆盖 {copy_publish_into(GITHUB_ROOT)} 个文件")
    if _commit_relpaths(GITHUB_ROOT, rels, msg):
        _git_no_proxy(GITHUB_ROOT, ["push", "origin", GITHUB_BRANCH], check=True)
        print(f"[publish] 已推 GitHub {GITHUB_HTTPS} ({GITHUB_BRANCH})")
    else:
        print("[publish] GitHub 跳过推送")
    _ = skip_class_archive


def main():
    import argparse
    ap = argparse.ArgumentParser(description="TheKing Publish v1.2")
    ap.add_argument("--game", help="发布单个游戏目录名 (如 heroes-rng)")
    ap.add_argument("--all", action="store_true", help="发布 games/ 下全部")
    ap.add_argument("--loader", action="store_true", help="构建 Loader 单文件 (含混淆)")
    ap.add_argument("--no-class-archive", action="store_true", help="不内嵌、不推送 class-archive.luau")
    ap.add_argument("--no-weather", action="store_true", help="关闭天气API播种 (调试用)")
    ap.add_argument("--push", action="store_true", help="构建后覆盖推送到 Gitee 与 GitHub (master)")
    args = ap.parse_args()

    use_weather = not args.no_weather
    dist_dir = ROOT / "dist"
    dist_dir.mkdir(exist_ok=True)

    # Loader 单文件
    if args.loader:
        build_loader(use_weather)

    # 白名单只在本机生成, 游戏发布不推 users.enc (改名单用 whitelist.py push)
    if not args.game and not args.all:
        entries = wl.read_whitelist()
        (dist_dir / "users.enc").write_bytes(wl.encode_list(entries))
        print(f"[publish] 白名单加密: {len(entries)} 用户 -> dist/users.enc (未纳入游戏推送)")
    else:
        print("[publish] 跳过白名单推送 (游戏包不带 users.enc)")

    # 游戏发布
    games_dir = ROOT / "games"
    if args.game:
        game_dir = games_dir / args.game
        if not game_dir.exists():
            sys.exit(f"[publish] 游戏目录不存在: {game_dir}")
        targets = [game_dir]
    elif args.all:
        targets = sorted([p for p in games_dir.iterdir() if p.is_dir()])
    else:
        targets = []

    skip_archive = args.no_class_archive
    entries2 = []
    for g in targets:
        e = publish_game(g, use_weather, skip_archive=skip_archive)
        if e:
            entries2.append(e)

    if entries2:
        merge_manifest(entries2, dist_dir / "manifest.json")

    print(f"\n[publish] 完成。--push 会覆盖推送 Gitee + GitHub (均为 master):")
    print(f"  dist/theking-loader.luau   (仅 --loader 时)")
    print(f"  dist/manifest.json         (游戏清单)")
    for e in entries2:
        print(f"  {e['script']}")

    if args.push:
        sync_and_push(skip_class_archive=skip_archive)


if __name__ == "__main__":
    main()
