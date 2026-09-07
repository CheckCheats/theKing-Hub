# theKing Obfuscator 开发手册

> 接手 AI: 读本文件再动 `tools/obfuscate.py`。原则 = **可用优先, 门禁不过不默认开**。

---

## [2026-09-01 | v1.4-safe 自迭代]

### 背景
- v1.5 (字符串表 + 谓词织入 + 二次封装 + CFF) 实机 UI 后炸 `nil < string`, 已回退 v1.3。
- 用户要求: 继续升级混淆, 但必须可用。

### 默认增量 (相对 v1.3)
1. 解密器: 特征表 XOR 掩码 + 战败日 `bit32.bxor` 隐藏
2. 每串 key 写不透明整数
3. 长串 >40 可分 3 段
4. 垃圾码实调用一次 `do local _=fn(0) end`
5. 水印 surrender 亦隐藏

### 刻意默认关
rename / virtualize / 字符串表 / 谓词织入 / wrap / CFF

### 门禁结果
- `--selftest` 全过
- 实机 Potassium: HF hub-single → Obf v1.4 产物 `compile true` + `exec true`, 启动行 `重型钓鱼@0.30.4` / lib v1.7.4, 授权通过; 延迟观察无 `nil < string`

### 下次迭代建议
1. 虚表仅对 `GetService/FireServer/InvokeServer` 白名单, 单独实机门禁后再谈默认开
2. rename 先用微型夹具覆盖嵌套函数/类型注解, 再上 hub
3. 勿一次叠多种高风险变换 (v1.5 教训)
