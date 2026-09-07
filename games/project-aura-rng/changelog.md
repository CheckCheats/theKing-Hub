# Project Aura RNG TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

```
版本号语义 (ScriptVersion, 写在 hub.luau 头部注释块):
  MAJOR  主版本   — 重构 / UI库或通信层更换 / 功能体系重做 (破坏性)
  MINOR  次版本   — 新增功能 / 显著增强现有功能
  PATCH  修订号   — bug修复 / 参数微调 / 文案修正 (不改变功能面)
```

---

## v0.2.0 [2026-09-07 | pv6760]

### Added
- 主要 Tab: 自动领取索引 / 自动装备最佳 / 自动升级
### 逆向依据
- intel.md [2026-09-07 | pv6760 | hub v0.2.0] createClient.fire + ClientUser.index/upgrades

---

## v0.1.0 [2026-09-07 | pv6760]

- 初始骨架: 主功能 / 传送 / 设置三 Tab
- 基于 hub-skeleton.luau 生成; 尚无玩法循环, 等待需求
