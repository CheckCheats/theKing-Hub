# [🔥UPD] Sniper Arena TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

```
版本号语义 (ScriptVersion, 写在 hub.luau 头部注释块):
  MAJOR  主版本   — 重构 / UI库或通信层更换 / 功能体系重做 (破坏性)
  MINOR  次版本   — 新增功能 / 显著增强现有功能
  PATCH  修订号   — bug修复 / 参数微调 / 文案修正 (不改变功能面)
```

---

## v0.4.2 [2026-09-03]
- fix: 别人注入只出 General、没有暴力页 — 未 GetService(ReplicatedStorage), 建窗后直接报错退出; 战斗模块失败也不再中断建 Tab
  PATCH → v0.4.1→v0.4.2

## v0.4.1 [2026-09-03]
- enhance: 暴力页全部参数(含可视化)写入本地配置, 重开脚本开关/滑条按上次显示
  PATCH → v0.4.0→v0.4.1

## v0.4.0 [2026-09-03]
- enhance: 静默瞄准下新增「可视化」— 开启后只锁子弹实际打得到的人, 墙后不锁; 出生屏障按游戏规则不挡
  MINOR → v0.3.4→v0.4.0

## v0.3.4 [2026-09-03]
- fix: 静默瞄准只锁大厅、锁不到对局里的人 — 对局模型在 Highlight 敌人夹且必须拿枪/刀; 不再把「不是 Character」的对局外观当尸体丢掉
  PATCH → v0.3.3→v0.3.4

## v0.3.3 [2026-09-03]
- fix: 改完谁都不锁 — IsAlive/IsFriendly 问到角色模型会假死/全员友方; 只问 Player 或人机根模型; 非组队局不跳过任何人
  PATCH → v0.3.2→v0.3.3

## v0.3.2 [2026-09-03]
- fix: 队伍检测改用 IsFriendly (Player/实体模型都会问); 关掉检测不再误滤敌人
- fix: 死人锁 — IsAlive/GetHealth 对玩家、角色、Entities 根模型都查, 不靠 Humanoid.Health
  PATCH → v0.3.1→v0.3.2

## v0.3.1 [2026-09-03]
- fix: 开队伍检测后谁都锁不到 — 选人误调尚未声明的角色函数直接报错; 人机同占位队名不再当队友
  PATCH → v0.3.0→v0.3.1

## v0.3.0 [2026-09-03]
- enhance: 瞄准逻辑改为单选 (准星附近 / 距离近 / 准星与距离); 其下增加最大距离滑条
- enhance: 全部功能去掉描述行, 缩短控件间距
  MINOR → v0.2.1→v0.3.0

## v0.2.1 [2026-09-03]
- fix: 静默瞄准扫不到人机 — 嵌套 Entities 也会扫; 人机不当友方; 无 Humanoid 也能锁; 圈内略优先 AI
  PATCH → v0.2.0→v0.2.1

## v0.2.0 [2026-09-03]
- enhance: 静默瞄准下新增「瞄准逻辑」— 准星附近优先, 距离近优先 (默认开)
  MINOR → v0.1.5→v0.2.0

## v0.1.5 [2026-09-03]
- fix: 开静默锁不到人 — 恢复选人扫描; 开枪不再被静音窗口挡住; 进圈改回全身部位; 靶场不再当大厅过滤掉
  PATCH → v0.1.4→v0.1.5

## v0.1.4 [2026-09-03]
- fix: 开关一点就崩 — 不是存档, 是界面把整行做缩放动画 (跟改白圈大小同一类)
  PATCH → v0.1.3→v0.1.4 (跟 lib v2.0.5)

## v0.1.3 [2026-09-03]
- fix: 开队伍检测崩溃 — 去掉 Toggle Flag 即时存档; 自动扳机同样处理
  PATCH → v0.1.2→v0.1.3

## v0.1.2 [2026-09-03]
- fix: 没开静默不再画圈; 启动不建 Drawing; 范围绘制默认关且去掉 Flag
- fix: 开静默不再后台扫人画线 (只在开枪时锁)
  PATCH → v0.1.1→v0.1.2

## v0.1.1 [2026-09-03]
- fix: 打开静默瞄准崩溃 — 开关不再立刻存档/全身扫描, 松手后再选人
  PATCH → v0.1.0→v0.1.1

## v0.1.0 [2026-09-03]
- chore: 版本号重置为 v0.1.0 (对外重新编号, 功能不变)

## v1.3.2 [2026-09-03]
- fix: 拖范围崩溃 — 滑条不再 Flag 连存; 白圈半径松手后再改; 瞄准范围仍即时生效
  PATCH → v1.3.1→v1.3.2

## v1.3.1 [2026-09-03]
- fix: 静默瞄准锁尸体 — 游戏血量走 EntityService.IsAlive/GetHealth, Humanoid.Health 死后仍为 100
  PATCH → v1.3.0→v1.3.1

