import pathlib

src = pathlib.Path("games/sniper-arena/hub.luau").read_text(encoding="utf-8")
lines = src.splitlines()
start = 0
if lines and lines[0].startswith("--[["):
    for i, line in enumerate(lines):
        if line.strip() == "]]":
            start = i + 1
            break
payload = "\n".join(lines[start:]).strip()
pathlib.Path("games/sniper-arena/.inject-payload.lua").write_text(payload, encoding="utf-8")
print(len(payload))
