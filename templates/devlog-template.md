# <游戏名> TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

## 条目格式 (复制使用)

```
## [YYYY-MM-DD | 会话N | vX.Y.Z | lib v1.2.0] <一句话主题>

### 目标
本轮想达成什么 (1-3 行)

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | autoSellFish() L120-150 | 新增: ... |
| lib/theking.luau | StartLoop | 修改: ... |

### 决策记录 (为什么这么改)
- 方案A被否原因 / 选择方案B的理由 / 关键权衡

### 验证
- 怎么测的 (record-session/watch-value/手动), 结果如何

### 遗留问题 / 下一步
- [ ] 具体待办, 写清复现条件和线索
```

---

<!-- 实际条目追加在这条线之下, 最新的在最上面 -->

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

<!-- 示例:
- [WindUI Slider 用 Value=50 平铺传参] → [滑条不显示] → [必须 Value={Min,Max,Default} 子表]
- [hook 游戏函数后未恢复] → [重进游戏判定异常] → [用完必 restore, 挂前探测 checkhooked]
- [主块平铺 local / local function 爆 200] → [注入编不过] → [IIFE + TheKing.Pack 单表, check_hub.py]
- [Drawing.new 画 ESP] → [Potassium 隐形/崩] → [TheKing.Draw]
-->

