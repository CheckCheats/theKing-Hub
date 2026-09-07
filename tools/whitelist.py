#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TheKing 白名单工具 v1.0 — 增删改到期时间 + 一键推送到 Gitee

白名单文件: ROOT/whitelist.txt (与 Loader/users.enc 同源, 手动维护的唯一入口)

    格式 (一行一个用户, # 注释, @ 前缀自动去掉):
        WoSh1N1D1e                      # 永久授权 (不带日期)
        FriendA | 2026-09-30            # 到期时间 (YYYY-MM-DD, 含当天有效)
        @FriendB | 2026-12-31

    到期语义: until 缺省 = 永久; until < 今天(UTC) = 已到期, Loader 提示
    "用户已至期限，请续约公司" 并弹出退出窗口。

用法:
    python tools/whitelist.py list                                    # 列出全部用户
    python tools/whitelist.py add 用户名 [--until 2026-09-30 | --permanent] [--force]
    python tools/whitelist.py remove 用户名
    python tools/whitelist.py extend 用户名 [--until 2026-09-30 | --permanent]   # 增强/修改到期
    python tools/whitelist.py push [--message "备注"]                  # 一键推送: 加密 users.enc -> Gitee

到期时间格式校验: YYYY-MM-DD (非严格历法校验, 但必须是数字且长度正确)。
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from repo_config import REPO_BRANCH, REPO_HTTPS, REPO_OWNER, REPO_NAME, GITEE_CHECKOUT  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
WHITELIST_PATH = ROOT / "whitelist.txt"
USERS_ENC = ROOT / "dist" / "users.enc"

# ==================== 加密参数 (与 Loader 端逐字节一致) ====================
EASTER_EGG_BYTES = [20320, 30475, 20320, 22920, 22920, 21602]  # 你看你妈妈呢
LOVE_BYTES = [108, 111, 118, 101]  # love
YPR_BYTES = [89, 111, 117, 32, 80, 108, 97, 121, 32, 82, 111, 98, 108, 111, 120]  # You Play Roblox
SURRENDER_DAY = 19450815  # 日本战败日
WHITE_KEY = 20260831  # 白名单密钥 (改它必须同步改 Loader CONFIG.WhiteKey, 否则全员解密失败 -> 未授权)

DEFAULT_WHITELIST = ["WoSh1N1D1e"]  # 文件不存在/为空时默认仅作者

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


# ==================== 白名单读写 ====================
def parse_whitelist(text: str) -> list:
    """解析 whitelist.txt -> [{'name':..., 'until': str|None}, ...] (保留文件顺序)。"""
    entries = []
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()  # 去注释
        if not line:
            continue
        parts = [p.strip() for p in line.split("|")]
        name = parts[0].lstrip("@").strip()
        if not name:
            continue
        until = parts[1].strip() if len(parts) > 1 and parts[1].strip() else None
        if until and not DATE_RE.match(until):
            sys.exit(f"[whitelist] 到期时间格式错误: {until!r} (应为 YYYY-MM-DD), 行: {raw.strip()}")
        entries.append({"name": name, "until": until})
    return entries


def read_whitelist() -> list:
    # 仅文件不存在 (首次初始化) 时兜底为默认作者; 文件存在但为空 = 用户主动清空,
    # 必须如实返回空名单, 否则删除最后一个用户后 push 会把默认作者又写回去。
    if not WHITELIST_PATH.exists():
        return [{"name": n} for n in DEFAULT_WHITELIST]
    return parse_whitelist(WHITELIST_PATH.read_text(encoding="utf-8-sig"))


def write_whitelist(entries: list):
    lines = [
        "# TheKing 白名单 — 一行一个用户; 无日期=永久, 带日期=到期时间(YYYY-MM-DD)",
        "# 用 tools/whitelist.py 管理 (add/remove/extend/push), 手动编辑后直接 push 亦可",
        "",
    ]
    for e in entries:
        nm = e["name"].lstrip("@")
        if e.get("until"):
            lines.append(f"{nm} | {e['until']}")
        else:
            lines.append(f"{nm}")
    WHITELIST_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ==================== 加密 (与 publish.py 旧版同算法, 载荷改为对象数组) ====================
def encode_list(entries: list, key=WHITE_KEY) -> bytes:
    """白名单 -> 密文。

    载荷 = JSON 对象数组: [{"name":"A"},{"name":"B","until":"2026-09-30"}]
    按 UTF-8 字节加密, 四特征派生, 与 Loader 解密端逐字节对齐。
    """
    payload = json.dumps(entries, ensure_ascii=False)
    payload_bytes = payload.encode("utf-8")
    egg, love, ypr = EASTER_EGG_BYTES, LOVE_BYTES, YPR_BYTES
    k = len(payload_bytes)
    enc = []
    for i, b in enumerate(payload_bytes):
        pos_key = (i + 1) * 31 + k * 7 + egg[i % len(egg)] + love[i % len(love)] \
            + ypr[i % len(ypr)] + SURRENDER_DAY + key
        enc.append((b + pos_key) % 256)
    return bytes(enc)


def ensure_checkout() -> Path:
    if not (GITEE_CHECKOUT / ".git").exists():
        print(f"[whitelist] 检出目录不存在, 克隆: {REPO_HTTPS}")
        GITEE_CHECKOUT.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "clone", REPO_HTTPS, str(GITEE_CHECKOUT)], check=True)
    return GITEE_CHECKOUT