## v1.3.0 [2026-09-03]
- enhance: 静默/绘制/范围/队伍/扳机及显示隐藏、卸载快捷键全部 Flag 持久化, 重进自动恢复
  MINOR → v1.2.1→v1.3.0

## v1.2.1 [2026-09-03]
- fix: 个人竞技全员占位队名(Team3)被当成组队, 开队伍检测后锁不到玩家和 AI
  PATCH → v1.2.0→v1.2.1

## v1.2.0 [2026-09-03]
- fix: 静默瞄准扫不到 `World.<地图>.Entities` 且 isEntityFriendly 前向引用导致选人报错被吞
- enhance: 范围绘制补回准星连线 + 锁定部位旋转 3D 十字 (Drawing 常驻, 关则挪出屏幕)
  MINOR → v1.1.9→v1.2.0

## v1.1.9 [2026-09-03]
- fix: 游戏厅整图被当成禁区导致静默瞄准无效果; 白圈去掉 GuiInset, 圆心与准星对齐
  PATCH → v1.1.8→v1.1.9

## v1.1.8 [2026-09-03]
- fix: 暴力页所有开关只写布尔(去掉 Flag/Notify/StartLoop); 白圈改回 Drawing 一次创建, 渲染循环跟半径, 关掉挪出屏幕
  PATCH → v1.1.7→v1.1.8

## v1.1.7 [2026-09-03]
- fix: 开静默也会崩 — 根因是心跳在开关后改白圈尺寸, 不是按钮控件; 白圈只在创建时写一次, 开关不再动 GUI
  PATCH → v1.1.6→v1.1.7

## v1.1.6 [2026-09-03]
- fix: 关范围绘制仍崩 — 改成按钮切换(不走 Toggle 存档); 关掉后心跳不再改白圈尺寸
  PATCH → v1.1.5→v1.1.6

## v1.1.5 [2026-09-03]
- fix: 开静默/关范围绘制崩溃 — 开关只改布尔值; 白圈心跳脚本加载时挂上且不再 Disconnect; 撤掉 Drawing 连线十字
  PATCH → v1.1.4→v1.1.5

## v1.1.4 [2026-09-03]
- enhance: 大厅([游戏厅]/Lobby 范围内) 暴力功能内部失效, 开关不用关; 进对局自动恢复
- fix: 关范围绘制不再 Disconnect/改 Enabled; 白圈用尺寸归零隐藏; Drawing 线移出屏幕而不是 Visible=false
  PATCH → v1.1.3→v1.1.4

## v1.1.3 [2026-09-03]
- fix: 范围绘制开关崩溃 — 白圈恢复为独立 ScreenGui; 准星连线/旋转十字改 Drawing 线, 不再往白圈里塞 Frame、不在开关回调里改控件
  PATCH → v1.1.2→v1.1.3

## v1.1.2 [2026-09-03]
- fix: 关范围绘制崩溃 — 开关只改标志; 0.2s 后再停心跳/循环; 不再在回调里改线/十字 Visible
  PATCH → v1.1.1→v1.1.2

## v1.1.1 [2026-09-03]
- fix: 开静默瞄准崩溃 — 心跳不再扫人/射线; 开关后延迟再画 HUD; 目标扫描改独立低频循环
  PATCH → v1.1.0→v1.1.1

## v1.1.0 [2026-09-03]
- enhance: 队伍检测 — 个人混战(每人各一队/无队)内部失效, 开关不用关; 有真实队伍则不瞄队友
- enhance: 范围绘制 — 白圈外再画准星到锁定部位的 2D 线, 以及部位上旋转十字
  MINOR → v1.0.1→v1.1.0

## v1.0.1 [2026-09-03]
- PATCH: 跟随 lib v2.0.3 黑金主题发布 (Logo 呼吸 / 切 Tab 淡入 / 侧栏白字)。玩法不变。

## v1.0.0 [2026-09-03]
- MAJOR: 跟随 lib v2.0.0 迁 Rayfield Gen2 + 品牌方圆标。玩法不变。

## v0.3.12 [2026-09-02 | pv154]

### Fixed
- 卸载崩溃: 对话框关闭后再 Destroy; 跳过 SaveConfig; WindUI/FOV 仅 Enabled=false 不 Parent=nil (lib v1.8.1)

---

## v0.3.11 [2026-09-02 | pv154]

### Fixed
- 开关静默瞄准崩溃: hook 改为启动后一次性安装, Toggle 只改 `silentAim.enabled` 标志; 不在开关时 setupvalue 挂/卸

---

## v0.3.10 [2026-09-02 | pv154]

### Fixed
- 开启静默瞄准后卸载崩溃: 卸载不再同步 setupvalue 还原 hook; 先关运行时再等帧后 Destroy; hook 留待下次注入延迟还原

---

### Fixed
- 点击卸载崩溃: 卸载逻辑整段 defer 到对话框外; 移除 Destroy 内 Window:Close; hook 还原不再走 OnCleanup

