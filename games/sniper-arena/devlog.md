# [🔥UPD] Sniper Arena TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

---

---

---

---

---

---

---

---

---

## [2026-09-03 | v0.4.1 → v0.4.2] 别人注入只有 General 没有功能

窗口已经起来 (Rayfield 自带 General), 暴力/设置 Tab 在文件后半才 NewTab。开头 `ReplicatedStorage:WaitForChild` 没 GetService, 作者注入器有服务全局所以能跑, 别人 `nil` 一炸整段停掉。改成 GetService + pcall require, 模块没有也不 return。

---

## [2026-09-03 | 发布包 | 别人注入找不到运行库]

Loader 注入狙击场报 `[TheKing] 找不到 theking.luau 运行库`。hub 开发态用 `LIB_CANDIDATES` + `isfile` 找本地库, `build.py` 只替换 `loadstring(libSource)` 行, 探测循环留在单文件里。作者本机有库所以不炸, 别人没有。修 `tools/build.py` 剥探测块并加产物门禁; 重打 sniper-arena / gakuran 发布包。

---

## [2026-09-03 | v0.4.0 → v0.4.1] 参数本地记住

暴力页开关/下拉/滑条(静默、可视化、瞄准逻辑、距离、范围绘制、范围、队伍、扳机)写 `TheKing_sniper_cfg.txt`, 不走 Rayfield Flag。创建时 Value 用存档, 界面和实际一致。旧 fov/dist 文件仍作迁移。

---

## [2026-09-03 | v0.3.4 → v0.4.0] 可视化: 只锁打得到的人

以前选人被墙挡住也会回退锁上。游戏子弹走 `Team1Atk/Team2Atk/Team3Atk`: 打对面+地图(`Default`), 不打队友、不打 `Barrier`。

可视化开: 用同一碰撞组从枪口射线, 第一下必须打在目标(高亮或同名 World 碰撞体)的 CanQuery 部位, 否则不锁。关: 行为与之前一样。

---

## [2026-09-03 | v0.3.3 → v0.3.4] 对局锁不到人、只会锁大厅

实机: `Player.Character` 停在 `Workspace.<名>` 且无枪骨; 对局外观在 `Workspace.Highlight.Enemy.HighlightHolder.<名>`, 带 `Gun-Main`/`Gun-*` 骨骼; `GetPlayerFromCharacter` 对高亮模型仍能拿到 Player, 但其 `Character` 仍是大厅模型。

旧逻辑整棵跳过 Highlight, 又把 `owner.Character ~= 当前模型` 当尸体, 对局目标全灭, 只剩大厅没枪的人。

现: 有持械高亮/World 实体时只锁那些; 友方走 `Highlight.Friendly`; 没持械实体时才回退靶场假人。

---

## [2026-09-03 | v0.3.2 → v0.3.3] 改完全不锁

entityCall 拿第一个非 nil: `IsAlive(Character)` 对活人返回 false, `IsFriendly(Character)` 对全员 true。改为玩家只问 Player、人机只问 Entities 根; 队伍检测仅在确认真多队伍时过滤。

---

## [2026-09-03 | v0.3.1 → v0.3.2] 锁队友 / 漏敌人 / 锁死人

IsFriendly 以前关检测也在滤人, 且只问 Character; GetTeam 全员 Team3 时检测等于没开所以锁队友。死人 Humanoid.Health 仍 100。

现: 仅队伍检测开启时用 IsFriendly (Player→角色→Entities 根); 失败才回退 GetTeam。存活同样多主体查询。

---

## [2026-09-03 | v0.3.0 → v0.3.1] 队伍检测锁不到任何人

`isTeammateCharacter` 在 `getLocalCharacter` 声明前闭包到全局 nil, 开检测后选人 pcall 全失败, 队友敌人都不锁。函数提前定义; 人机仅在真组队且队名相同才跳过。

---

## [2026-09-03 | v0.2.1 → v0.3.0] 瞄准逻辑单选 + 最大距离 + 去描述

Dropdown 三选一; 最大距离 50–8000 延迟写入 TheKing_sniper_dist.txt。所有 Toggle/Slider/Keybind/Button 不再传 Desc, Rayfield 不再插描述行。

---

## [2026-09-03 | v0.2.0 → v0.2.1] 锁人机 AI

Entities 里套着 Model 时旧扫描只认直系 Humanoid/Folder, 人机被跳过。`IsFriendly` 可能把 NPC 当友方。`IsAlive` 用人机模型时仍可过, 但无 Humanoid 直接 false。同名 Player 尸体过滤也会误杀 AI。