# ==================== Gitee 推送 (绕开本机坏掉的图形凭据选择器) ====================
# 本机 PortableGit 系统 gitconfig 写死 credential.helper=helper-selector, 该选择器
# 在无界面环境会空等 ~19s GUI 超时甚至挂死, 导致 git push 无输出地失败。
# 方案: 每次推送带 -c credential.helper= 清空 helper 链 + URL 内联凭据 (凭据读
# ~/.git-credentials-gitee, 该文件由 git credential approve / 手工维护)。
CRED_FILE = Path.home() / ".git-credentials-gitee"


def read_gitee_creds():
    """从 ~/.git-credentials-gitee 读 (username, password), 无则 (None, None)。"""
    if not CRED_FILE.exists():
        return None, None
    line = CRED_FILE.read_text(encoding="utf-8").strip()
    import urllib.parse
    try:
        u = urllib.parse.urlsplit(line)
        return urllib.parse.unquote(u.username or ""), urllib.parse.unquote(u.password or "")
    except Exception:
        return None, None


def gitee_url_with_creds() -> str:
    user, pwd = read_gitee_creds()
    if user and pwd:
        return f"https://{user}:{pwd}@gitee.com/{REPO_OWNER}/{REPO_NAME}.git"
    return REPO_HTTPS


def git_run(co: Path, *args: str):
    subprocess.run(["git", "-C", str(co), "-c", "credential.helper=", *args], check=True)


def git_push(message: str):
    """加密白名单同步检出目录并推送。v2.1: rebase 在写检出文件之前执行,
    避免检出目录带未暂存改动导致 rebase 失败。

    旧版 v2.0 bug: cmd_push 先把 users.enc 写进检出目录, 再调 git_push,
    git rebase 撞上未暂存改动 -> "cannot rebase: You have unstaged changes"
    -> 推送永远不成功, 删除/修改白名单推不出去。

    修复: rebase 前丢弃可能的遗留改动, rebase 完再写文件, 提交推送。
    """
    co = ensure_checkout()
    # 0. 丢弃 dist/users.enc 的本地改动 (可能是上次推送失败遗留; 下面会无条件覆盖, 丢弃安全)
    subprocess.run(
        ["git", "-C", str(co), "-c", "credential.helper=", "checkout", "--", "dist/users.enc"],
        capture_output=True)
    # 1. 先取远端 (公开仓库匿名 fetch 即可, 不需要凭据)
    f = subprocess.run(
        ["git", "-C", str(co), "-c", "credential.helper=", "fetch", "origin", REPO_BRANCH],
        capture_output=True, text=True)
    if f.returncode != 0:
        sys.exit(f"[whitelist] fetch 失败:\n{f.stdout}\n{f.stderr}")
    # 2. 本地有未推送提交时 rebase 到远端之上 (此时工作区干净, rebase 不会失败)
    rb = subprocess.run(
        ["git", "-C", str(co), "-c", "credential.helper=", "rebase", f"origin/{REPO_BRANCH}"],
        capture_output=True, text=True)
    if rb.returncode != 0:
        sys.exit(f"[whitelist] rebase 失败 (检出目录与远端冲突, 需手动处理):\n{rb.stdout}\n{rb.stderr}")
    # 3. rebase 完才把新 users.enc 写进检出目录 (无条件覆盖, 本地白名单是唯一真相)
    dst = co / "dist" / "users.enc"
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(USERS_ENC.read_bytes())
    print(f"[whitelist] 已同步到检出目录: {dst}")
    # 4. 提交白名单文件
    git_run(co, "add", "dist/users.enc")
    # 无条件提交: 无变更时 git commit 报错, 忽略 (仍要继续 push 掉可能遗留的本地提交)
    r = subprocess.run(
        ["git", "-C", str(co), "-c", "credential.helper=", "commit", "-m", message],
        capture_output=True, text=True)
    if r.returncode != 0:
        print("[whitelist] 工作区无新变更, 检查未推送提交")
    # 5. 无条件推送: 有新提交就上去, 没有则 "Everything up-to-date"
    rp = subprocess.run(
        ["git", "-C", str(co), "-c", "credential.helper=", "push", gitee_url_with_creds(), REPO_BRANCH],
        capture_output=True, text=True)
    if rp.returncode != 0:
        sys.exit(f"[whitelist] 推送失败:\n{rp.stdout}\n{rp.stderr}")
    print(f"[whitelist] 已推送 {REPO_HTTPS} (branch: {REPO_BRANCH})")