---

### Fixed
- 注入/热替换/卸载崩溃: Potassium 禁止 `Window:Destroy` 与 FOV GUI 硬删, 改软卸载 (Close + Parent=nil)
- theking 热替换走 `Destroy({ hotSwap=true })`, 先停循环/清 hook 再藏 UI

---

### Fixed
- 热替换/重注入崩溃: 恢复 theking 同步关窗; 白圈 Heartbeat 改按需连接; 销毁时先断连再删 GUI
- AI 选人: 用 EntityService.IsFriendly 过滤友方; 移除不存在的 GetEntities 调用

---

### Fixed
- 静默瞄准: 不再只扫玩家列表, 同时纳入 workspace AI/NPC (Entities/Live/NPCs 等容器 + EntityService 实体表)

---

### Added
- 静默瞄准下方新增「范围绘制」开关: 关闭后不画白圈, 瞄准逻辑仍生效; Flag 持久化

---

### Fixed
- 静默瞄准: 圈内看得见人却不锁 — 改为部位轮廓进圈即锁定该敌人, 再在其身上选最好打的露出点; 不再用骨骼中心跨人混分
- 点击卸载崩溃: 确认后推迟销毁窗口/白圈, 避免在按钮回调里同步 Destroy

---

### Changed
- 静默瞄准: 头/躯干/四肢分部位检测露出; 优先锁最好命中的露出部位 (躯干略优先于头); 全被挡时回退圈内最近点

---

## v0.3.2 [2026-09-01 | pv154]

### Fixed
- 使用中闪退: 白圈不再走注入器 Drawing (热替换/卸载时 Destroy 会崩客户端), 改为 ScreenGui 空心圈; 销毁前先断开更新

---

## v0.3.1 [2026-09-01 | pv154]

### Fixed
- 静默瞄准: 圈内有人却不锁 — 改为头/胸/根骨任一进圈即可, 不再要求头必须在圈里, 也不再被墙/栏杆视线检测挡掉

---

## v0.3.0 [2026-09-01 | pv154]

### Changed
- 静默瞄准: 不再 360° 锁世界距离最近; 改为屏幕中心白圈范围内、离准星最近的可见敌人
- 静默瞄准描述简化

### Added
- 范围滑条 (默认 60): 控制白圈半径, 圈越大可瞄范围越大

---

## v0.2.1 [2026-09-01 | pv154]

### Fixed
- 自动扳机: 开启后不再立刻模拟点击把开关点回去; 鼠标在 HUB 上时不开枪

---

## v0.2.0 [2026-09-01 | pv154]

### Added
- 暴力-队伍检测: 开启后不瞄准同队 (混战 Default 不互判队友)
- 暴力-自动扳机: 静默瞄准锁人开枪; 未开静默时准星有人开枪

### Fixed
- DEL 显示/隐藏窗口: 不再走 Window:Toggle (动画链会崩游戏), 改为切 ScreenGui.Enabled

### Removed
- 暴力 Tab 状态栏

---

## v0.1.5 [2026-09-01 | pv154]

### Fixed
- 静默瞄准: 不再用 hookfunction (会丢掉 CombatOriginFn 的 3 个返回值, 开了就开不了枪)
- 改为 setupvalue 替换 Shoot/LocalShoot 里的 CombatOriginFn, 完整保留返回值

---

## v0.1.4 [2026-09-01 | pv154]

### Fixed
- 静默瞄准开启后无法开枪: CombatOriginFn 多返回值丢失 + 改在 Shoot 窗口预扫描
- 开启时 lazy 挂 Shoot(inShoot) + CombatOriginFn(仅替换 CFrame), 近战/关功能不受影响

---

## v0.1.3 [2026-09-01 | pv154]

### Fixed
- 静默瞄准: 改为 lazy hook — 仅开启功能时挂 CombatOriginFn, 关闭/未开启时零 hook
- 移除 ClientShootableComponent.Shoot hook (注入即挂导致功能关闭也无法射击)

---

## v0.1.2 [2026-09-01 | pv154]

### Fixed
- 静默瞄准: 移除 AsyncRaycast/RaycastUtils hook (叠层 nil 致无法射击)
- 改为 ClientShootableComponent.Shoot 同步窗口 + CombatOriginFn 单点改向

---

## v0.1.1 [2026-09-01 | pv154]

### Fixed
- 静默瞄准: 改为仅在 Shoot 调用栈内改方向, 修复开启后无法开枪 (误 hook 近战/标记用的 CombatOriginFn)

---

## v0.1.0 [2026-09-01 | pv154]

### Added
- 初始骨架: 暴力 / 设置 Tab
- 静默瞄准: 360° 最近可见敌人, 开枪时自动对准 (CombatOriginFn + 双射线模块 Swap)

### 逆向依据
- intel.md [2026-09-01 | pv154] Shoot 流程与 CombatOriginFn 单例结论
