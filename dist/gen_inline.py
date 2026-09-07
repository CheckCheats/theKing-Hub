import os

src_path = r'D:\BuildProject\RoLua\Core\games\dungeon-raiders\hub.luau'
with open(src_path, 'rb') as f:
    data = f.read()

# LF only
data = data.replace(b'\r\n', b'\n').replace(b'\r', b'')
src = data.decode('utf-8', errors='replace')

# Escape for Lua double-quoted string
def lua_escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

escaped = lua_escape(src)
code = 'local SRC = "' + escaped + '"\n'
code += 'local fn, err = loadstring(SRC, "hub.luau")\n'
code += 'if not fn then print("ERR:"..tostring(err)) return end\n'
code += 'local ok,re = pcall(fn)\n'
code += 'if not ok then print("RUNTIME:"..tostring(re)) else print("OK") end\n'

out = r'D:\BuildProject\RoLua\Core\dist\test_inline.lua'
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, 'w', encoding='utf-8') as f:
    f.write(code)
print(f'written, code size: {len(code)}')