# ==================== 命令 ====================
def cmd_list(entries):
    import datetime
    now = datetime.datetime.now(datetime.timezone.utc)
    today = now.strftime("%Y-%m-%d")
    today_date = now.date()
    if not entries:
        print("(空名单)")
        return
    print(f"{'用户名':<24} {'到期时间':<12} 状态")
    print("-" * 48)
    for e in entries:
        until = e.get("until")
        if not until:
            status = "永久"
        else:
            y, m, d = map(int, until.split("-"))
            days = (datetime.date(y, m, d) - today_date).days
            status = "已到期!" if today > until else f"剩余 {days} 天"
        print(f"{e['name']:<24} {(until or '—'):<12} {status}")


def cmd_add(entries, name, until, force):
    name = name.lstrip("@")
    if any(e["name"] == name for e in entries):
        if not force:
            sys.exit(f"[whitelist] 用户已存在: {name} (加 --force 覆盖)")
        entries = [e for e in entries if e["name"] != name]
    entries.append({"name": name, "until": until})
    write_whitelist(entries)
    print(f"[whitelist] 已添加: {name} ({'永久' if not until else until})")


def cmd_remove(entries, name):
    name = name.lstrip("@")
    before = len(entries)
    entries = [e for e in entries if e["name"] != name]
    if len(entries) == before:
        sys.exit(f"[whitelist] 未找到用户: {name}")
    write_whitelist(entries)
    print(f"[whitelist] 已删除: {name}")


def cmd_extend(entries, name, until):
    name = name.lstrip("@")
    for e in entries:
        if e["name"] == name:
            e["until"] = until
            write_whitelist(entries)
            print(f"[whitelist] 已修改 {name}: {'永久' if not until else until}")
            return
    sys.exit(f"[whitelist] 未找到用户: {name}")


def cmd_push(entries, message):
    USERS_ENC.parent.mkdir(parents=True, exist_ok=True)
    USERS_ENC.write_bytes(encode_list(entries))
    print(f"[whitelist] users.enc 已生成: {len(entries)} 用户 -> {USERS_ENC} ({USERS_ENC.stat().st_size} B)")
    git_push(message)  # 同步检出目录 + 推送都交给 git_push (rebase 前检出目录必须干净)


