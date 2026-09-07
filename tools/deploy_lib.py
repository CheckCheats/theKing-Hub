"""Deploy lib/theking.luau to Potassium workspace"""
import shutil
src = r'D:\BuildProject\RoLua\Core\lib\theking.luau'
dsts = [
    r'C:\Users\CARSER\AppData\Local\Potassium\workspace\lib\theking.luau',
    r'C:\Users\CARSER\AppData\Local\Potassium\workspace\theking.luau',
]
for d in dsts:
    shutil.copyfile(src, d)
    print('deployed to:', d)

# Force-clear uikit cache in workspace (it's stored in _G of the running session,
# but workspace files don't hold runtime state - so this only updates source).
