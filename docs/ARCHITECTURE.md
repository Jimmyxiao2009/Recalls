# 架构说明

## 运行时关系

```text
Main / Bootstrap
├─ SceneRouter ─────────────── route_changed
├─ AppState ────────────────── save/load + progress + flags
├─ PackLoader ──────────────── res://packs/**/*.json
├─ MemorySystem ────────────── unlock + view definitions
├─ StoryPlayer ─────────────── node + choice + commands
├─ CeremonyBus ──────────────── phenomenon steps / channels
├─ RitualSystem ─────────────── conditions → actions
└─ RulePatchSystem ──────────── temporary rule changes
```

页面只负责把数据渲染成可交互组件：

```text
HubView → GateView → WorkbenchView → StoryView → HubView
   └────────────────── MemoryView ←───────┘
```

## Data Pack Loader

`godot/scripts/pack/data_pack_loader.gd` 扫描 `res://packs` 下的每个目录。每个目录的 `manifest.json` 是包身份；标准 section 会扫描各自目录中的 JSON 文件并按 `id` 建索引。

引擎公开以下内容访问接口：

- `get_hub()`
- `get_gate_list()`
- `find("scenarios", scenario_id)`
- `find("stories", story_id)`
- `find("memories", memory_id)`
- `get_all("phenomena")` / `get_all("rituals")`

JSON 文件可以是单条对象、对象的 `items` 数组或直接数组，方便小包和大包采用相同加载器。

## 状态与持久化

`AppState` 维护：

- 当前 scenario 与 progress
- scenario flags
- 已解锁 gates
- 已获得 memories
- 已访问 routes

默认状态保存在内存，退出时写入 `user://history_narrative_save.json`。Demo 的重新进入工作台会从 0% 开始，便于反复验证阈值演出；已解锁 Memory 会保留。

## Workbench 状态机

scenario 数据定义 `modules[].status_rules` 和 `progress_events[]`。Workbench 每次推进时间时：

1. 计算下一进度。
2. 找出刚跨过的阈值。
3. 应用对应 `RulePatch`。
4. 通过 `CeremonyBus` 播放 phenomenon。
5. 刷新模块按钮、地图色调、状态日志和最终入口。

模块支持 `active`、`warning`、`disabled`、`locked` 等状态。引擎不判断模块名称，因此同一套 Workbench 可用于别的朝代或事件。

## Story / VN 命令

`StoryPlayer` 支持：

- `show` / `hide`
- `fade`
- `flash`
- `shake`
- `wait`
- `text_flash`
- `phenomenon`
- `award_memory`
- `set_progress`
- `set_flag`
- `rule_patch`
- `jump`
- `end`

节点可以定义 `next` 或 `choices[]`。选项只改变当前故事的下一节点，不把具体历史内容硬编码到脚本中。

## Ceremony / Phenomenon

`CeremonyBus` 是演出调度器而不是单一 Shader。每个 phenomenon 有 `steps[]`，每一步拥有 `channel`、`effect`、`strength`、`duration`。当前 Overlay 已实现：

- scene overlay：闪白、噪声、暗角、色差
- text：侵入式文字
- camera：震屏信号，由 Main 驱动页面容器
- ui：模块熄灭事件信号
- shader / audio：统一接口，后续接真实 CanvasItem shader 和音效

因此将来可以让同一阈值事件同时改变画面、UI、镜头、音频和规则。

## UI 层级与参考图映射

- Layer 0：生成的地图底图 + 地图色调
- Layer 1：`MapOverlay` 直接绘制城门、单位、战线和任务点
- Layer 2：Workbench 的 TopBar、MainTabs、LeftPanel、RightPanel、BottomCommandBar、TimeControl
- Layer 3：`PhenomenonOverlay` 与 `StoryView` 的剧情 / Ceremony 覆盖

视觉样式统一由 `ThemeFactory` 提供，页面不散落创建随机颜色。当前的 UI 边界使用暗褐实体面板与铜金边框，地图和固定 UI 保持亮度与层级分离。
