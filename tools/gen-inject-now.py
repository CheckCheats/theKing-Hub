import pathlib

b64 = pathlib.Path("games/sniper-arena/.inject.b64").read_text().strip()
boot = (
    'local reg=rawget(_G,"RCWTK_SNIPER_SA")\n'
    'if type(reg)=="table" and type(reg.restore)=="function" then pcall(reg.restore) end\n'
    'local key="[🔥UPD] Sniper Arena"\n'
    'if type(_G.RCWTK_REGISTRY)=="table" and type(_G.RCWTK_REGISTRY[key])=="function" then pcall(_G.RCWTK_REGISTRY[key]) task.wait() end\n'
    f'loadstring(crypt.base64decode("{b64}"))()\n'
)
pathlib.Path("games/sniper-arena/inject-now.lua").write_text(boot, encoding="utf-8")
print(len(boot))
