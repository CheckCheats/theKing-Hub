# TheKing Loader — Hub 分发引擎使用手册

> 版本: Loader v0.4.0 (加载动画) | Obfuscator v1.4 | 更新时间: 2026-09-01
> 仓库: https://github.com/CheckCheats/theKing-Hub

## 一、单行执行 (最快上手)

在任意 Roblox 注入器(如 Real)中执行这一行:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/CheckCheats/theKing-Hub/main/dist/theking-loader.luau"))()
```

**要求**: 当前 Roblox 用户名必须在白名单内 (当前仅 @WoSh1N1D1e)。

## 一、架构总览

```
用户 (任意游戏)                你的 GitHub 仓库 (私有/公开都行)
   │ 手动运行                        │
   ▼                                │
theking-loader.luau ────────────────┼─ 拉 dist/users.enc      (加密白名单)
   │                                ├─ 拉 dist/manifest.json  (游戏清单)
   ├─ 解密白名单 → 比对用户名        │
   ├─ 匹配当前游戏 universeId         │
   └─ 拉 games/<名>/dist/*-obf.luau ─┘
         │
         └─ loadstring 注入 → TheKing HUB 正常跑
```

**免卡密**: 授权 = 用户名在白名单内。加用户只需编辑 `games/<游戏>/whitelist.txt` 一行。

## 二、文件地图 (新增/改动)

| 文件 | 作用 |
|---|---|
| `loader/theking-loader.luau` | Loader 主脚本 (开发态 readfile 加载库) |
| `tools/obfuscate.py` | **theKing Obf v1.4 自研混淆器** (可用优先自迭代) |
| `tools/publish.py` | 一键发布: build→混淆→白名单加密→manifest |
| `tools/build.py` | (升级) 兼容标准加载行 + 自定义 `loadXxx()` 加载函数 |
| `games/<游戏>/whitelist.txt` | **手动维护**: 一行一个用户名, `#` 注释, 支持 `@用户名` 写法 |
| `games/<游戏>/dist/users.enc` | 发布生成: 加密白名单 (勿手改) |
| `dist/manifest.json` | 发布生成: 游戏清单 |

## 三、白名单维护 (唯一手动步骤)

```bash
# 编辑 ROOT/whitelist.txt (全局, 不存在时默认仅 @WoSh1N1D1e)
WoSh1N1D1e
# 这是注释
@朋友A          # @ 前缀会被自动去掉
```

保存后重新发布即可, 无需改 Loader。

## 三-b、发布与上传 (一次命令)

```bash
python tools/publish.py --loader --all    # 构建 Loader 单文件 + 发布全部游戏 (天气播种)
python tools/publish.py --no-weather      # 调试用: 关天气播种
```

上传: `git add -A && git commit -m "..." && git push origin main --force`
仓库: https://github.com/CheckCheats/theKing-Hub (main)

## 四、发布流程 (每次更新脚本/白名单)

```bash
python tools/publish.py --game heroes-rng   # 单个游戏
python tools/publish.py --all               # 全部
```

产物:
1. `games/<游戏>/dist/hub-single-obf.luau` — 混淆后脚本 (上传 GitHub)
2. `games/<游戏>/dist/users.enc` — 加密白名单 (上传 GitHub)
3. `dist/manifest.json` — 游戏清单 (上传 GitHub)

**上传后用户无需更新 Loader, 下次运行自动拉最新版。**

## 五、Loader 安全设计 (多层反绕过)

| 层 | 手段 | 反制什么 |
|---|---|---|
| L1 | 白名单加密 users.enc (四特征派生: 你看你妈妈呢+love+You Play Roblox+战败日) | 偷名单 |
| L2 | 拉取/解密/解析任一失败 → 一律未授权 | 断网/篡改/伪造 |
| L3 | 注入函数内部二次 checkAuth | 绕过 UI 直调注入 |
| L4 | 未授权/无脚本 → 强制退出弹窗 | 蹭脚本 |
| L5 | Loader 自身发布走 theKing Obf v1.4 混淆 + 天气播种 | 静态分析 |
| L6 | 加载动画阶段预检授权, 非白名单直接显示拒绝 + 头像 | 绕过 UI 直接注入 |

**关键不变量**: `checkAuth()` 是唯一授权入口, 所有注入路径必经。改这里 = 改安全模型, 三思。

## 六、theKing Obf v1.4 混淆器

### 设计原则 (可用优先)

v1.5 曾上过字符串表/谓词织入/二次封装/CFF，**实机 UI 起来后炸 `nil < string`**，已回退。
v1.4 只默认开启「可证明互逆、不改控制流语义」的增强；高风险变换继续 opt-in。

### 默认开启 (相对 v1.3)

1. **自定义字符串加密**: 位置键 + 四特征串, 每串独立 key, 长串可分 2~3 段
2. **解密器自混淆**: 特征表 XOR 掩码 + 战败日 `bit32.bxor` 隐藏 (算法与 v1.3 互逆)
3. **不透明 key**: 调用侧 `dec(密文, opaque(key))`，抗常量扫描
4. **数字拆分** + **垃圾码实调用一次** (防死代码剥离) + 反 AI 水印
5. **可选天气播种** (多态输出)

### 默认关闭 (风险高, 需单独实机门禁)

- `--rename` / `--virtualize`
- 字符串表 / 不透明谓词织入 / 二次封装 / CFF / VM (未默认落地)

### 用法

```bash
python tools/obfuscate.py input.luau -o out.luau
python tools/obfuscate.py --selftest
python tools/obfuscate.py input.luau -o out.luau --rename --virtualize  # 高风险, 须实机验证
```

### 迭代门禁

1. `python tools/obfuscate.py --selftest` 必须全过
2. 对 `hub-single` 出产物后实机 `loadstring` → `compile true` + `exec true`，再观察 UI 10s+ 无延迟报错
3. 通过后再 `publish.py`；未过门禁不得把高风险开关改成默认开

### 迭代路径

- [x] v1.3 字符串加密 + 明文解密器 + 数字/垃圾码
- [x] v1.4 解密器自混淆 + 不透明 key + 垃圾码实调用 (默认开; 实机门禁通过)
- [ ] 虚表/rename 修好后仍默认关, 可选开 + 独立门禁
- [ ] 字符串表 / 谓词织入 / 二次封装 (曾 v1.5, 待修后再试)
- [ ] 轻量 VM (混淆 2.0)

## 七、配置点 (发布前必须改)

| 位置 | 改什么 |
|---|---|
| `loader/theking-loader.luau` 头部 CONFIG | RepoOwner / RepoName / RepoBranch (你的 GitHub) |
| `tools/publish.py` WHITE_KEY | 白名单密钥 (必须与 Loader WhiteKey 一致) |
| `tools/publish.py` WHITE_KEY 同步 | 改一个必须改另一个, 否则解密失败 |
| `dist/manifest.json` | universeId/placeId 首次需手动补 (publish 保留旧值) |

## 八、常见问题

**Q: 用户说不授权?**
→ 检查: 用户名大小写是否精确匹配 / whitelist.txt 是否上传 / users.enc 是否重新发布。

**Q: Loader 报"清单拉取失败"?**
→ GitHub 国内不稳, 已内置 raw→jsdelivr→gitee 三级降级。确认 manifest.json 路径正确。

**Q: 改了 WHITE_KEY 但用户还在用旧 Loader?**
→ 密钥不匹配 → 解密失败 → 全部未授权 (安全设计如此)。旧 Loader 必须重新发布。

**Q: 注入失败「找不到 theking.luau 运行库」?**
→ 发布包误留了开发态本地找库。别人电脑没有 `lib/theking.luau` 就会先报错。`build.py` 已剥掉这段; 重发对应游戏的 `hub-single-obf.luau` 即可, 不要让用户去放运行库。

**Q: 换电脑/换游戏?**
→ Loader 在任何游戏都能跑, 白名单是全局的 (按用户名, 不绑设备)。进支持的游戏点注入即可。

## 九、引擎集成注意

- Loader 的 `GameName = "TheKing Loader"`, 与游戏脚本的 GameName (如 "Heroes RNG") 不同 → 热替换注册表按名隔离, 互不干扰。
- 发布态 Loader 需先 build 内嵌 theking.luau (同 hub 流程), 再混淆。见 publish.py 的 loader 分支 (TODO: 未实现单文件化 loader, 当前 loader 开发态直接跑)。
- lib/theking.luau 升级后: 游戏脚本重发布即可, Loader 本身不依赖 lib 内容, 只依赖加载行格式。