现: 递归 Model 最多 5 层; 人机不走 IsFriendly; 有部位即可; 选人分数给人机一点优先; FetchEntity 用 pairs。

---

## [2026-09-03 | v0.1.5 → v0.2.0] 瞄准逻辑

静默瞄准下增加开关, 默认开。圈内选人: 屏幕离准星 70% + 世界距离 30%; 部位再加距离权重。关掉则仍只按准星远近。

---

## [2026-09-03 | v0.1.4 → v0.1.5] 锁不到敌人

防崩时拆掉了后台选人, 开枪包装还被 `uiQuietUntil` 挡住; 进圈只扫关键部位; `Lobby` 祖先把靶场假人滤掉。扫描 0.15s 恢复 (开静默 0.25s 后才扫, 不碰 UI 点击栈)。范围绘制仍须静默开着才画圈。

---

## [2026-09-03 | v0.1.3 → v0.1.4 | lib v2.0.5] 开关一点就崩 (非存档)

Rayfield Toggle 点击链: Tween 行 `Size` (1,-20 → 1,-26) + UIStroke + `_animateIndicator`。Potassium 改 ScreenGui/Frame Size 原生崩, 与白圈 Size 同一类。队伍检测回调只写布尔也会崩, 因为动画在回调之前。

theking Toggle/Button: 掐掉原点击, 叠一层无动画按钮; 旋钮瞬切; 回调 `task.defer`。

---

## [2026-09-03 | v0.1.2 → v0.1.3] 开队伍检测崩溃

Rayfield Toggle `Flag=teamCheck` 点开即 autoSave, 与静默/范围绘制同一条 Potassium 崩路径。暴力页剩余 Flag 全部去掉 (含自动扳机); 回调只写布尔。

---

## [2026-09-03 | v0.1.1 → v0.1.2] 没开静默也画圈 + 开关再崩

### 根因
1. `drawFov` 默认 true + 启动 `ensureFovDraw` + RenderStepped 每帧写圈, 静默关着也有白圈
2. `Flag=silentAimDrawFov` 读档把绘制强制打开
3. 渲染循环里 `fovDraw or ensureFovDraw()` 会在 RenderStepped 里 `Drawing.new`
4. 开静默后 Heartbeat 仍 `findBestTarget`

### 改动
- 必须静默+范围绘制都开才延迟建 Drawing; 渲染循环只更新已有对象
- 范围绘制默认关, 去掉 Flag; 不再启动即画
- 去掉后台锁人扫描, 开枪时才选目标
- Toggle 回调只写布尔

### 遗留
- 待用户重跑 v0.1.2: 默认无圈; 只开静默不崩; 再开范围绘制才出圈

---

## [2026-09-03 | v0.1.0 → v0.1.1] 开静默瞄准崩溃

### 根因
Toggle `Flag=silentAim` 点开即 Rayfield autoSave; 同帧后 Heartbeat `findBestTarget` 对全身 `GetDescendants` + 多点投影 + 射线。Potassium 原生崩 (与 v1.1.1 / Flag 存档同类)。

### 改动
- 静默开关去掉 Flag, 状态延迟写入 `TheKing_sniper_sa.txt`
- 开启后 0.55s 才选人/画锁定线; 开枪包装同样避开这段
- 进圈判定改用关键瞄准部位, 不再每次全身 GetDescendants

### 遗留
- 待用户重跑 v0.1.1 后点开静默验证

---

## [2026-09-03 | v0.1.0] 对外版本号重置

ScriptVersion / 头部 / 启动印记改为 v0.1.0, 玩法与 v1.3.2 相同。

---

## [2026-09-03 | v1.3.2] 拖范围崩溃

Rayfield Slider Flag 每格 autoSave + RenderStepped 立刻写 Drawing.Radius, Potassium 崩。滑条只改 fovRadius 数字; 0.22s 无拖动才写 Radius; 范围存 `TheKing_sniper_fov.txt`。

---

## [2026-09-03 | v1.3.1] 不锁死人

Humanoid.Health 死后仍 100。`EntityService.IsAlive` / `GetHealth` 对 Player 或 Entities 模型有效, 对 Character 无效。另跳过 Lobby/Highlight/_Temp/Died 残留, 以及已不是 player.Character 的尸体。选人循环当场再验活。

---

## [2026-09-03 | v1.3.0] 功能设置持久化

Callback 仍只写布尔/数值 (不 Notify/StartLoop)。Flag: silentAim / silentAimDrawFov / silentAimFov / teamCheck / saAutoTrigger / uiToggleKey / uiUnloadKey。LoadConfig 后 syncPersistedUiState。

---

## [2026-09-03 | lib v2.0.4] 隐藏窗口后鼠标交还游戏

