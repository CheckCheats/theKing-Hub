# TheKing.Draw — 2D / 3D 绘制

写透视、范围圈、锁定脚底、世界标签前读本文。禁止凭记忆猜参数, 禁止 `Drawing.new`。

## 为什么不用 Drawing API

开源脚本普遍走 `Drawing.new("Line"|"Text"|"Quad"|...)`。本引擎实测: **Potassium 上 Drawing 经常完全隐形, 并疑似拖崩客户端**。地下城战利品者 v1.0.2 起已全部改原生 ScreenGui。引擎绘制层沿用这条路, 热替换/卸载走 `Destroy` 自动拆层。

## 2D (每帧对象池)

必须夹在 `begin` / `finish` 之间, 或交给 `onPaint` (内部已夹好)。

```lua
TheKing.Draw.onPaint(function()
    local x, y, on = TheKing.Draw.worldToScreen(part.Position)
    if on then
        TheKing.Draw.dot(x, y, 8, Color3.new(1, 0.3, 0.3), 0.2)
        TheKing.Draw.text(x, y - 18, "目标", { Size = 14, Color = Color3.new(1, 1, 1) })
        TheKing.Draw.rect(x - 20, y - 20, 40, 40, Color3.new(1, 1, 1), 0.85)
        TheKing.Draw.line(x, y, x + 40, y + 40, Color3.new(1, 1, 0), 2, 0.2)
        TheKing.Draw.ring(hrp.Position, 12, Color3.new(1, 0.2, 0.2), 0.35, { yOff = -2.2 })
        TheKing.Draw.modelBox(model, Color3.fromRGB(255, 200, 40), 0.25)
    end
end)
```

| 方法 | 参数 |
|---|---|
| `begin` / `finish` | 手动开帧时用; 漏 `finish` 会留下上一帧多余图形 |
| `line(x1,y1,x2,y2, color, thickness, trans)` | 旋转 Frame 模拟线段 |
| `rect(x,y,w,h, color, trans)` | 轴对齐矩形 |
| `dot(x,y, size, color, trans)` | 圆点 (UICorner) |
| `text(x,y, str, opts)` | opts: `Size` `Color` `Transparency` `Center`(默认居中) |
| `worldToScreen(pos)` | 返回 `x, y, visible, depth` (Viewport, 与 IgnoreGuiInset 对齐) |
| `ring(center, radius, color, trans, opts)` | 世界水平圆投影成折线。opts: `yOff` `minScr` `segPx` `maxSegs` `thickness` |
| `modelBox(model, color, trans)` | 包围盒 12 条棱投影 |
| `onPaint(fn)` | RenderStepped; 传 `nil` 断开。已 `AddConnection` |
| `destroy` | 拆 GUI/3D/连接; Destroy/热替换自动调 |

`trans` = BackgroundTransparency, **0 不透明, 1 全透明**。

## 3D (带 key 的持久实例, 不要每帧 Instance.new)

```lua
TheKing.Draw.disc("lock", enemyHrp, 2.8, Color3.fromRGB(255, 70, 70), 0.35, -2.45)
TheKing.Draw.box("chest", part, part.Size, Color3.fromRGB(255, 200, 40), 0.5)
TheKing.Draw.sphere("aoe", hrp, 8, Color3.new(1, 0, 0), 0.7)
TheKing.Draw.highlight("esp", model, Color3.fromRGB(255, 200, 40), Color3.new(1, 1, 1), 0.65, 0.2)
TheKing.Draw.billboard("name", hrp, "宝箱", { Color = Color3.new(1, 0.85, 0.2), StudsY = 2.4 })
TheKing.Draw.hide("lock") -- 关掉某一件, 不销毁
```

| 方法 | 用途 |
|---|---|
| `disc(key, adornee, radius, color, trans, yOff)` | 脚底圈 (CylinderHandleAdornment, AlwaysOnTop) |
| `box` / `sphere` | 盒/球装饰, adornee 为 BasePart 或 Model(取 PrimaryPart) |
| `highlight` | 穿墙高亮, Parent 到实例上 |
| `billboard` | 头上字, opts: `Width` `Height` `StudsY` `Color` |
| `hide(key)` | 隐藏该 key |

同一 `key` 复用实例, 换目标只改 Adornee。脚底圈跟锁定目标: 每帧 `disc("lock", tgt.hrp, ...)` 即可, 不要 2D 折线硬跟 (会 10Hz 卡顿)。

## 性能

- 2D 池化, 禁止每帧 `Instance.new` 再 `Destroy`
- 世界圆优先 `disc` (3D 贴脚); `ring` 只在必须投影到屏幕时用, `maxSegs` 不要盲目加大
- 绘制回调里禁止 `GetDescendants` / 全图扫; 列表在外缓存

## 与业务脚本分工

地下城战利品者仍有一份历史 Overlay (功能已验证)。**新游戏和新功能必须走 `TheKing.Draw`**, 不要再复制一份对象池。
