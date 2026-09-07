# Fisch TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

## [2026-08-25 | 会话1 | v0.0.0 | lib 未接入] 首次建档 + 反作弊侦察

### 目标
建立 Fisch 游戏档案, 侦察反作弊对抗面, 摸清游戏结构。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| games/fisch/intel.md | 全文 | 新建: front matter + 反作弊结论 |
| games/fisch/changelog.md | 全文 | 新建 |

### 决策记录 (为什么这么改)
- 首次会话客户端在 build-script-index + 全树遍历并发时崩溃 → 定下"重操作串行"纪律, 已写入 intel.md「环境稳定性」。

### 验证
- dump-anticheat-hooks scanConnections=true: 元表全 C closure, 无注入监听 — 无主动反作弊。

### 遗留问题 / 下一步
- [ ] 结构探索未完成: ReplicatedStorage 拓扑 / remote 清单 / 核心钓鱼模块
- [ ] script-index 未建成 (崩溃中断), 需单独重建且期间不跑其他重工具

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [build-script-index 与 get-descendants-tree 并发执行] → [Fisch 客户端直接崩溃掉线] → [重操作严格串行; 探索期用 search-instances 分片查询代替全树遍历]
