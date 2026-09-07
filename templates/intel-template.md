---
game: "<游戏显示名>"
placeId: 0
universeId: 0
placeVersion: 0
created: YYYY-MM-DD
updated: YYYY-MM-DD
script: "games/<game-dir>/hub.luau"
status: active # active | stale | archived
---

# 游戏情报档案 — <游戏名>

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 条目格式示例

```
## [2026-08-25 14:30 | pv5231 | sol-rng-fishing@2.0.0]
- ByteNetReliable 是唯一 Reliable RemoteEvent
- 包格式: [u8 packetId][payload], 一帧可含多包连续排列
- string 编码 = u16 长度 + 字节; bool/u8 = 1字节; f32/f64 标准 IEEE754
```

---

## 协议与通信

<!-- ByteNet / RemoteEvent / RemoteFunction 的编码格式、packetId 获取方式 -->

## Remote 清单

<!-- remote 名 | 路径 | 类型 | 参数格式 | 触发动作 | 服务端是否校验 -->

## NPC / 地点坐标

<!-- 名称 | CFrame 或模型路径 -->

## 关键机制结论

<!-- 客户端权威点、判定时机、冷却/概率机制、反作弊行为 -->

## L2 手段登记 (危险功能对抗手段台账)

<!-- 每条: [日期 | pv<N> | 功能名]
- 手段: hook 抢发包/模拟输入/...
- 目标: 函数或 remote 路径
- 验证: 小号实测时长 + 无 kick/回滚/弹窗
- 信号特征: 出问题时服务器如何反应 (供封禁预警)
-->

## 可复用代码片段

<!-- 已验证的 send/listen/buffer 片段, 注明依赖条件 -->

## 待复核 (placeVersion 变更后移入)

## 已证伪
