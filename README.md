# 忘川历史叙事引擎

一个 Godot 4.x 的历史叙事引擎第一版垂直切片。它不是战斗 RPG，也不是普通视觉小说模板，而是用“历史工作台 + VN + Memory + 异象规则”验证一条可扩展内容链路。

当前 demo 使用 `demo_chongzhen` 内容包，场景从“忘川”进入“世界之门”，再进入以中央战略地图为主角的“终局前夕”工作台。点击底部“推进时间”会提升史实还原度；每次达到阈值，机构和功能按钮会变暗、熄灭或锁定，并触发 Ceremony。进度达到 100% 后只留下“遗诏”和“自缢”，进入剧情模式并获得 `煤山前夜` Memory，返回 Hub 后即可看到它。

## 运行

需要 Godot 4.x。项目已按 1280×720 基准布局，也支持窗口缩放。

```text
godot --path H:/Recalls
```

也可以在 Godot Project Manager 中导入本目录并运行 `project.godot`。

键盘快捷键：

- `Enter`：Hub 进入世界之门
- `M`：打开 Memory
- `Esc`：返回 Hub

## 目录

```text
project.godot
packs/
  core/
  demo_chongzhen/
    manifest.json
    hub.json
    gates/
    scenarios/
    stories/
    memories/
    phenomena/
    rituals/
godot/
  scenes/app/Main.tscn
  scripts/core/        # Bootstrap、状态、路由
  scripts/pack/        # Data Pack Loader
  scripts/systems/     # Memory、Story、Ceremony、Ritual、Rule Patch
  scripts/ui/          # 页面、主题、地图和 Overlay
assets/generated/      # 图像模型生成的项目素材
docs/                  # 架构、素材和后续计划
```

## 引擎层与内容层

引擎只认识 `manifest`、集合 section、状态和命令类型，不知道“崇祯”这个词。历史人物、日期、模块、进度阈值、演出步骤、剧情节点和 Memory 都位于 `packs/demo_chongzhen/`，后续可以复制目录创建新的内容包。

## 当前完成度

- [x] Godot 4 工程与主场景
- [x] Pack Loader：manifest、gates、scenarios、stories、memories、phenomena、rituals
- [x] Hub / Gate / Workbench / Story / Memory 页面
- [x] 中央地图主视觉、两侧实体面板、顶部资源栏、底部命令栏、推进时间控件
- [x] 进度阈值驱动的模块状态与规则补丁
- [x] Ceremony 总线：UI、camera、shader、scene overlay、text、audio 通道接口
- [x] 闪白、噪声、暗角、色差、震屏、文字侵入等第一版演出
- [x] Demo 闭环：Hub → Gate → Workbench → Story → Memory → Hub
- [x] Ritual 监听与 Rule Patch 骨架
- [x] 用户参考图导向的 Superdesign 视觉基线
- [x] 图像模型生成的战略地图、Hub 背景、VN 背景、人物占位素材

## 设计参考

视觉基线已同步到 [Superdesign 画布](https://superdesign.dev/teams/2a786f92-dde2-44dd-b17c-8f6c94277721/projects/b916acb8-4733-4601-8ab3-39faf15d4d19)，并以用户提供的高保真参考图为最高优先级：中央地图占主角，左右栏为连续实体管理系统，顶部和底部形成策略游戏外框，剧情与异象作为独立 Layer 3 覆盖。