# ==================== GUI 模式 (v2.0, tkinter) ====================
# 图形界面: 用户列表 + 添加/删除/修改到期/一键推送。复用全部核心逻辑 (复用而非重写)。
def run_gui():
    import tkinter as tk
    from tkinter import ttk, messagebox, simpledialog
    import datetime

    root = tk.Tk()
    root.title("TheKing 白名单管理")
    root.geometry("720x520")
    root.minsize(560, 400)

    def refresh_tree():
        tree.delete(*tree.get_children())
        entries = read_whitelist()
        now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
        for e in entries:
            until = e.get("until") or "—"
            status = "永久" if not e.get("until") else ("已到期!" if now > e["until"] else "有效")
            tree.insert("", "end", values=(e["name"], until, status))
        return entries

    # ---- 顶部列表 ----
    outer = ttk.Frame(root, padding=8)
    outer.pack(fill="both", expand=True)
    cols = ("用户名", "到期时间", "状态")
    tree = ttk.Treeview(outer, columns=cols, show="headings", selectmode="browse", height=12)
    for c, w in zip(cols, (260, 140, 100)):
        tree.heading(c, text=c)
        tree.column(c, width=w, anchor="center")
    tree.pack(side="left", fill="both", expand=True)
    sb = ttk.Scrollbar(outer, orient="vertical", command=tree.yview)
    sb.pack(side="right", fill="y")
    tree.configure(yscrollcommand=sb.set)

    # ---- 操作按钮 ----
    btns = ttk.Frame(root, padding=(8, 0, 8, 8))
    btns.pack(fill="x")

    def selected_name():
        sel = tree.selection()
        if not sel:
            messagebox.showinfo("提示", "请先在列表中选择一个用户", parent=root)
            return None
        return tree.item(sel[0], "values")[0]

    def ask_until():
        until = simpledialog.askstring(
            "到期时间", "到期时间 YYYY-MM-DD\n(留空 = 永久授权)", parent=root)
        if until is None:
            return None, False  # 取消
        until = until.strip()
        if until and not DATE_RE.match(until):
            messagebox.showerror("格式错误", "应为 YYYY-MM-DD 或留空", parent=root)
            return None, False
        return (until or None), True

    def on_add():
        name = simpledialog.askstring("添加用户", "Roblox 用户名:", parent=root)
        if not name or not name.strip():
            return
        name = name.strip()
        until, ok = ask_until()
        if not ok:
            return
        try:
            entries = read_whitelist()
            cmd_add(entries, name, until, force=False)
        except SystemExit as e:
            messagebox.showerror("添加失败", str(e), parent=root)
            return
        refresh_tree()
        status_var.set(f"已添加 {name}")

    def on_remove():
        name = selected_name()
        if not name:
            return
        if not messagebox.askyesno("确认删除", f"确定删除用户 {name} ?", parent=root):
            return
        try:
            entries = read_whitelist()
            cmd_remove(entries, name)
        except SystemExit as e:
            messagebox.showerror("删除失败", str(e), parent=root)
            return
        refresh_tree()
        status_var.set(f"已删除 {name}")

    def on_extend():
        name = selected_name()
        if not name:
            return
        until, ok = ask_until()
        if not ok:
            return
        try:
            entries = read_whitelist()
            cmd_extend(entries, name, until)
        except SystemExit as e:
            messagebox.showerror("修改失败", str(e), parent=root)
            return
        refresh_tree()
        status_var.set(f"已修改 {name}: {'永久' if not until else until}")

    def on_push():
        if not messagebox.askyesno("确认推送", "将加密当前白名单并推送到 Gitee, 继续?", parent=root):
            return
        try:
            entries = read_whitelist()
            cmd_push(entries, "whitelist: update users (GUI)")
        except SystemExit as e:
            messagebox.showerror("推送失败", str(e), parent=root)
            return
        status_var.set("推送成功")
        messagebox.showinfo("推送成功", "白名单已推送到 Gitee", parent=root)

    ttk.Button(btns, text="刷新", command=lambda: (refresh_tree(), status_var.set("已刷新"))).pack(side="left", padx=4)
    ttk.Button(btns, text="添加用户", command=on_add).pack(side="left", padx=4)
    ttk.Button(btns, text="修改到期", command=on_extend).pack(side="left", padx=4)
    ttk.Button(btns, text="删除用户", command=on_remove).pack(side="left", padx=4)
    ttk.Button(btns, text="一键推送", command=on_push).pack(side="left", padx=4)

    # ---- 底部状态 ----
    status_var = tk.StringVar(value="就绪")
    ttk.Label(root, textvariable=status_var, anchor="w", padding=(8, 0, 8, 6)).pack(fill="x")

    refresh_tree()
    root.mainloop()


def main():
    ap = argparse.ArgumentParser(description="TheKing 白名单工具 v2.0 (CLI + GUI)")
    ap.add_argument("cmd", nargs="?", choices=["list", "add", "remove", "extend", "push"],
                    help="CLI 命令 (不带命令时配合 --gui)")
    ap.add_argument("name", nargs="?", help="用户名 (add/remove/extend)")
    ap.add_argument("--until", help="到期时间 YYYY-MM-DD")
    ap.add_argument("--permanent", action="store_true", help="永久授权 (不设到期)")
    ap.add_argument("--force", action="store_true", help="add 时覆盖已存在用户")
    ap.add_argument("--message", default="whitelist: update users", help="git 提交信息")
    ap.add_argument("--gui", action="store_true", help="启动图形界面模式")
    args = ap.parse_args()

    if args.gui:
        run_gui()
        return

    if not args.cmd:
        sys.exit("缺少命令: list / add / remove / extend / push (或加 --gui 启动图形界面)")

    if args.until and args.permanent:
        sys.exit("[whitelist] --until 与 --permanent 二选一")

    until = None
    if args.until:
        if not DATE_RE.match(args.until):
            sys.exit(f"[whitelist] 到期时间格式错误: {args.until!r} (应为 YYYY-MM-DD)")
        until = args.until
    elif not args.permanent:
        until = None  # 缺省 = 永久

    # 文件不存在时 add 从空名单开始 (默认仅作者只在 publish 时兜底, 不阻止首次添加)
    entries = [] if args.cmd == "add" and not WHITELIST_PATH.exists() else read_whitelist()

    if args.cmd == "list":
        cmd_list(entries)
    elif args.cmd == "add":
        if not args.name:
            sys.exit("add 需要用户名")
        cmd_add(entries, args.name, until, args.force)
    elif args.cmd == "remove":
        if not args.name:
            sys.exit("remove 需要用户名")
        cmd_remove(entries, args.name)
    elif args.cmd == "extend":
        if not args.name:
            sys.exit("extend 需要用户名")
        cmd_extend(entries, args.name, until)
    elif args.cmd == "push":
        cmd_push(entries, args.message)


if __name__ == "__main__":
    main()
