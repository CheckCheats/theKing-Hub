import pathlib

root = pathlib.Path("games/sniper-arena")
parts = [(root / f".inj-chunk{i}.txt").read_text() for i in range(4)]

for i, p in enumerate(parts[:3]):
    if i == 0:
        src = '_G.RCWTK_B64="' + p + '"\nprint("[RCWTK] chunk0")'
    else:
        src = '_G.RCWTK_B64=_G.RCWTK_B64.."' + p + '"\nprint("[RCWTK] chunk' + str(i) + '")'
    (root / f".inj-step{i}.lua").write_text(src, encoding="utf-8")

boot = """local reg=rawget(_G,"RCWTK_SNIPER_SA")
if type(reg)=="table" and type(reg.restore)=="function" then pcall(reg.restore) end
local key="[🔥UPD] Sniper Arena"
if type(_G.RCWTK_REGISTRY)=="table" and type(_G.RCWTK_REGISTRY[key])=="function" then pcall(_G.RCWTK_REGISTRY[key]) task.wait() end
"""
boot += '_G.RCWTK_B64=_G.RCWTK_B64.."' + parts[3] + '"\n'
boot += "loadstring(crypt.base64decode(_G.RCWTK_B64))()\n_G.RCWTK_B64=nil\n"
(root / ".inj-step3.lua").write_text(boot, encoding="utf-8")

for i in range(4):
    print(i, (root / f".inj-step{i}.lua").stat().st_size)
