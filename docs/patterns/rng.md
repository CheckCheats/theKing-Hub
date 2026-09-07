---
genre: rng
games: ["heroes-rng", "project-aura-rng"]
updated: 2026-09-07
---

# RNG 类游戏套路库

> Heroes RNG (深度移植) + Project Aura RNG (侦察级)。下一个 RNG 进逆向前先通读。
> 单游戏 remote 名 / 装备 instanceId / 区域表不收, 看案例索引。

## 逆向套路 (进新游戏先跑这个流程)

1. **先定性通信层, 再列业务名**。至少见过两种: ① 单一 Network 模块 `FireServer("动作名", ...)` (Heroes RNG); ② roblox-ts 每条业务一个具名 RemoteEvent, 文件夹名带 `@GlobalEvents` (Project Aura)。不要假设下一家还是同一种。
2. **四件套优先定位**: 抽取请求 / 抽取结果(含 Rejected) / 跳过或 Instant 结果 / 装备-卸下。有这四条才能谈自动抽和跳过滚动。
3. **官方自动开关先于自制循环**: RNG+养成常自带 AutoEnchant / AutoPotion / AutoFeed / ExplorationAuto / SetSetting("AutoXxx")。能直发官方包就走 L1, 别先 hook。
4. **防挂机通道单独记账**: `RequestAfkRejoin` / `AntiIdleTeleportRequest` 这类名字出现 = 长时间挂机必踩。先确认谁发、发了会切服还是只瞬移。
5. **配置表运行时 require, 禁止硬抄掉率/角色表** — 周更游戏表会变 (来自 Heroes RNG)。

## 协议模式

- **请求-结果-拒绝三元组** 很常见: `XxxRequest` + `XxxResult` + `XxxRejected`。循环里要听 Result/Rejected, 不要只狂发 Request (来自 Project Aura 侦察; Heroes 则把限速写在 Config.RemoteRateLimits)。
- **表现包不可当权威**: Unreliable 的伤害/掉落广播只用于 ESP/提示, 领奖走 Redeem/Claim Request (来自 Project Aura 地块水晶)。
- **装备必须带真实实例 id**: 合成/上阵包里乱填 id 会被拒或装备空气 (来自 Heroes RNG EquipHero)。

## 功能配方

- **跳过抽取滚动 (常要 L2)**: 替换滚动 UI 的 Play + WaitComplete 成对函数, 或走游戏自己的 InstantRoll 通道。只改一个会卡死等待 (来自 Heroes RNG; Project Aura 有 `InstantRollResult` 候选, 未验证)。
- **自动抽 (L1)**: 有票再发 Roll Request, 听 Result; 尊重服务器限速, StartLoop 抖动。没票 Backoff, 不要空转刷包。
- **自动升级/买天赋**: 读游戏 Affordable 判定再 Purchase; 用 pending+超时防连点 (来自 Heroes RNG)。
- **传送**: 优先游戏区域/回地块 remote, 不要对服务器校验的位置写 CFrame (来自 Heroes; Project Aura 候选 `TeleportToPlotRequest`)。
- **防挂机**: 吞切服包 + 拉高客户端闲置阈值 + 引擎 Idled 模拟输入, 三件套按需 (来自 Heroes RNG)。新游戏先确认 AntiIdle 包语义再抄。

## 已知坑 (该类型跨游戏反复踩的)

- **executor require 缓存是否与游戏 VM 共享要因游戏测**: Heroes 可 require 全部模块并立刻替换滚动函数; 有的 RNG (如历史上的 Sol's RNG) 会隔离。Project Aura 的 `ReplicatedStorage.TS` 尚未试 require。
- **官方自动和自制自动叠开会双发**: 开脚本前先 `SetSetting`/`AutoXxxToggle` 关掉游戏自己的, 或只驱动官方开关不要两套循环。
- **LiveOps 会改窗口标题**: 档案 `game:` / hub `GameName` 用稳定官方名, 不要跟商店页 Emoji 前缀。

## 案例索引

- **heroes-rng**: `games/heroes-rng/intel.md` — Network 字符串分发、点击攻击限速、滚动 UI 替换、防挂机三件套、设施两步触碰传送。
- **project-aura-rng**: `games/project-aura-rng/intel.md` — roblox-ts/Flamework 具名 Remote 全表、官方自动附魔/药水/探索、地块+光环混合玩法 (深度未做)。
