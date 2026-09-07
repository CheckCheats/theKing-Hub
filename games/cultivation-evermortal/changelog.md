# Cultivation: Evermortal TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

```
版本号语义 (ScriptVersion, 写在 hub.luau 头部注释块):
  MAJOR  主版本   — 重构 / UI库或通信层更换 / 功能体系重做 (破坏性)
  MINOR  次版本   — 新增功能 / 显著增强现有功能
  PATCH  修订号   — bug修复 / 参数微调 / 文案修正 (不改变功能面)
```

---

## v0.3.0 [2026-09-07 | pv1118]

### Added
- 自动克服困难: 气够点突破球/渡劫
- 自动磨练肉体: 磨练钮亮且气够时点
- 自动升级技巧: 气够升级 CULTIVATE (跳过圆满/玉)
- 自动滚动天赋: 点 ROLL TALENT
- 装备最佳天赋: 已拥有里最稀有并装备
### 逆向依据
- intel 2026-09-07 BreakCluster / Techniques.Grid / Talents.Roll+Owned

## v0.2.0 [2026-09-07 | pv1118]

### Added
- 自动 Tab: 自动冥想 — 切到修炼页、点 MEDITATE、指针进金色芯点左键
### 逆向依据
- intel 2026-09-07 坐忘 QTE / Nav.Cultivate / Meditate.Hit.MouseButton1Down

## v0.1.0 [2026-09-07 | pv1118]

- 初始骨架: 主功能 / 传送 / 设置三 Tab
- 基于 hub-skeleton.luau 生成
- 尚无局内逆向结论, 功能开关均为占位
