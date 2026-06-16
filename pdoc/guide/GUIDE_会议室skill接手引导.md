# GUIDE_会议室skill接手引导

## 业务背景

会议室 skill 的核心不是“把会议演出来”，而是把复杂需求转化为“多人格专业讨论 + 独立记忆层 + 结构化结论 + 后续执行建议”的工作流。Codex 聊天侧是主流程载体，React viewer 只作为可选旁观界面；会后结论与后续执行建议始终回到聊天栏同步。 - v1.28.0

## 发布定位

- 第一价值：多人格讨论互不串味。每个角色都要守住自己的专业边界，不退化成同一个人在换名字说话。 - v1.28.0
- 第二价值：每个人格有自己的长期知识与短期记忆入口，讨论时能带着自己的经验进场，而不是共享一团全局上下文。 - v1.28.0
- 第三价值：讨论输出必须能落地到结论、方案、派工或待验证分歧，不能停留在热闹的角色扮演。 - v1.28.0
- 可视化会议只负责“看”，不负责“想”；真正的产品力在 `references/roles/*`、`references/personas/*` 和 live append runtime。 - v1.28.0

## 核心入口

- `SKILL.md`：会议室 skill 主入口与触发规则。 - v1.22.0
- `scripts/start_expert_panel_meeting.ps1`：准备文字会议所需的 live runtime，并在 viewer 可用时返回手动点击的可视化会议链接；不再自动拉起 viewer，也不再把 viewer 成功与否作为文字会议的前置门槛。 - v1.27.0
- `scripts/click_latest_meeting_link.ps1`：保留为开发/人工排障辅助脚本，不属于默认用户链路。 - v1.27.0
- `scripts/test_meeting_trigger_contract.ps1`：会议触发静态回归脚本，检查触发词、固定首句、禁止 deepseek 抢路由、文字主流程优先字段和全局废弃 skill 删除状态。 - v1.27.0
- `scripts/new_visual_meeting_session.ps1`：仅保留为开发 smoke test，不得进入用户侧 Function 1 会议链路。 - v1.19.0
- `runtime/initialize_live_meeting.ps1`：创建空 main-process live runtime，正式邀请人 + 氛围状态补满 10 席，默认 `discussion` 且关闭陪审 UI；显式陪审/PK/多轮投票才写入启用态 A/B 选项；氛围席铭牌仍取真实邀请角色，`ambientState` / `ambientLabel` 只表达状态。 - v1.30.0
- `runtime/set_live_meeting_thinking.ps1`：主进程选中下一位非主持 speaker 后的前端同步脚本；后台真实读取该人格资料和最新会议内容期间，viewer 通过 `runtime.pendingSpeaker` 显示该发言框省略号。不得用于主持人的固定控场、投票、结果或总结 turn。 - v1.25.1
- `runtime/append_live_meeting_turn.ps1`：主进程 live 的唯一提交脚本；主持固定控场直接 append，非主持发言生成完成后 append 并清空匹配的 `runtime.pendingSpeaker`；投票 turn 会补齐所有可见非主持席位并统一统计大屏票数。 - v1.26.0
- `runtime/import_text_meeting_result.ps1`：文字会议先在聊天中完成后，把 transcript 和精简结尾摘要一次性导入 `meeting-runtime.json`，供 viewer 回放；若本轮是陪审/方案 PK/多轮投票，必须同时传入 `-VoteRoundsJson(File)` 或 `-DeliberationJson(File)`，保留 A/B 标记、投票轮和动画。 - v1.31.0
- `runtime/run_live_meeting.ps1`：旧 authored session 转 live 的开发转换器，不得用于用户侧默认会议入口。 - v1.19.0
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：会议 viewer 主要 React 组件，包含 session 热加载、同一会议 id 增量 turn 续播、陪审团 A/B 信息、上一条/下一条播放控制、默认布局、陪审团投票手臂时序、牛牛部门人格表情映射、睡觉状态鼻涕泡、真实发言生成期省略号、逐步揭示会议记录、全可见席位投票统计和空闲降载状态；氛围状态不得追加铭牌状态牌。 - v1.26.0
- `assets/expert-meeting-viewer/react-viewer/src/styles.css`：会议 viewer 样式入口，包含陪审团大屏 A/B 主标签、说明行与票数布局、发言框思考省略号动画。 - v1.24.1
- `references/ROLE_NAME_ZH.md`：260 个导入人格的中文短职位名映射；必须保持 260 行、非空、展示宽度不超过 6 个单位，避免会议铭牌出现任务标签式名称。 - v1.23.0
- `references/VISUAL_TRANSCRIPT_SCHEMA.md`：会议 session JSON 字段约定。 - v1.0.0
- `pdoc/design/DESIGN_会议室skill流程收束_v1.1.0.md`：功能一/功能二、触发矩阵、反馈格式和状态机的收束设计。 - v1.22.0
- `pdoc/design/DESIGN_live_meeting_runtime_v1.0.0.md`：实时多人格子 agent 会议 runtime 第一版设计，定义主持人主进程、5/6/10 人约束、全员并发思考、排队发言和增量再思考。 - v1.0.0