Rayfield `mouseOverride` 开菜单时解锁鼠标, 隐藏/最小化只停止强制、不恢复 LockCenter, 狙击场第一人称会一直露出指针。theking 包装 Hide/Show/ToggleHide/ToggleMinimise, 菜单不在交互态时 `MouseIconEnabled=false` + `LockCenter`。

---

## [2026-09-03 | v1.2.1] 个人竞技开队伍检测锁不到人

### 根因
实机全员 GetTeam=`Team3` (玩家+AI)。旧逻辑「同队>=2人」=组队, 于是全员互判队友。

### 改动
`refreshTeamPlay`: 至少两支不同真实队名才 teamPlay

---

## [2026-09-03 | v1.2.0] 静默无目标 + 线/十字

### 根因
- 敌人在 `Workspace.World.<uuid>.Entities`, 只扫了 workspace 直系 `Entities`
- `isValidEnemyCharacter` 调用尚未声明的 local `isEntityFriendly`, 选人抛错被 hook 里 pcall 吃掉, 永远无目标

### 改动
- 前向声明修好; 扫描 World 子节点 Entities
- 0.12s 心跳刷新 lastTargetPart 供绘制 (不在 RenderStepped 里选人)
- Drawing Line: 准星连线 + 三轴旋转十字, 隐藏仍走挪出屏幕

---

## [2026-09-03 | v1.1.9] 游戏厅静默无效果 + 圆心偏下

### 根因
实机 Place=`[游戏厅]` 126042865144779, `combatZoneActive()` 按 PlaceId 直接 false, 开枪不改方向。白圈 Y 加了 inset 58px, 圆心偏下。

### 改动
- 静默瞄准不再按大厅 Place 禁用; 选人与 hook 在靶场也工作
- 自动扳机仍用 Lobby 模型包围盒避开排队区
- FOV/选人共用无 inset 的视口中心

---

## [2026-09-03 | v1.1.8] 开源 Drawing FOV + 开关全员去副作用

### 对照
Exunys / Stefanuk / ketachka: `Drawing.new("Circle")` 启动一次, `RenderStepped` 写 Position/Radius, Toggle 只改 `ShowFOV` 布尔; 卸载先断连再 `:Remove()`

### 本注入器差异
- 开关回调里改 Visible / 存 Flag / Notify / StartLoop 会原生崩
- 藏圈不写 Visible, 把 Position 挪到 (-10000,-10000)
- 热替换用 `_G.RCWTK_SA_FOV_DRAW` 先 Remove 旧圈再新建

### 改动
- 去掉 ScreenGui 白圈
- 队伍检测/自动扳机与静默瞄准同一套: Callback 只写布尔; 扳机心跳常驻
- 滑条改 `fovRadius`, 渲染循环差分写 Radius

---

## [2026-09-03 | v1.1.7] 开静默与关绘制同一根因

### 根因
不是按钮控件。`silentAim.enabled=true` 后心跳 `updateFovCircle` 把 Ring.Size / UIStroke.Transparency 从 0 写成可见值, Potassium 原生崩。关绘制则是写成 0, 同一条写 GUI 路径。

### 改动
- 去掉 FOV Heartbeat
- 白圈在 `ensureFovCircle` 里按当前半径一次建好, 之后永不改属性
- 静默/绘制恢复 Toggle; 去掉 Flag/Notify/开时清缓存, Callback 只写布尔
- 范围滑条去掉 Flag (拖动不再存档)

### 代价
白圈一直在; 拖滑条只改瞄准半径, 圈看起来不会跟着变

---

## [2026-09-03 | v1.1.6] 关绘制仍崩

### 根因
v1.1.5 Toggle 只写布尔, 但 Rayfield Toggle+Flag 存档, 以及下一帧心跳把白圈 Size 写成 0, 仍会打崩 Potassium

### 改动
- 范围绘制改为 Button 点按翻转 `drawFov`, 无 Flag
- `updateFovCircle` 在 show=false 时直接 return, 不写 Size/Transparency
- LoadConfig 不再读绘制开关

### 代价
关掉后白圈可能残留在屏幕上; 静默瞄准圈选逻辑仍按标志关闭

### 遗留
若点按钮仍崩, 就是 Notify/Rayfield Button 本身, 只能拿掉绘制入口

---

## [2026-09-03 | v1.1.5] 开关只改标志

### 根因
开静默/关绘制仍调用 connect Heartbeat / StartLoop / Drawing / Enabled, Potassium 原生崩

