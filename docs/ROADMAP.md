# 后续开发建议

## P1

1. 把 `ThemeFactory` 提取为 Godot `.tres` Theme，并增加 Noto Serif CJK 字体资源。
2. 为 `MapOverlay` 增加可点击城门、单位、战线和摄像机平移缩放。
3. 把 `CeremonyOverlay` 的噪声、色差、去饱和改为真实 CanvasItem Shader 参数。
4. 为 Gate 增加通用条件求值器：Memory、flag、progress、前置事件。
5. 将 `TopBar`、`LeftPanel`、`RightPanel`、`BottomCommandBar` 拆成独立 `.tscn`，支持主题替换。
6. 将报告选项、陪伴角色反馈、底部命令说明全部收敛到 pack JSON。

## P2

1. 增加多包选择器与 pack 热加载调试面板。
2. 为 StoryPlayer 增加存档节点、回看、跳过已读和历史记录。
3. 预留 AI 人物对话接口：只允许读取当前 scenario、Memory 和可见关系状态。
4. 加入 Q 版陪伴角色占位与情绪 / 好感数据。
5. 让 Rule Patch 支持 `disable_target`、`reveal_target`、`capture_ui`、`change_time_step` 等类型组合。
6. 增加自动化 headless smoke test，验证每个 demo pack 都能完成最小闭环。

## 美术资产节奏

先确保 UI 框架与数据包能复用，再逐步替换：地图底图 → 事件插图 → Hub 背景 → VN 背景 → 人物立绘 → UI 装饰与 Shader 贴图。所有素材都应通过稳定 asset slot 接入，不让脚本依赖随机文件名。
