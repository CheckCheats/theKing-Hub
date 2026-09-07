# (学乱) Gakuran TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

---

## [2026-09-03 | 发布包 | 别人注入找不到运行库]

与狙击场同一构建缺陷: `LIB_CANDIDATES` 探测留在 `hub-single-obf` 里。修 `tools/build.py` 后重打本游戏发布包。玩法未改。

---

## [2026-09-03 | v1.0.1 | lib v2.0.3] 黑金主题发布
跟随共享库主题打混淆包推 Gitee。玩法未改。

## [2026-08-25 | 会话1 | 未建 hub | lib -] 档案建立 + v7560 全面增量分析

### 目标
从 20 天前 pv7532-7538 的运行时记忆重建持久档案 (games/gakuran/), 并对 v7560 做增量全面分析。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/gakuran/intel.md | 全文件 | 新建: 从 recall-game-memory 迁移 v7538 结论 + 写入 v7560 新结论 |
| games/gakuran/devlog.md | 全文件 | 新建 |
| games/gakuran/changelog.md | 全文件 | 新建 |

### 分析结论摘要 (详见 intel.md)
- 反作弊: 元表全 C 闭包无 hook, 行为级对抗 (Services 销毁 + 服务端权威)。
- 脚本数 789(v7532)→1020(v7538)→910(v7560), 净减 = 合并重构。
- v7560 新系统: Spec 框架 (Sandevistan 时停等 4 能力) / 校报摄影打工 / 卡拉OK / 滑板皮肤 gacha / GakuranBall 球类。
- 自行车系统已删除 (RideBike 0 命中), 不再是"staged 待上线"。

### 决策记录
- 目录名 `gakuran` (kebab-case 硬性规范); 显示名 "(学乱) Gakuran" 写 intel front matter。
- v7538 结论默认仍有效但未重验的放「待复核」区, 不冒充已验证。
- 摄影打工自动化判定为 L1 (发游戏自身 remote + 正确参数, 无 hook 无伪造), 但按 SOP 首次实现仍需小号实测。

### 验证
- get-game-info universeId=9199655655 与记忆键一致。
- script-index 910 脚本全反编译成功 (0 失败), grep/search 复用同一索引。
- dump-anticheat-hooks scanConnections=true 实测干净。
- SandevistanClient/PhotoJobServiceClient/KaraokeConfig/SpecConfig 均精读源码确认。

### 遗留问题 / 下一步
- [ ] 功能候选排序待用户挑: 自动摄影打工 (L1, 最完整协议) > 卡拉OK自动点歌 > 战斗辅助 (读 SpecTimeSlowed 找输出窗口)
- [ ] 「待复核」区三项在下次开发会话顺手验证
- [ ] hub.luau 尚未创建; 开工时从 templates/hub-skeleton.luau 复制

---

## [2026-08-25 | 会话2 | v0.2.0 | lib v1.4.1] 战斗修复 + 祖国人/替身换真实动画

### 目标
修快攻/遗忘不生效; 祖国人与替身使者弃用游戏原生 emote, 换成"真·祖国人/JOJO 动画"且全服可见。

### 根因与关键发现
1. **战斗不生效根因**: `hookfunction(M1Mod.OnM1Activated)` detour 后, `debug.getupvalue(OnM1Activated, 1)` 直接报错 (detour 破坏 Lua closure 结构) → Init 校验失败 → 整个战斗桥停摆。
2. **修复**: 改用 `M1Mod.ServerResponse` 作 upvalue 操作锚 — 它未被 hook, 且与 tryM1 共享同一批模块级 upvalue。布局实测 dump: [4]=combo [5]=readyFlag [8]=ComboResetTime=1.55 (作校验锚)。setupvalue 写入已实测生效。
3. **FE 动画通道**: 用户指出别人实现过祖国人动画 → 重新核对 Roblox 复制规则: 自己角色 Animator 上 LoadAnimation+Play 会随网络所有权复制 = 全服可见 (之前"必须走服务器白名单"的判断是错的)。
4. **UGC Emote 拆包**: catalog 商品 ID 不是动画 ID。`game:GetObjects("rbxassetid://商品ID")` 返回内部 Animation 实例, 读其 AnimationId 即真实动画。全部 6 个动画拆包+播放验证通过。

### 改动明细
| 位置 | 改动 |
|---|---|
| CombatBridge.Init/preSkip/clearGate | 锚点 tryM1 → ServerResponse, 新增 [8]==1.55 布局校验 |
| 动画管理器 (新增) | playCustomAnim/stopCustomAnim/stopAllCustomAnims + CharacterAdded 清表 |
| 祖国人区块 | 飞行状态机 (fly/hover/锁定姿势三态差分切换), 4 个真实动画 ID |
| 替身使者区块 | POSE_CHOICES 换真实 JOJO 动画 ID, stand_emote loop 改 track.IsPlaying 探测重播 |
| 头部加载 | 双环境兼容 lib/theking.luau 或 theking.luau |

### 验证
- live-reload 两轮零错误; ServerResponse setupvalue 写入实测生效; OnM1Activated 走 hook 链调用无异常 (Equip=false 时被 tryM1 守卫拒绝属预期); Homelander Fly 动画 Length=4.69s 真实加载。
- 待用户实战验证: 装备武器后测快攻节奏/遗忘跳段手感; 第二视角确认 FE 动画全服可见。

### 遗留问题 / 下一步
- [ ] 快攻最小间隔 0.18s 是否触发服务器 Declined 回滚需实战观察; 若频繁回滚调大 slider
- [ ] FE 动画在部分游戏会被服务器动画管理器覆盖 (Gakuran 有自己的 Animate 系统) — 若全服不可见仅本地可见, 备选方案 = 物理姿态模拟 (PlatformStand + CFrame 倾斜)
- [ ] 替身使者可加更多 JOJO 动画 ID (社区资源丰富)

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [用 HttpService:GetAsync 出网] → [403 "disabled/blacklisted for security reasons"] → [一律走 executor 的 request()]
- [把 v7538 的"Bike staged 待上线"当现状] → [白等功能计划] → [placeVersion 变了先复核旧结论, v7560 已删 Bike]
- [对 hookfunction detour 过的函数用 getupvalue] → [报错, 校验失败整个功能停摆] → [找同一闭包链上未被 detour 的函数当锚 (如 ServerResponse)]
- [以为客户端播自己角色动画不能全服可见] → [绕远路逆向服务器白名单, 结论错误] → [Roblox 网络所有权规则: 自己角色上的 Animator 动画随所有权复制, FE anim 脚本的标准原理]
- [拿 catalog 商品 ID 当 AnimationId 用] → [LoadAnimation 成功但 Length=0 不播] → [GetObjects 拆包取内部 Animation.AnimationId]
- [反编译注释的 upvalue 顺序直接当地址硬编码] → [运行时布局不符, 功能静默失效] → [dump 实测布局 + 找稳定值锚点 (如 ComboResetTime=1.55) 做运行时校验]