### 改动
- Toggle 只写 silentAim.enabled / drawFov
- 白圈 ScreenGui 启动时建好, Heartbeat 常驻, 仅在直径变化时改 Size
- 连线/十字 Drawing 全部撤掉 (防崩优先)

---

## [2026-09-03 | v1.1.4] 大厅内部失效 + 关绘制不再碰 GUI Enabled

### 改动
- `isInLobby`: PlaceId 126042865144779 / 名称含游戏厅 / 站在 workspace.Lobby 包围盒内
- 静默/绘制/扳机内部 return, 开关保持
- 范围绘制开关只写 `drawFov`; 心跳用 Size=0 藏圈; Drawing 挪到屏幕外

---

## [2026-09-03 | v1.1.3] 范围绘制开关仍崩溃

### 根因
线/十字是 ScreenGui Frame, 开关时改 Visible/Rotation/Enabled 与白圈同一层, Potassium 原生崩

### 改动
- 白圈回到 v1.0 结构 (只有 Ring+UIStroke)
- 连线与旋转十字用 Drawing.new("Line"), 开关只改标志, 循环里 Visible=false 停画
- 不再用 Highlight / 不再在心跳里 findBestTarget

---

## [2026-09-03 | v1.1.2] 关范围绘制崩溃

### 根因
Toggle 回调里立刻 Disconnect Heartbeat + 改 AimLine/AimCross Visible + StopLoop

### 改动
- 开关只写 `drawFov`; 心跳见标志后只关整个 FOV Enabled
- 真正停心跳/扫描循环延迟 0.2s, 且不再 hideAimOverlay

---

## [2026-09-03 | v1.1.1] 开静默瞄准崩溃

### 根因
范围绘制在 Heartbeat / 开关同帧调用 findBestTarget (GetDescendants + Raycast + GetTeam), Potassium 原生崩

### 改动
- 心跳只更新白圈和缓存部位的线/十字
- 选人扫描改 StartLoop 0.15s, 开关后 0.25s 才开始
- 白圈预创建; 线/十字不和开关同帧新建整窗

### 验证
- 待用户: 开静默不崩, 绘制仍有圈/线/十字

---

## [2026-09-03 | v1.1.0 | lib v2.0.3] 队伍检测内部失效 + 瞄准绘制

### 目标
个人竞技不关开关也能打全员; 有队则屏蔽队友。范围绘制补准星连线与锁定部位旋转十字。

### 改动
- `refreshTeamPlay`: 真实队名下至少 2 人同队才 teamPlay; 否则 isTeammateCharacter 直接 false
- FOV HUD: AimLine + AimCross (Heartbeat 50ms 扫目标, 十字持续旋转)

### 遗留
- 待实机: 混战全员可锁; 队内赛不锁队友; 开范围绘制能看见线+十字

## [2026-09-03 | v1.0.1 | lib v2.0.3] 黑金主题发布
跟随共享库主题打混淆包推 Gitee。玩法未改。

## [2026-09-02 | 会话20 | v0.3.12 | lib v1.8.1] 卸载仍崩溃

### 根因
Confirm 回调栈未退出时 SaveConfig / ScreenGui Parent=nil 清 WindUI, Potassium 原生崩溃

### 改动
- theking: Confirm 确定键 task.defer OnConfirm; Destroy({ skipSave }) ; softHide 默认只 Enabled=false
- hub performUnload: 先停循环/断 FOV, 0.45s 后 Destroy({ skipSave=true }); FOV 不再 Parent=nil

### 验证
- 待用户: 开静默后 END/卸载按钮不崩

---

## [2026-09-02 | 会话19 | v0.3.11] 开关静默瞄准崩溃

### 根因
Toggle 回调 (WindUI 栈) 内同步/延迟 `debug.setupvalue` 挂接或还原 Shoot hook, Potassium 开/关均崩

### 改动
- `installSilentAimHooks` 仅在 `bootstrapSilentAimHooks` 延迟一次性执行 (~0.38s 后)
- `setSilentAimEnabled` 只改 `silentAim.enabled` + FOV Heartbeat, 永不 uninstall
- Toggle Callback 改 `task.defer`, 移除 `deferRestoreSilentAimHooks`
- 移除加载时同步 `restoreGlobalHooks()`; 还原并入 bootstrap 首步
- `syncPersistedUiState` 读 `uiRefs.silentAim.Value` 恢复开关

### 验证
- 待用户: 注入见 v0311, 开关静默不崩, 开静默后卸载不崩

---

## [2026-09-02 | 会话18 | v0.3.10] 静默开启时卸载崩溃

### 根因
卸载时同步 `debug.setupvalue` 还原 Shoot hook (静默瞄准开启状态下)

