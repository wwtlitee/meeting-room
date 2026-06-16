# REPORT_专家团硬启动会议流程_v1.0.0

## 基本信息

- 日期：2026-05-27
- 负责人：Solazhu
- 范围：专家团 skill 触发流程、可视化会议 session、React viewer 会议产物展示、Codex 内置浏览器导航策略

## 本次目标

- 专家团触发后优先拉起 Codex 内置浏览器展示会议现场。
- Codex 聊天侧只输出必要流程状态、结论和可执行方案。
- 网页侧作为主要展示载体，承载会议过程、可实施方案、推荐员工子任务。
- 为后续“员工正在工作”的动画预留结构化字段。

## 已完成

- 新增 `scripts/start_expert_panel_meeting.ps1`，串联 session 生成、viewer 启动、Codex 内置浏览器打开三步硬流程。
- 硬编码 Codex 侧消息模板：开会中输出会议主题、参会人员、会议进行状态和裸 viewer URL；会后输出会议结论、实施方案与推荐员工。
- 强化 `scripts/open_inapp_browser_url.ps1`，支持通过页面特征文本判断“内置浏览器已在目标会议页”，避免误报失败。
- 修复旧会议页误判：确认范围收窄到右侧内置浏览器区域，且必须匹配本次会议主题，不能用左侧聊天文本冒充网页载入。
- React viewer 改为监听 `current-session.json`，有新 session 时直接走现有转场载入新会议，不依赖整页刷新。
- 中文议题下增加中文发言门禁：过滤英文/韩文资料原句，内部字段名转为中文表达，参会人员职位改为中文显示。
- 会议产物面板改为会后加载：逐字会议动画未结束前不渲染实施方案和推荐员工，避免未开会先出结果。
- 修复功能一发言机械化：删除固定九段式台词生成路径，改为按会议动作生成发言，并禁止角色资料原句直接进入台词。
- 新增自然发言规则文档 `references/NATURAL_MEETING_DIALOGUE_RULES.md`，记录活人感来自接话、补充、反对、修正和专业后果，而不是硬编码用户示例句。
- 会议生成器增加角色声音画像：按角色分工给出专业镜头，例如产品看承诺，工程看实现，测试看失败路径，设计看用户感知；该生成器后续仅作为 fallback / smoke test，不再作为正式功能一台词来源。
- 主持人开场改为正常开题和提出问题；专家发言改为第一人称判断、承接上一位、说明专业后果，不再上来直接抛方案。
- 修正二次模板化问题：正式功能一不再使用脚本预设赞同、反对、总结、抛观点等会议动作；每条发言只能根据已发生对话、当前角色专业/性格和真实议题约束生成。
- `scripts/start_expert_panel_meeting.ps1` 支持 `-UseCurrentSession` 和 `-SessionFile`，正式会议入口改为装载 authored session、启动 viewer、打开 Codex 内置浏览器。
- 更新 `SKILL.md` 和 `references/NATURAL_MEETING_DIALOGUE_RULES.md`，明确 `new_visual_meeting_session.ps1` 只是 fallback / smoke test，不是正式自然会议来源。
- 为 `E:\AI\deadman` 写入并载入非模板 authored session，参会角色来自真实专家名单：产品经理、心理学家、安全工程师、移动应用构建工程师、AI 工程师、UX 研究员、叙事设计师、模型 QA 专家。
- 扩展 `scripts/new_visual_meeting_session.ps1`，输出 `summary.implementationPlan`、`summary.recommendedWorkers`、`summary.futureAnimationIdea`。
- 扩展 React viewer，新增“会议产物 / 实施方案与推荐员工”展示区。
- 更新 `SKILL.md` 与 `references/VISUAL_TRANSCRIPT_SCHEMA.md`，把硬启动和结构化结论写入 skill 规范。

## 复核结果

- PowerShell 语法复核通过：`new_visual_meeting_session.ps1`、`start_expert_panel_meeting.ps1`、`open_inapp_browser_url.ps1`。
- React 构建通过：`npm run build`。
- 硬启动脚本复核通过：返回 `ok=true`，viewer 地址为 `http://127.0.0.1:5175/`，未触发默认浏览器兜底。
- 消息模板复核通过：输出 `codexStartMessage`、`codexFinalMessage`，且开会中模板包含裸 URL 行，可触发 Codex 网页预览卡。
- 新会议载入复核通过：第二次写入新 session 后，内置浏览器返回 `loaded the expected meeting in the existing viewer`。
- 中文发言复核通过：当前会议 9 条发言的英文字符数为 0。
- 会后产物逻辑复核通过：`MeetingOutcomePanel` 仅在 `playback.finished` 后挂载。
- 自然发言复核通过：机械开头句式检查无命中，同一角色二次发言不再复读第一段。
- 示例句防硬编码复核通过：用户给出的自然发言示例未作为固定台词写入生成结果。
- 讨论链复核通过：生成会议包含主持人追问，专家发言有同意、补充、反对和修正关系。
- 二次模板修正复核通过：`start_expert_panel_meeting.ps1` PowerShell parser 通过，`-UseCurrentSession` 返回 `ok=true`，且 `source=current_session`。
- `E:\AI\deadman` authored session 复核通过：JSON 可解析，participant_count=8，内置浏览器确认显示 `http://127.0.0.1:5175/` 本次会议。
- 当前 session 复核通过：实施方案 5 条，推荐员工 6 名，结论、下一步、后续动画字段均存在。
- 页面文本复核通过：可检测到“会议产物”“实施方案与推荐员工”“推荐员工子任务”“后续动画方向”。

## 风险与边界

- Codex 内置浏览器的 UIAutomation 地址栏控件可能因客户端版本变化而变化；当前已增加页面特征文本兜底。
- 默认浏览器只允许在显式参数 `-OpenDefaultBrowserAfterInAppFailure` 且内置浏览器失败时使用。
- 自然会议质量依赖 Codex 按规则手写 authored session；若后续误用 `-Topic` fallback，仍可能退化为脚本模板发言。
- skill 目录当前不是 Git 仓库，无法配置 `.git/info/exclude`；本地 `pdoc/` 仅作为本机经验文档目录保留。

## 建议下一步

- 把推荐员工子任务接入真实 worker 执行链，而不是只展示推荐名单。
- 设计“员工正在工作”动画的最小闭环：任务分配、工作中状态、产物回填、会议总结更新。
- 为硬启动脚本增加统一输出模板，便于 Codex 聊天侧稳定同步“正在开会 / 结论 / 子任务推荐”。
