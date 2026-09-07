"""
RCWTK 部署: 仓库 -> potassium workspace (autoexec 双路径全覆盖, 每次改完 hub 必跑)

用法:
  python tools/deploy_dr.py             # 双路径同步
  python tools/deploy_dr.py --check     # 打印磁盘版本与钾 VFS 版本差异

实现要点:
  1. 读取 ScriptVersion 自动同步到 DR_HUB_v<版本号> tag (避免钾 autoexec 误判为旧版本跳过加载)
  2. 写入临时文件 + shutil.copyfile, 避免 deploy 写到一半被钾 autoexec 半截热替换
  3. --check 同时显示 mtime, 防止本地修改未 deploy 的遗漏
"""
import shutil
import re
import sys
import os
import tempfile

# RCWTK 部署: 仓库 -> potassium workspace (autoexec 双路径全覆盖, 每次改完 hub 必跑)
src = 'games/dungeon-raiders/hub.luau'
dsts = [
    r'C:\Users\CARSER\AppData\Local\Potassium\workspace\games\dungeon-raiders\hub.luau',
    r'C:\Users\CARSER\AppData\Local\Potassium\workspace\dungeon-raiders\hub.luau',
]
CHECK_ONLY = '--check' in sys.argv

t = open(src, encoding='utf-8').read()
m = re.search(r'ScriptVersion = .([\d.]+).', t)
ver = m.group(1) if m else '?'
expected_tag = 'DR_HUB_v' + ver.replace('.', '')

# 同步 tag 到最新版本号 (钾 autoexec 用 tag 判重, tag 变才重载)
if 'DR_HUB_v' in t:
    t = re.sub(r'DR_HUB_v\d+', expected_tag, t)

if CHECK_ONLY:
    src_mtime = os.path.getmtime(src)
    print('disk: v%s  (%d bytes, mtime=%.0f)' % (ver, len(t), src_mtime))
    for d in dsts:
        try:
            w = open(d, encoding='utf-8').read()
            v = re.search(r'ScriptVersion = .([\d.]+).', w)
            tag = re.search(r'DR_HUB_v\d+', w)
            dst_mtime = os.path.getmtime(d)
            stale = (dst_mtime < src_mtime - 0.5)
            print('  v%s  %s  mtime=%.0f%s  %s' % (
                v.group(1) if v else '?',
                tag.group(0) if tag else '?',
                dst_mtime,
                '  [STALE! run deploy]' if stale else '',
                d,
            ))
        except OSError:
            print('  (缺失)  %s' % d)
    sys.exit(0)

# 写到临时文件避免半截状态 (钾 autoexec 在写入过程中可能读到坏文件)
with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', delete=False, suffix='.luau') as tmp:
    tmp.write(t)
    tmp_path = tmp.name
try:
    for d in dsts:
        shutil.copyfile(tmp_path, d)
    print('deployed v%s (%s) -> 2 paths' % (ver, expected_tag))
    for d in dsts:
        w = open(d, encoding='utf-8').read()
        tag = re.search(r'DR_HUB_v\d+', w)
        print(' ', d, tag.group(0) if tag else '?')
finally:
    os.unlink(tmp_path)