### 改动
- `performUnload`: 只 `disableSilentAimRuntime`, 不还原 hook; 分帧等待后再 Destroy
- 关静默 Toggle 也 defer 还原 hook
- 下次注入 0.25s 后延迟 restoreGlobalHooks

---

### 根因
- 卸载确认回调栈内同步清 hook/FOV; Destroy 仍调 Window:Close
- OnCleanup 里 setupvalue 还原与对话框同栈

### 改动
- `performUnload` 整段 task.defer, 对话框只触发 defer
- theking.Destroy 去掉 Close, 只 softHideWindUi
- 静默 hook 不再注册 OnCleanup, 只走 _G restore

---

### 目标
注入/热替换直接崩溃客户端。

### 根因
- Potassium 上 `Window:Destroy()` 与 gethui ScreenGui `:Destroy()` 会原生崩溃
- 热替换只等一帧, 旧窗未卸完新实例已建

### 改动明细
- theking.Destroy: 热替换仅 StopAll+断连, 不跑 OnCleanup/不 Close/不 Destroy 窗口
- 新实例 CreateWindow 前软隐藏旧 WindUI; hub 启动立刻 restore 静默 hook
- 完整卸载仍软隐藏 UI (Parent=nil), 永不硬 Destroy

### 验证
- 连续注入两次应出现「旧实例已销毁, 接管完成」+ SNIPER_HUB_v038

---

### 目标
脚本不会瞄准 AI 敌人。

### 改动明细
- `collectEnemyCharacters`: 玩家 + EntityService 实体表 + workspace 常见 AI 容器 + 顶层 Humanoid Model
- 队伍判定改 `isTeammateCharacter`, EntityService.GetTeam 支持 Model
- 自动扳机射线改 `getCharacterFromHit`, AI 也能触发
- 敌人列表 0.25s 缓存, 避免每枪全扫

### 验证
- 对 AI 开静默应能锁; 自动扳机对 AI 也应开枪

---

### 目标
静默瞄准下方加「范围绘制」; 关掉不画白圈; 参数可持久化。

### 改动明细
- `silentAim.drawFov` + `setDrawFovEnabled`; `updateFovCircle` 双重 gate
- Toggle `Flag=silentAimDrawFov` 默认开; 存 uiRefs 供 LoadConfig 后同步
- `syncPersistedUiState`: Load 后读 Toggle/Slider Value (WindUI Set(false) 不走 Callback)

### 验证
- 关范围绘制白圈消失、静默仍锁; 重跑后状态恢复

---

### 目标
圈内有敌人有时不锁; 点卸载脚本导致 Roblox 崩溃。

### 改动明细
- 选人改两段: 任意部位轮廓进圈 → 锁离准星最近的人 → 再在该人身上选露出/好打部位
- 进圈检测用部位中心+包围盒六端点, 不再只测骨骼中心
- 补 R6 `Left Arm` 等命名; 递归查找骨骼
- 卸载: 确认回调里先关静默/白圈, `task.defer` Destroy; 白圈 Parent=nil 后再 Destroy; theking `Window:Destroy` 也推迟到帧后
- FOV 圈优先挂 gethui, 避免跟 PlayerGui 一起被拆

### 决策记录
- 上次 ease 虽注释「只比同一人」但实现是全局混分, 会表现为圈内近的人不锁
- WindUI Dialog 确定按钮栈上 Destroy 窗口是已知崩溃点

### 验证
- Potassium 注入 v034 启动日志; 圈内漏锁回归; 点卸载不应崩

---

### 目标
提高静默瞄准命中率: 不强制打头; 头/身体谁露出且更好打就锁谁。

### 改动明细
- `AIM_PART_NAMES` 扩至头/躯干/HRP/上臂/前臂 (R6/R15)
- `isPartExposed`: 枪口→部位射线, 仅该敌人自身遮挡算露出
- `PART_HIT_EASE`: 躯干等大部位评分加权, 同距优先躯干
- `findBestTarget`: 先选露出部位最低分; 全无露出时回退圈内最近 (防栏杆误杀)

### 决策记录
- 不做全局 canSee (v0.3.1 已证伪会误杀), 改为**分部位**露出判定
- ease 只影响同敌多部位取舍, 不跨敌抢锁

### 验证
- 待注入: 只露头/只露胸/头胸都露三种场景

---

### 目标
使用脚本过程中客户端闪退。

### 改动明细
- 去掉 `Drawing.new("Circle")`, 改 PlayerGui/gethui 上 ScreenGui+UIStroke 空心圈
- 销毁先 Disconnect Heartbeat 再 Destroy GUI (TheKing.Destroy 先跑 OnCleanup 再断连, Drawing 会一边画一边删)
- CombatOriginFn 包装体 pcall, lookAt 失败不影响开枪

