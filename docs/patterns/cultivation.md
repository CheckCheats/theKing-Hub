---
genre: cultivation
games: ["cultivation-evermortal"]
updated: 2026-09-07
---

# 修仙 / 聚气突破类 游戏套路库

> 从**同类型 ≥2 个游戏**的 intel.md / devlog.md 提炼的可泛化经验。
> 当前只有 Cultivation: Evermortal 一档, 下面先记「进同类游戏第一步看什么」。单游戏细节留 intel。

## 逆向套路 (进新游戏先跑这个流程)

- 商店页常见循环: 聚气 → 气满突破 → 功法加速聚气 → 抽天赋/灵根 → 宗门 → 飞升转世。先对照 UI 按钮再对 remote, 不要假设客户端改气量能过服。(来自 cultivation-evermortal 公开描述, 未局内验证)

建议钾顺序: `inspect.py howto 突破` → `probe ui` / `buttons` → `probe remotes` → 真人打一次坐/突破再 `listen`。

## 协议模式

- (待第 2 个同类游戏验证)

## 功能配方 (可复制的功能实现思路)

- (待局内验证后再写)

## 已知坑 (该类型跨游戏反复踩的)

- (尚无)

## 案例索引

- `games/cultivation-evermortal/` — Cultivation: Evermortal (pv1118 建档)
