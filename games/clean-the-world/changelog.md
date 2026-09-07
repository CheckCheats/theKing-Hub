# Clean the WORLD! TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

```
版本号语义 (ScriptVersion, 写在 hub.luau 头部注释块):
  MAJOR  主版本   — 重构 / UI库或通信层更换 / 功能体系重做 (破坏性)
  MINOR  次版本   — 新增功能 / 显著增强现有功能
  PATCH  修订号   — bug修复 / 参数微调 / 文案修正 (不改变功能面)
```

---

## v0.5.0 [2026-09-03]
- chore: 版本号重置为 v0.5.0 (对外重新编号, 功能不变)

## v1.0.1 [2026-09-03]

### Changed
- PATCH: 跟随 lib v2.0.3 黑金主题发布 (Logo 呼吸 / 切 Tab 淡入 / 侧栏白字)。玩法不变。

## v1.0.0 [2026-09-03]

### Changed
- MAJOR: 界面迁 Rayfield Gen2 (lib v2.0.0), 小图标统一品牌方圆标。玩法不变。

## v0.5.3 [2026-09-01 | pv761]

### Changed
- 接 lib 1.8.0: 技能/花钱退避走 TheKing.Backoff; 商店开关 BindToggle; Remote 走 FindRemote/WaitChild

## v0.5.2 [2026-09-01 | pv761]

### Changed
- 自动升级技能: 缓存技能快照, 热路径不再 WaitForChild; 每轮最多买 1 个; 无可买时约 10s 不再拉 GetSkillUpgrades
- 花钱: UI 显示 MAX/已满不再 Get; 全满约 12s 歇一轮, 有未满但买不起约 6s 歇一轮

## v0.5.1 [2026-09-01 | pv761]

### Removed
- 去掉「大海垃圾清洗」(不好用, 回退)

## v0.5.0 [2026-09-01 | pv761]

### Added
- 主功能「大海垃圾清洗」: 满桶立刻倒袋, 场上垃圾袋送风扇兑现 (不等 4 秒摇桶)

## v0.4.1 [2026-09-01 | pv761]

### Changed
- 自动清扫: 临时关入桶动画后同步扔 (不再等 0.55s 弧线); 新垃圾 ChildAdded 立刻扫; 桶满跳过; 默认每轮 16

## v0.4.0 [2026-09-01 | pv761]

### Added
- 花钱 Tab: 自动购买污染 / 升级 / 建造 (列表未满才买, 满级跳过, 新条目出现再买)

## v0.3.0 [2026-09-01 | pv761]

### Added
- 技能树 Tab: 自动升级 (口香糖够且前置已点就买; 不买 Robux/声望)

### Changed
- 主功能去掉「清扫状态」; 自动清扫开关排第一

## v0.2.1 [2026-09-01 | pv761]

### Changed
- 去掉空的「传送」Tab (尚无点位)

## v0.2.0 [2026-09-01 | pv761]

### Added
- **自动清扫**: 复用游戏 `throwPaperToTrash` 清 `DropArea` 上的纸/粪/蕉/蛋, 不限鼠标圈; 可调每轮数量 (1~15)

### 逆向依据
- intel.md 2026-09-01: CollectPaper + collectPapersNearMouse / throwPaperToTrash upvalue 绑定

<!-- 新版本条目追加在这条线之上 -->

## v0.1.0 [2026-09-01 | pv761]

- 初始骨架: 主功能 / 传送 / 设置三 Tab
- 基于 hub-skeleton.luau 生成

<!-- 新版本条目追加在这条线之上, 格式:
## vX.Y.Z [日期 | pv<N>]
### Added / Fixed / Changed
- 变更点 (一行一条, 写清动了哪个功能)
### 逆向依据 (如有)
- 引用 intel.md 的相关结论条目日期
-->
