# Real MCP 逆向工作流手册 (RCWTK 标准链路)

> 目标读者: 使用 Real MCP 注入器分析 Roblox 游戏的 AI。
> 铁律: **开工先查档** (`games/<game>/intel.md` + `recall-game-memory`), 已有结论禁止重挖; **收工必归档**。

## 低痕迹分析纪律 (先读这个, 再用任何工具)

分析动作本身是客户端上的异常负载, 暴力分析 = 帧率骤降 / 行为画像异常 = 账户被标记。所有工具调用前过一遍:

**负载控制**
- `build-script-index` 全游戏反编译是重操作: 确认本次会话真需要 ≥3 次 script-grep 才建; 建一次后所有查询走索引复用, 禁止反复重建 (`force=true` 只在游戏更新/换 place 后用)。
- 探索优先 `search-instances` 定向 selector (类名/名字/tag 过滤), 禁止无过滤全树 dump; 大容器必 `countsOnly=true` 先看直方图再决定钻哪。
- `eval`/`get-data-by-code` 禁止高频轮询 — 循环等待用 `start-job`, 值变化观察用 `watch-value` (它自己控制采样节奏)。

**spy 卫生**
- `remote-spy`/`inbound-spy` 必须带 `remoteName` 过滤再 start; 全量监听让每个 namecall 都过 hook, 性能税全客户端买单。
- 用完必 `stop`/`restore`; namecall hook 是全局的, 挂着不还 = 游戏一直跑在你的 hook 上。
- `decode-buffer` 控制录制时长 (默认 4s 够) 与样本数, 别开着录 60s。

**行为节奏**
- 分析动作分散进行, 别进服 30 秒内狂轰滥炸 — 人类不会登录即遍历整个 ReplicatedStorage。
- 新 remote 试探永远最小参数单发, **严禁循环 fire 一堆 remote 试反应** — 这是教科书级的检测特征。
- 关注 `list-clients` 的 fps/健康度: 客户端明显变卡 = 你的分析在烧帧, 先停手减载再继续。


## 阶段 0: 接入与建档

| 动作 | 工具 | 说明 |
|---|---|---|
| 确认客户端 | `list-clients` | 多开时先看哪个 responsive, 再 `set-active-client` |
| 游戏身份 | `get-game-info` | placeId/universeId/placeName, 匹配 games/ 档案的键 |
| 历史记忆 | `recall-game-memory` | universe 键控自动召回, 先读再干活 |

**建档规则**: games/ 下无对应目录 → 复制 `templates/intel-template.md`, front matter 用 get-game-info 返回值填充。不需要用户下命令。

## 阶段 1: 结构探索

| 目标 | 工具 | 要点 |
|---|---|---|
| 找 remote | `search-instances` root=ReplicatedStorage | selector 如 `RemoteEvent`,`#ByteNetReliable` |
| 大容器概览 | `get-descendants-tree` countsOnly=true | 先看 class 直方图再决定钻哪里 |
| 找标记物 | `get-tagged` / `.Tag` selector | 敌人/收集物常用 CollectionService 标记 |
| 藏起来的东西 | `list-special-instances` source=nil recurseScripts=true | 数据模块和反作弊常挂 nil parent |

## 阶段 2: 代码侦察

标准链路: `build-script-index`(一次性) → `script-grep` / `search-scripts`(语义) → `get-script-content`(精读)。

- script-grep 用**代码里真实存在的标识符**(remote 名、函数名), 不是自然语言; 自然语言用 search-scripts。
- 反编译返回空/乱码 = 混淆或 VM 保护 → 转 `get-script-strings` 直接读字节码字符串表 (拿 remote 名/kick 消息/配置 key 很有效)。
- 多个脚本同路径时用 docId 精确定位。

## 阶段 3: 通信监听

| 方向 | 工具 | 流程 |
|---|---|---|
| 客户端→服务器 | `remote-spy` | **先 probe**(确认 hook 安全) → list 安装 → 在游戏里手动触发动作 → list 读流量 → **stop 还原** |
| 定位调用方 | `find-remote-callers` | 需要 script-index; 告诉你哪个游戏脚本在什么上下文里发这个包 |
| 服务器→客户端 | `inbound-spy` | hook 已有 OnClientEvent 监听者; 后连的监听要重新 start |

要点:
- 忙碌游戏务必 `remoteName` 过滤, 否则日志不可读。
- InvokeServer 的条目带 `response` 字段 — 能区分服务端接受还是拒绝。
- `seen` 在涨但列表空 = 过滤词写错, 不是没流量。
- namecall hook 是全局的, 有性能代价, **用完必须 stop/restore**。

## 阶段 4: 协议解码

单 remote 打包一切的现代游戏(ByteNet/Blink/BufferNet)用 `decode-buffer`:

1. 提供 `truthExpr`: Luau 表达式返回你推测 payload 携带的数值(相机 yaw、坐标、血量), 与 payload 同刻采样。
2. 判读原则: **看 max error 接近 0 的候选, 不看相关度** — 上百个候选项里高相关纯属运气好。
3. 角度字段自带 sin/cos 变体尝试, 直接给原始 yaw 即可。
4. 若 payload 解出来是 field/value 表而不是字节流, 样本会原样返回 — 更好读。

**已知陷阱 (来自实战)**:
- executor 与游戏 VM 的 require 缓存部分隔离: 游戏内部的编码函数可能拿不到 → 手搓 buffer 编码。
- packetId 类配置运行时从 ReplicatedStorage JSON 读 (如 BytenetStorage.<Name>.Value), 别硬编码 — 游戏一更新就失效。
- string = u16长度+bytes; optional = u8前缀; Color3 = RGB 各 u8。

## 阶段 5: 行为验证

`record-session`: watch 表达式(目标血量、自己的弹药)+ remoteName 过滤, 一条时间线同时看到"我发了什么"和"世界变了什么"。
长等待动作(传送确认、复活)用 `start-job` + `await-job`, 不要把 eval 挂住 15 秒。
改值后验证是否被服务器回滚用 `watch-value` (3 秒窗口足够看出权威归属)。

## 阶段 6: 归档 (收工必做)

1. 开发中已随手 `remember-game` 的结论 → 收工时整理进 `games/<game>/intel.md` 对应分区, 带条目头 `[日期 | pv<N> | 来源@版本]`。
2. 只归档**验证过**的结论; 猜想写进条目但标注 `(未验证)`。
3. UI 层结论(WindUI 版本兼容性等)写进本引擎 docs, 不进游戏档案。

## 反作弊侦察与服务器反应观察

- 怀疑有对抗时第一步: `dump-anticheat-hooks scanConnections=true` — 看 DataModel 元表是否被游戏挂钩、有无无源 per-frame 监听。**有 = 该游戏有主动反作弊**, 结论记入 intel.md「关键机制」, 功能设计按 AGENTS.md 敏感点清单过一遍。
- **服务器反应观察法** (验证一个动作是否安全):
  1. `record-session` 开录制, watch 目标状态表达式 (货币/血量/背包计数)。
  2. 手动触发一次该动作。
  3. 读时间线: 值变了且稳定 = 客户端权威或已接受; 变了又弹回 = 服务器拒绝 (回滚); 直接断线/弹窗 = 触发检测, 该路径封死。
  4. 回滚 ≠ 加大力度重试, 换合法路径 (找游戏自己的按钮 remote)。
- Real 的 firesignal 是 no-op, 点按钮要走 `send-input` 真实输入。
- spy-closure 可钩具体本地函数(带 filtergc getter), 但 print/tostring 这类热全局拒绝钩。