### 决策记录
- 上次热替换停在「触发其自毁」后无 v031 启动日志, 客户端 PID 已换, 符合原生崩溃
- 不改 theking Destroy 顺序, 本游戏自管连接生命周期

### 验证
- 待注入: 开静默瞄准画圈、关功能、热替换不崩

---

## [2026-09-01 | 会话10 | v0.3.1 | lib v1.7.4] 圈内不锁人

### 目标
圈里看得到敌人, 开枪却不锁他。

### 改动明细
- `findBestTarget` 检测 Head/UpperTorso/Torso/HRP/LowerTorso, 任一进圈且在镜头前方即可
- 去掉 `onScreen` 和 `canSee` 硬过滤 (头略出屏、栏杆挡住射线时会被误杀)

### 决策记录
- 默认 60px 很小, 瞄身体时头经常在圈外
- 选人仍按 2D 距准星最近的那个部位

### 验证
- 待注入重跑后进圈开枪

---

## [2026-09-01 | 会话9 | v0.3.0 | lib v1.7.4] 静默瞄准改屏幕 FOV 圈

### 目标
静默瞄准改简单描述; 下方加范围滑条默认 60; 从屏幕中心画白圈; 圈内多人选离准星最近。

### 改动明细
- `findBestTarget`: WorldToViewportPoint, 圈内 + 可见, 按 2D 距屏幕中心选最近, 圈外不锁
- `Drawing.new("Circle")` 空心白圈, RenderStepped 跟视口中心, 半径=滑条; 静默关则隐藏; OnCleanup 销毁
- Slider `范围` Flag=`silentAimFov` Value Min10 Max400 Default60

### 决策记录
- 60 按像素半径, 与 Drawing.Radius / 屏幕 2D 距离同一单位
- 仍保留世界距离上限 5000 和视线 Raycast, 避免锁墙后的人

### 验证
- (待注入实测: 圈位置/半径、圈内选人、圈外不锁)

### 遗留
- 若 Drawing 圆心和准星有 GuiInset 偏移再补 inset

---

## [2026-09-01 | 会话8 | v0.2.1 | lib v1.7.4] 自动扳机开启即关闭

### 目标
开关一开就被关掉。

### 改动明细
- 开启后 0.6s 内不模拟点击
- 鼠标在 HUB 上时不 click
- Flag/循环名改为 saAutoTrigger, 避免和内部名撞

### 决策记录
- 根因: mouse1click 打在仍停在开关上的鼠标, 等于又点了一次 Toggle

---

## [2026-09-01 | 会话7 | v0.2.0 | lib v1.7.4] DEL 崩溃 + 队伍检测 + 自动扳机

### 目标
修 DEL 崩溃; 去掉状态栏; 加队伍检测与自动扳机。

### 改动明细
| 文件 | 改动 |
|---|---|
| hub.luau | 显示隐藏改 findHubScreenGui.Enabled |
| hub.luau | 删除状态 Paragraph + silentAimStatus 循环 |
| hub.luau | isTeammate: EntityService.GetTeam, Default 当混战 |
| hub.luau | 自动扳机: mouse1click, 静默锁人 / 准星射线 |

### 决策记录
- Window:Toggle 动画链 (Tween+DoF) 会崩, 与 Heroes RNG 同修法
- 大厅实测 Team=Default 或 Team1; Default 不当事队, 避免 FFA 全员被当成队友
- 自动扳机模拟点击, 不直调 Shoot (避免再踩 hook)

### 验证
- 待注入: DEL 隐藏不崩; 队内不锁队友; 自动扳机能打出枪

---

## [2026-09-01 | 会话6 | v0.1.5 | lib v1.7.4] hookfunction 丢多返回值

### 目标
v0.1.4 开启静默瞄准仍无法开枪。

### 改动明细
| 文件 | 改动 |
|---|---|
| hub.luau | 删除 hookfunction CombatOriginFn / Shoot |
| hub.luau | debug.setupvalue 替换 CSC.Shoot / LocalShoot 的 CombatOriginFn upvalue |

### 决策记录
- 实测 CombatOriginFn 返回 3 值: CFrame, nil, table
- Potassium hookfunction 替换后多返回值丢失, Common.Shoot assert 方向失败
- setupvalue 走 Lua 包装, table.unpack 保留 n 个返回值

### 验证
- 待注入: 开启后仍可开枪

---

## [2026-09-01 | 会话5 | v0.1.4 | lib v1.7.4] 开启静默瞄准只能用刀

### 目标
v0.1.3 功能关闭可射击; 开启后枪不能用, 刀正常。