## 功能边界

- 功能一：开会出方案。用于会议室讨论、评审、陪审模式、方案 PK、更新方向研究；输出会议结论、实施方案和推荐员工，但不自动执行子任务。 - v1.22.0
- 功能二：员工执行子任务。仅在用户明确说“开始分工执行 / 让员工去做 / 跑子任务”等执行意图后触发；输出真实产物、执行进度和阻塞项。 - v1.1.0
- 功能一触发后直接进入唯一会议入口，不再让用户选择会议类型；圆桌/普通会议旧链路已删除，功能一结束后仍必须再让用户选择执行方式，避免把“开会出方案”和“执行子任务”混在一起。 - v1.18.0
- 功能一以文字会议为主流程：会议页未确认打开时仍继续文字会议，只是不可宣称可视化会议已经就绪。 - v1.27.0
- 当前更推荐“文字先聊完，再导入 viewer”，而不是强行追求实时会议页同步。 - v1.29.0
- 任何会议室/会议 skill 触发后，用户可见第一句必须固定输出：`会议室 skill已触发～喵`，再进入唯一会议入口或启动流程；该句优先于项目级 `收到计划，开始执行～喵` 通用开场。 - v1.22.0
- 修改触发词、路由优先级、启动字段或 AGENTS 补充规则后，必须运行 `scripts/test_meeting_trigger_contract.ps1` 作为同步前回归。 - v1.11.0

## 触发与反馈

- 默认触发“会议室 / 开会 / 专家团 / 专家们 / 讨论一下”时，Codex 不再询问会议类型，直接进入唯一会议入口并默认走 `discussion` text-first live。 - v1.30.0
- 固定触发提示必须先输出，让用户明确知道 `meeting-room` / 会议室已命中；不得先说通用任务接收话术，也不得再追加旧的会议二选一提示。 - v1.22.0
- 进入唯一会议入口后，功能一选择真实员工、准备会议内容；若 viewer 校验通过，则先输出 `[打开可视化会议](currentBrowserUrl)` 手动链接，再在链接下方直接继续文字会议。 - v1.27.0
- 如果本轮会议直接在聊天中完成，允许在结尾通过 `import_text_meeting_result.ps1` 把本轮 transcript 与精简摘要导入 viewer，再输出“已导入本轮文字会议”的链接；陪审/PK 会议导入时必须带投票轮数据，不得降级成普通 discussion 回放。 - v1.31.0
- 默认 discussion live 是当前唯一用户入口：正式邀请人 + 氛围状态补满 10 席，主进程读取正式人格、可发言氛围状态和实时会议记录后逐条写入或会后导入 `meeting-runtime.json`；陪审团/A-B 只是显式投票类请求的内部机制。 - v1.30.0
- 氛围状态不是身份：`nod` 是“对对对”状态，`reserve` 是保留意见状态，`thinking` 是再想想状态，`zzz` 和 `phone` 是视觉状态；铭牌主文本必须始终显示真实邀请角色，状态不得追加状态牌，只能作为内部状态或动作反馈存在。 - v1.24.1
- 投票必须覆盖所有可见非主持席位：正式席位由主进程显式写入，氛围席按状态补齐；`nod` / 对对对跟随本轮正式票的明确多数，无明确多数则 `z`，`reserve` / `thinking` / `zzz` / `phone` 默认 `z`。大屏票数、座位按钮和铭牌投票边框必须从同一份补齐后的 votes 计算。 - v1.26.0
- 实时发言框在 speaker 思考阶段只显示姓名/职位和正文循环省略号；正文生成完成第一字后再开始逐字打字，避免用户误以为发言框空白或整段预写。 - v1.24.0
- 非主持、非固定话术发言必须走两段同步：先写入 `runtime.pendingSpeaker`，此时后台读取该 speaker 的人格信息和最新会议记录，会议页显示姓名/职位与循环省略号；生成完成后再追加 turn，会议页从省略号切换为逐字说话。主持人的开场、投票、轮次引导、结果公布和最终总结仍按固定 Q-flow 直接写入。 - v1.25.1
- 会议记录面板必须按播放进度逐步揭示，只显示当前 turn 及之前的内容；不得在 `1/N` 时显示后续发言、投票结果或最终结论。 - v1.25.2
- 默认 live runtime 必须保持 append-only 运行态：启动时 `turns=0`，测试用完整流程样本不得写入默认 `meeting-runtime.json` 冒充实时会议；空运行态顶部进度显示“等待写入”，不显示伪进度。 - v1.25.3
- 如果真实子 agent 拉起较慢，聊天侧允许先输出会前等待文案：`正在通知员工开会` 与 `<displayName> 已进入会议室`。这些提示必须和真实后台拉起事件一一对应；会议页前台仍保持旧版 authored 会议的简洁观感，不暴露子 agent 细节。 - v1.14.0
- `mode: "discussion"` 是默认数据模式；`mode: "jury_deliberation"` 仅在陪审、PK、多轮投票请求中启用，由 `deliberation.labelA/detailA`、`labelB/detailB` 和 `voteRounds` 驱动大屏 A/B 选项、票数和投票变化。 - v1.30.0
- Codex 开会中先同步：会议主题、参会人员、可点击可视化会议链接（若可用），随后直接展开文字会议；不得把生成、剧本、会议数据、`SCRIPT_*` 或内部 A/B 标记作为用户侧说明。 - v1.27.0
- 若 `servedSession.matches = false`，Codex 只是不输出可视化链接，文字会议仍继续。 - v1.27.0
- 若 `servedSession.matches = false`，表示端口服务的是旧会议或错误 skill root，必须换端口或阻塞，不能把旧页面当作本次会议。 - v1.9.0
- viewer 长期开启时必须进入空闲降载：会议结束、暂停或页面隐藏时关闭装饰 RAF/interval/无限 CSS 动画，并降低 session 轮询频率。 - v1.10.0
- viewer 空态现在应明确提示“等待文字会议导入”，并在完成导入后把综合方案、推荐任务、推荐角色放在底部短摘要区，而不是夹在中部。 - v1.29.0
- viewer 播放结束后，Codex 再同步：会议结论、实施方案、推荐员工。 - v1.1.0
- 会后推荐员工只是派工建议；Codex 需要继续询问：`1，直接主任务执行` / `2，拉起子 agent 分工执行`。 - v1.2.0

