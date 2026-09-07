#!/usr/bin/env python3
"""RCWTK 跨档案经验召回工具 — 自迭代引擎的"读取"端。

用法:
  python tools/recall.py <关键词>          # 按游戏目录名 / genre / universeId / placeId / 显示名 召回
  python tools/recall.py fishing           # → 命中 genre=fishing 的模式库 + 两个游戏档案
  python tools/recall.py 5750914919        # → universeId 命中 fisch → 推荐 patterns/fishing.md
  python tools/recall.py <新游戏名>         # → 无档案时报"全新类型", 有同类型模式库则推荐

召回层级 (由近及远):
  1. 该游戏 intel.md / devlog.md (若有档案)
  2. docs/patterns/<genre>.md (同类型套路, 自迭代核心)
  3. docs/engine-memory.md (引擎层, 恒定召回)
"""
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):  # AI 工具链按 UTF-8 读输出; 真 cmd 下失败也不致命
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except (ValueError, OSError):
        pass

ROOT = Path(__file__).resolve().parent.parent
GAMES = ROOT / "games"
PATTERNS = ROOT / "docs" / "patterns"
ENGINE_MEMORY = ROOT / "docs" / "engine-memory.md"


def parse_front_matter(text):
    """极简 YAML front matter 解析: 只取顶层 key: value 行。"""
    meta = {}
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return meta
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if ":" in line and not line.startswith((" ", "\t")):
            key, _, val = line.partition(":")
            meta[key.strip()] = val.strip().strip('"')
    return meta


def find_game(query):
    """按目录名/genre/universeId/placeId/显示名匹配游戏目录。返回 (dir, meta) 或 (None, None)。"""
    q = query.lower()
    for d in sorted(GAMES.iterdir()):
        intel = d / "intel.md"
        if not intel.exists():
            continue
        meta = parse_front_matter(intel.read_text(encoding="utf-8"))
        candidates = (
            d.name.lower(),
            meta.get("genre", "").lower(),
            meta.get("game", "").lower(),
            meta.get("universeId", ""),
            meta.get("placeId", ""),
        )
        if q in candidates:
            return d, meta
    return None, None


def recall(query):
    game_dir, meta = find_game(query)
    hits = []
    if game_dir:
        genre = meta.get("genre", "")
        hits.append(("游戏档案", meta.get("game", game_dir.name),
                     [str(game_dir / "intel.md"), str(game_dir / "devlog.md")]))
        pattern = PATTERNS / f"{genre}.md" if genre else None
        if pattern and pattern.exists():
            hits.append(("同类型模式库 (自迭代)", f"{genre} 类套路已沉淀", [str(pattern)]))
        else:
            hits.append(("同类型模式库", f"genre={genre or '未标注'}, 模式库尚未建立 — 收工时注意提升经验", []))
    else:
        pattern = PATTERNS / f"{query.lower()}.md"
        if pattern.exists():
            hits.append(("同类型模式库 (按 genre 直查)", query.lower(), [str(pattern)]))
        else:
            hits.append(("游戏档案", "无匹配档案 — 全新游戏, 从 templates/intel-template.md 建档", []))

    hits.append(("引擎记忆", "恒定召回", [str(ENGINE_MEMORY)]))
    return hits


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)
    for tag, desc, files in recall(sys.argv[1]):
        print(f"\n== {tag}: {desc}")
        for f in files:
            print(f"   -> {f}")
    print("\n(召回完成: 会话开始时按上述顺序读文件)")


if __name__ == "__main__":
    main()