### 改动明细
| 文件 | 改动 |
|---|---|
| hub.luau | CombatOriginFn hook 用 table.pack 保留 u62.Get 多返回值 |
| hub.luau | Shoot hook (lazy): 射击前 GetCombatOrigin 预扫描, inShoot 窗口替换 CFrame |
| hub.luau | 移除 debug.info 栈检测 (混淆名不可靠) |

### 决策记录
- 根因: hook 只 return 一个 CFrame 破坏射击链; 且在 CombatOriginFn 内 Raycast 干扰 origin
- 近战走 GetCombatOrigin 直连, 不经过 Shoot inShoot 窗口 → 刀不受影响

### 验证
- 待注入实测

---

## [2026-09-01 | 会话4 | v0.1.3 | lib v1.7.4] 注入即无法射击 — lazy hook

### 目标
用户反馈: 注入脚本后无法开枪, 功能关闭也不行。

### 改动明细
| 文件 | 改动 |
|---|---|
| hub.luau | 删除启动时 installSilentAimHooks + 删除 Shoot hook |
| hub.luau | setSilentAimEnabled: 开→挂 CombatOriginFn, 关→hookfunction 还原 |
| hub.luau | isShootContext 替代 inShoot 窗口 |

### 决策记录
- 根因: v0.1.2 脚本加载即 hook Shoot+CombatOriginFn, 即使 Toggle 关也拦截射击链路
- 关闭功能 = 零 hook, 与原版行为一致

### 验证
- 待注入实测: 默认关 → 可射击; 开启 → 可射击 + 锁敌

---

## [2026-09-01 | 会话3 | v0.1.2 | lib v1.7.4] 仍无法射击 — 移除射线 hook + inShoot 窗口

### 目标
v0.1.1 仍反馈开静默瞄准无法开枪; 控制台有 origAsyncRaycast nil。

### 改动明细
| 文件 | 改动 |
|---|---|
| hub.luau | 删除 AsyncRaycast/RaycastUtils Swap |
| hub.luau | 新增 inShoot: ClientShootableComponent.Shoot 同步执行期间才改 CombatOriginFn |
| hub.luau | hook ClientShootableComponent.Shoot + CombatOriginFn 两处 |

### 决策记录
- LookVector 在 Shoot 同步期从 CombatOriginFn 捕获进闭包, 异步 InvokeAction 沿用同一向量, 不必 hook 射线
- 探测脚本曾覆盖 CSC.Shoot 为 nil 返回 — 若仍无法射击需重进对局刷新 module

### 验证
- 待用户重进 FFA 后实测

---

## [2026-09-01 | 会话2 | v0.1.1 | lib v1.7.4] 修复开启静默瞄准后无法开枪

### 目标
用户反馈开启功能后无法射击; 定位根因并 PATCH 修复。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | isShootCall() | 新增: debug.info 栈检测, 仅 Shoot/OnLocalShooted 内改方向 |
| hub.luau | redirectCFrame/redirectDirection | 移除 isFiring 判定, 改用 isShootCall |
| hub.luau | installSilentAimHooks | _G.RCWTK_SNIPER_SA 重复注入前先 restore; hook 体 pcall 包裹 |

### 决策记录
- 根因: CombatOriginFn 也被 MeleeableComponent.spawnMark 等复用; enabled+按住左键时误改 CFrame 导致射击链路 nil 调用
- 不用全删 CombatOriginFn hook: Shoot 发包仍依赖该单例取 LookVector, 收窄调用栈即可

### 验证
- 待用户进 FFA 实测: 开启静默瞄准后仍可正常开枪

### 遗留问题 / 下一步
- [ ] FFA 实弹验证静默命中

---

## [2026-09-01 | 会话1 | v0.1.0 | lib v1.7.4] 建档 + 静默瞄准首版

### 目标
新游戏 [🔥UPD] Sniper Arena (universe 9534705677) 建档; 实现首个 UI Tab「暴力」功能: 静默瞄准。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/sniper-arena/intel.md | 全文件 | 新建档案: Shoot 流程 / CombatOriginFn 单例 / 射线链 |
| games/sniper-arena/hub.luau | installSilentAimHooks | hookfunction CombatOriginFn + Swap AsyncRaycast/RaycastUtils |
| games/sniper-arena/hub.luau | findBestTarget | 360° 遍历玩家, Head 优先, workspace:Raycast 可见性 |
| games/sniper-arena/hub.luau | 暴力 Tab | Toggle 静默瞄准 + Paragraph 状态 |