## 当前流程

1. 触发会议室会议。 - v1.22.0
2. Codex 第一可见句输出：`会议室 skill已触发～喵`，覆盖通用任务接收话术。 - v1.22.0
3. Codex 直接进入唯一会议入口，不询问普通/陪审团二选一。 - v1.16.0
4. 选择真实相关员工，读取稳定角色 prompt 与 persona store。 - v1.1.0
5. 默认 discussion live 先由 `initialize_live_meeting.ps1` 初始化空 `meeting-runtime.json`，`turns=0`；随后 Codex 主进程推进主持与自然讨论。轮到非主持角色发言时，先用 `set_live_meeting_thinking.ps1` 同步该 speaker 的真实生成期，再读取 `meeting-runtime.context.json` 和最新会议记录，最后通过 `append_live_meeting_turn.ps1` 追加发言；若文字会议已在聊天中完成，可改用 `import_text_meeting_result.ps1` 一次性导入。 - v1.30.0
6. `start_expert_panel_meeting.ps1` 启动/复用 viewer，并校验 viewer 服务的会议 `id` 与本次 session 或 runtime 一致；若 5175 被旧全局服务占用，应切到下一个可用端口。 - v1.15.0
7. `start_expert_panel_meeting.ps1` 默认只校验 viewer session 并返回手动点击的可视化会议链接；不得自动打开。若 `servedSession.matches = false`，直接跳过链接，文字会议继续。 - v1.27.0
8. React viewer 只承担旁观动画；文字会议本身在聊天中实时推进，若不走实时 append，则在聊天结束后导入 transcript 与精简摘要再回放。 - v1.29.0
9. 会后 Codex 同步结论、实施方案和推荐员工，并询问直接主任务执行或拉起子 agent 分工执行。 - v1.2.0

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-16 | v1.31.0 | 补充文字陪审/PK 导入保留 voteRounds/deliberation 的发布门禁 | Unclecow |
| 2026-06-15 | v1.30.0 | 默认会议回归 discussion/text-first，陪审团与 A/B 只保留为显式投票类机制 | Unclecow |
| 2026-06-15 | v1.29.0 | 新增文字会议结果导入 viewer 流程，并将 viewer 摘要收束到底部短摘要区 | Unclecow |
| 2026-06-14 | v1.28.0 | 补充发布定位，突出多人格专业边界、独立记忆层和可落地讨论结果 | Unclecow |
| 2026-06-14 | v1.27.0 | 收束为文字会议主流程，可视化会议降级为手动打开的可选旁观链接 | Unclecow |
| 2026-06-02 | v1.26.0 | 修复全可见席位投票统计，`nod` 跟随正式多数而非固定 B | Unclecow |
| 2026-06-02 | v1.25.3 | 隔离测试样本与默认 live runtime，并修复空运行态进度显示 | Unclecow |
| 2026-06-02 | v1.25.2 | 修复会议记录提前泄露未来 turn，避免会议中途显示最终结论 | Unclecow |
| 2026-06-02 | v1.25.1 | 限定 pendingSpeaker 只用于非主持发言，恢复主持固定 Q-flow 边界 | Unclecow |
| 2026-06-02 | v1.25.0 | 新增 pendingSpeaker 同步，发言生成期间前端显示真实省略号 | Unclecow |
| 2026-06-01 | v1.24.1 | 移除氛围状态牌，铭牌区域只显示真实邀请角色 | Unclecow |
| 2026-06-01 | v1.24.0 | 修正氛围铭牌身份语义，新增发言前思考省略号 | Unclecow |
| 2026-06-01 | v1.23.0 | 将 260 个角色中文展示名全量职位化，保留大屏短铭牌约束 | Unclecow |
| 2026-06-01 | v1.22.0 | skill 对外名称改为 meeting-room / 会议室，更新固定触发句与 viewer 左上角品牌 | Unclecow |
| 2026-06-01 | v1.21.0 | 校正氛围状态发言规则，`nod`、`reserve`、`thinking` 可作为氛围人格按需进入会议记录 | Unclecow |
| 2026-06-01 | v1.19.0 | 默认会议改为 main-process append-only live，删除用户侧预写 session 链路 | Unclecow |
| 2026-05-31 | v1.18.0 | 删除圆桌/普通会议旧链路，只保留轻度陪审团 live 会议形态 | Unclecow |
| 2026-05-31 | v1.17.0 | 修正唯一会议为轻度陪审团 live，恢复默认 A/B 大屏选项 | Unclecow |
| 2026-05-31 | v1.16.0 | 收束为单一会议入口，默认轻度 live；睡觉状态正式显示鼻涕泡 | Unclecow |
| 2026-05-31 | v1.15.0 | 普通会议默认接入 `meeting-runtime.json` 轻度 live runtime，viewer 支持同 id 增量续播 | Unclecow |
| 2026-05-29 | v1.13.1 | 将会议链接自动点击从可选改为输出文案后的强制步骤，失败才由用户手点 | Solazhu |
| 2026-05-29 | v1.13.0 | 删除旧侧栏/URL 输入自动化脚本，改为只点击最新可见的打开会议页链接 | Solazhu |
| 2026-05-29 | v1.12.0 | 收束会议打开方式为可点击链接主路径，停止默认 UIAutomation 自动拉起 | Solazhu |
| 2026-05-29 | v1.11.0 | 执行会议 skill 未触发根因会方案，新增触发合同静态回归脚本与规则文档 | Solazhu |
| 2026-05-29 | v1.10.0 | 增加 viewer 空闲降载规则，降低长期开启造成的卡顿风险 | Solazhu |
| 2026-05-29 | v1.9.0 | 增加 viewer 服务会议 id 校验与旧端口换端口规则，防止打开旧会议 | Solazhu |
| 2026-05-29 | v1.8.1 | 将固定触发提示提升为覆盖项目通用开场的优先规则 | Solazhu |
| 2026-05-29 | v1.8.0 | 新增专家团 skill 命中后的固定首句触发提示 | Solazhu |
| 2026-05-28 | v1.7.0 | 禁止 Function 1 会议兜底，会议页未确认打开时不再文字模拟会议或输出结论 | Solazhu |
| 2026-05-28 | v1.6.0 | 增加用户侧后台话术防泄露规则，并修复右侧浏览器侧栏收起时的自动展开与确认语义 | Solazhu |
| 2026-05-28 | v1.5.6 | 扩展牛牛表情库，并收束为部门人格映射，不再推进随机换座 | Solazhu |
| 2026-05-28 | v1.5.0 | 新增牛牛人格表情 variant 与角色气质映射 | Solazhu |
| 2026-05-28 | v1.4.0 | 固化 viewer 最新手调布局，并修正真实陪审团投票手臂收回时序 | Solazhu |
| 2026-05-28 | v1.3.0 | 固化当前对话 Codex 浏览器优先策略，并优化陪审团 A/B 大屏与上一条导航 | Solazhu |
| 2026-05-28 | v1.2.0 | 增加会前会议模式选择与会后执行方式选择流程 | Solazhu |
| 2026-05-28 | v1.1.0 | 收束专家团 skill 双功能边界、触发矩阵、反馈格式和 viewer 状态机 | Solazhu |
| 2026-05-27 | v1.0.0 | 新增专家团硬启动流程接手说明 | Solazhu |
