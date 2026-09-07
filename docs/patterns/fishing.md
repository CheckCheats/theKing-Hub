---
genre: fishing
games: ["heavy-fishing", "fisch"]
updated: 2026-09-05
---

# 钓鱼类游戏套路库

> 从 heavy-fishing (深度逆向) + fisch (侦察级) 提炼。下一个钓鱼游戏进逆向前先通读本文件。
> 单游戏专属细节 (坐标/remote 名/数值表) 不在此收, 看案例索引指向的档案。

## 逆向套路 (进新游戏先跑这个流程)

1. **反作弊侦察**: `dump-anticheat-hooks scanConnections=true` — 两家钓鱼游戏实测均**无主动客户端反作弊** (DataModel 元表全 C closure, 无无源 per-frame 监听) (来自两者)。L1 人类化即可安全开发。
2. **通信层定位**: 直奔 `ReplicatedStorage.Events` / `Remotes` — 两家都是**具名 RemoteEvent + 明文基础类型参数**, 无 ByteNet/打包协议 (来自两者)。按名字猜语义, 再用 remote-spy 或反编译调用处确认参数。
3. **找钓鱼链路四件套**: ① 抛竿 remote (参数常为 HRP.CFrame) → ② 小游戏开始包 (S→C) → ③ 进度/伤害上报 remote → ④ 会话结束包。认准"客户端可反复发的那个上报 remote", 它就是自动钓鱼的伤害通道 (来自 heavy-fishing)。
4. **配置表运行时 require**: `ReplicatedStorage.Info.*` (鱼/竿/饵/区域权重) 全部运行时 require 即取, **禁止硬抄进档案** — 游戏更新自动跟随 (来自 heavy-fishing)。
5. **小游戏判定窗口必须反编译客户端模块确认**, 不靠猜 (来自 heavy-fishing)。

## 协议模式

- **S→C→S 回调型小游戏**: 服务器发 `(callbackRemote)`, 客户端操作后向 callbackRemote 回报结果字符串 ("Perfect"/"Good"/"Bad") — 蓄力/拍击类小游戏都是这个形状 (来自 heavy-fishing)。
- **频率权威的上报**: 伤害上报 remote 常为**无参数** FireServer, 服务器只认上报频率不验证点击 — 条保持在判定区内即满速输出 (来自 heavy-fishing)。
- **会话 token**: 小游戏开始包带 uuid token, 结束回报要带上; 主 handler 用 `type(p1)=="table"` 过滤迟到的 SessionEnd 包 (来自 heavy-fishing)。
- **开战信号在 NPC 镜像属性**: Boss 是否在战 = `workspace.NPC.<Boss>.InFight` 这类服务器回写属性, 配置表里没有; 玩家 FishID 属性战斗中不一定指向实体 (来自 heavy-fishing)。

## 功能配方

- **自动钓鱼 (L1)**: 锁条 = 对 Bar UI `TweenPosition` 0 时长覆盖到判定区中心 (本地 UI 操作服务器不可见, 所有发包仍是游戏自身协程发出) — 判定区窗口从反编译/实测得出 (来自 heavy-fishing)。
- **自动卖鱼**: `SellFish:FireServer("All")` 类 remote 直发, 钓鱼类普遍**无位置校验无确认弹窗** (来自 heavy-fishing; 新游戏先小参数试探)。
- **传送**: 岛屿/区域瞬移 = 游戏自身"回到出生点"就是纯客户端 CFrame 写入 → 客户端任意传送走合法路径 (来自 heavy-fishing; 新游戏先确认传送 remote 是否存在)。
- **Boss 自动战**: 检测 NPC `InFight` 属性轮询 (0.4s 足够) 接管; 多阶段 Boss 先把阶段属性 (Phase2/FinalPhase) 逆向全再写状态机 (来自 heavy-fishing)。
- **节奏/音游类小游戏**: 扫音符实例 Y.Scale 过判定线即按键; 判定线 Y 必须动态读 UI, 音符直接挂在轨道下 (容器结构版本间会变) (来自 heavy-fishing)。
- **价值决策**: 开始包常含鱼的价值字段 (重量/稀有度), 开战瞬间即可决策速刷或全力 (来自 heavy-fishing)。

## 已知坑 (该类型跨游戏反复踩的)

- **只发包不删表 = 假命中**: 节奏小游戏直接 `RhythmHit("hit")` 已被证伪 — 游戏客户端 TryHit 还负责 Destroy 音符 + 从内部表移除, 只发包会被游戏自身 Heartbeat 补发 miss。**必须走游戏自身判定函数路径** (来自 heavy-fishing, 1.2.2 证伪)。
- **阶段切换别信状态机全局变量**: 二段小游戏触发时 fsm 状态可能还在"钓鱼态", 接管要与 fsm 解耦 — 小游戏开始事件触发即无条件接管 (来自 heavy-fishing)。
- **多命鱼假血**: 鱼配置有 `Phase` 字段 = 总命数, 前 N-1 条命血量回跳是正常的; 一次性大招只留到最后一条命 (服务器有显式 FinalPhase 标记) (来自 heavy-fishing)。
- **钓鱼游戏地图大/实例多**: 全量反编译与全树遍历并发会**崩客户端** — 重操作严格串行, 结构探索用分片 selector (来自 fisch)。
- **官方自动功能是等级门槛**: 官方自动钓鱼常见 Level≥N 解锁, 低级号唯一路径是自制脚本 — 顺带逆向官方开关 remote 可白嫖服务器侧逻辑 (来自 heavy-fishing)。

## 案例索引

- **heavy-fishing**: `games/heavy-fishing/intel.md` — 全类型最完整参照: 钓鱼链路/小游戏判定区/技能伤害模型/Boss 阶段/Rhythm 协议/经济系统全逆向, 且含大量"已证伪"教训 (假称号/Rhythm 直发)。
- **fisch**: `games/fisch/intel.md` — 目前仅侦察结论 (无客户端 AC + 重操作串行纪律); 该游戏本体就是 heavy-fishing 的玩法原型, 深度逆向待补。
