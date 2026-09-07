"""Force overwrite hub.luau in workspace root"""
import shutil
src = r'D:\BuildProject\RoLua\Core\games\dungeon-raiders\hub.luau'
dst_root = r'C:\Users\CARSER\AppData\Local\Potassium\workspace\hub.luau'
shutil.copyfile(src, dst_root)
print('deployed to root:', dst_root)
