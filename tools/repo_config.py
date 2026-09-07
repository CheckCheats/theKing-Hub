#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""仓库配置 (publish.py / whitelist.py 共用, 与 Loader CONFIG 一致)。

主仓库: Gitee (国内直连稳, raw 直出无 CDN 缓存层, 更新即时生效)
旧 GitHub 仓库仅作 Loader 端灾备, 版本可能落后。
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REPO_OWNER = "CheckCheat"
REPO_NAME = "the-king-hub"
REPO_BRANCH = "master"
REPO_HTTPS = "https://gitee.com/CheckCheat/the-king-hub.git"

# 本地 Gitee 检出目录 (whitelist push / publish 推送都走它; 不存在时自动 git clone)
GITEE_CHECKOUT = ROOT / "gitee-checkout"