### 决策记录
- 选 CombatOriginFn 单例 hook 而非改 Camera.CFrame: Shoot 发包与 AsyncRaycast 共用 LookVector, 单点修改覆盖服务端方向
- 360° 无 FOV 限制: 按距离最近 + 视线 unobstructed 选人, 符合用户需求
- 仅 MouseButton1 / 手柄 R2 视为「开枪中」, 避免非射击 Raycast 被误改
- L2 登记: hookfunction 挂游戏自身 CameraController 闭包, Destroy 时 hookfunction 还原

### 验证
- Potassium 客户端 placeId=119259569670784 pv154 逆向: decompile ClientShootableComponent / AsyncRaycast / RaycastUtils 确认参数
- CombatOriginFn 两次 GetCombatOriginFn() 引用相同 (true) 已实测
- 实弹 FFA 对局内命中验证: **未做** (当前在大厅 place)

### 遗留问题 / 下一步
- [ ] 进 FFA 对局实测静默瞄准命中与服务端接受情况
- [ ] 若服务端独立校验相机与发包夹角, 可能需要额外 hook GetSpreadedDirection 或 InvokeAction 序列化
- [ ] 补 dump-anticheat-hooks 结论进 intel

---

## 踩坑黑名单 (跨会话累积, 只增不删)

- [Rayfield Toggle/Button 点击 Tween 行 Size] → [一点开关就原生崩, 与存档无关] → [theking 截掉原点击, 无动画 overlay + defer 回调]
- [暴力页 Toggle 带 Flag (teamCheck/silentAimDrawFov/saAutoTrigger)] → [点开即时 autoSave 原生崩] → [暴力开关一律无 Flag, 回调只写布尔]
- [启动即 Drawing.new + 范围绘制默认开/Flag 读档] → [没开静默也有圈, 开关崩] → [两开关都开才延迟建圈; 渲染循环禁止 new]
- [Rayfield Toggle Flag=silentAim 点开 autoSave + 同帧全身 GetDescendants 选人] → [开静默原生崩溃] → [无 Flag, 延迟写文件; 0.55s 后再扫描; 进圈只用瞄准部位]
- [CombatOriginFn 在 ClientShootableComponent require 时即捕获] → [只 hook GetCombatOriginFn 无效] → [直接 hookfunction 单例闭包本身, 引用共享]
- [静默瞄准用 isFiring  gate CombatOriginFn] → [开启后无法开枪/近战报错] → [仅 Shoot/OnLocalShooted 调用栈内才改方向 (debug.info)]
- [脚本加载即 hook Shoot+CombatOriginFn] → [功能关闭也无法射击] → [lazy hook: 仅 Toggle 开启时挂 CombatOriginFn, 不 hook Shoot]
- [CombatOriginFn hook 只 return 一个值 / 内部 Raycast] → [开静默瞄准枪不能射、刀正常] → [Shoot 预扫描 + table.pack 多返回值 + inShoot 替换]
- [自动扳机 mouse1click 开功能当下就点] → [开关被点回去立刻关闭] → [开启后延迟 + 鼠标在 HUB 上禁止点击]
- [静默瞄准只测 Head + onScreen + 视线 Raycast] → [身体在圈内仍不锁] → [多部位进圈即锁, 不强制视线]
- [FOV 白圈用 Drawing.new Circle + 销毁时仍 RenderStepped 写属性] → [使用中/热替换闪退] → [ScreenGui UIStroke 画圈, 先断连再 Destroy]
- [范围绘制 Heartbeat 里 findBestTarget] → [开静默瞄准原生崩溃] → [心跳只画缓存部位; 选人用延迟低频循环]
- [关范围绘制时同步 Disconnect/改 Visible] → [点击关闭崩溃] → [开关只改标志, 延迟停心跳, 不碰子控件 Visible]
- [白圈 ScreenGui 内塞 Frame 线/十字并改 Rotation] → [开关范围绘制崩溃] → [白圈单独一层; 线/十字用 Drawing]
- [Rayfield Toggle 带 Flag/Notify/StartLoop] → [队伍检测/静默/绘制开关崩] → [Callback 只写布尔; 循环启动时挂上]
- [ScreenGui 心跳改 Size 跟开关] → [开静默/关绘制崩] → [Drawing 圈 + 渲染循环; 藏圈挪出屏幕不改 Visible]
- [整棵跳过 Highlight + Character~=模型当尸体] → [只锁大厅、对局锁不到] → [锁 Highlight.Enemy 持枪/刀模型; 对局外观不要当尸体]
- [露出判定无命中当可见 + Default 射线] → [锁墙后的人 / 被屏障误挡] → [可视化用 TeamXAtk, 必须打到目标 CanQuery 部位]
