---
genre: fishing
game: "Fisch"
placeId: 16732694052
universeId: 5750914919
placeVersion: 5177
created: 2026-08-25
updated: 2026-08-25
script: "games/fisch/hub.luau"
status: active
---

# 游戏情报档案 — Fisch (鱼 🌌 [星界])

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

---

## 协议与通信

<!-- ByteNet / RemoteEvent / RemoteFunction 的编码格式、packetId 获取方式 -->

## Remote 清单

<!-- remote 名 | 路径 | 类型 | 参数格式 | 触发动作 | 服务端是否校验 -->

## NPC / 地点坐标

<!-- 名称 | CFrame 或模型路径 -->

## 关键机制结论

## [2026-08-25 | pv5177 | dump-anticheat-hooks]
- 客户端层无主动反作弊: DataModel 元表 __index/__namecall/__newindex 全为原生 C closure,
  Heartbeat/Stepped/RenderStepped 无无源注入监听。只读分析与常规发包不触发检测面。

## 环境稳定性

## [2026-08-25 | pv5177 | 会话事故]
- 全量反编译 (build-script-index) 与全树遍历并发执行曾致客户端崩溃。
- 对策: 重操作严格串行; 结构探索用 search-instances 分片代替全树遍历; 索引构建期间不做其他重操作。

## L2 手段登记 (危险功能对抗手段台账)

<!-- 每条: [日期 | pv<N> | 功能名]
- 手段: hook 抢发包/模拟输入/...
- 目标: 函数或 remote 路径
- 验证: 小号实测时长 + 无 kick/回滚/弹窗
- 信号特征: 出问题时服务器如何反应 (供封禁预警)
-->

(空)

## 可复用代码片段

<!-- 已验证的 send/listen/buffer 片段, 注明依赖条件 -->

(空)

## 待复核 (placeVersion 变更后移入)

(空)

## 已证伪

(空)
