# 素材规划

## 已生成并接入

| 文件 | 用途 | 生成策略 |
|---|---|---|
| `assets/generated/chongzhen_workbench_map.png` | 中央 2.5D 北京 / 宫城战略地图 | 参考用户提供的策略游戏构图，生成无文字地图底图 |
| `assets/generated/hub_background.png` | 忘川 Hub 背景 | 黑水、雾山、铜金世界之门、低密度记忆光点 |
| `assets/generated/vn_palace_background.png` | VN 剧情背景 | 明末宫殿书房、窗外火光、下方留对白空间 |
| `assets/generated/portrait_chongzhen_placeholder.png` | VN 人物占位 | 虚构晚明帝王胸像，暗褐铜金统一光色 |

## 规划中的插槽

- `gate_thumbnail`：世界之门缩略图，可复用地图局部或单独生成。
- `portrait_companion`：陪伴角色 / 史料记录者。
- `ui_copper_frame`：九宫格铜制边框，适合 `PanelContainer`。
- `ui_seal`：印章、朝代纹样、角部装饰。
- `overlay_noise`：Ceremony 噪声与纸张纹理。
- `overlay_light`：闪白、火光和尘埃层。

## 接入约定

素材由 pack 用稳定的 `res://assets/generated/...` 路径引用；页面从 `scenario.map_asset`、`story.background_asset`、`story.portrait_asset` 读取。没有素材时，`BackgroundCanvas`、`MapOverlay` 和主题边框仍可维持完整运行，方便先开发内容和规则。
