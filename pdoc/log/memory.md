## 2026-06-02 00:00

- 新增 `runtime/set_live_meeting_thinking.ps1`，用 `runtime.pendingSpeaker` 同步下一位 speaker 的真实后台生成期。
- React viewer 读取 `pendingSpeaker` 合成 pending turn，发言内容提交前显示该 speaker 气泡省略号，提交后切换为逐字打字。
- 修正边界：pending 只允许非主持自然发言使用；主持开场、投票、轮次引导、结果公布和总结仍按固定 Q-flow 直接 append。
- `append_live_meeting_turn.ps1` 补齐 `control` turn 支持，并在提交真实 turn 后清空匹配 pending 状态，避免省略号残留。
- React viewer 会议记录改为按当前播放进度逐步揭示，避免中途显示未来发言和最终结论。
- 新增 `REPORT_pending_speaker_generation_sync_v1.25.0` 并同步 Guide / schema / skill 合同。

## 2026-06-01 16:49

- 修正 live runtime 氛围席：铭牌身份继续取真实邀请角色，氛围状态只写入状态字段。
- 启动消息参会列表补齐氛围席真实角色，避免聊天提示与会议页 10 席不一致。
- React viewer 移除氛围状态牌，只保留发言前循环省略号，正文出现后再进入逐字打字。
- 新增并修正 `REPORT_ambient_nameplate_and_thinking_bubble_v1.24.0`，同步接手 Guide 到 v1.24.1。

## 2026-06-01 02:58

- 全量职位化 `ROLE_NAME_ZH.md` 的 260 个中文展示名，保留 260 行、非空、≤6 宽度单位约束。
- 当前 viewer runtime 快照同步刷新正式参会角色名，避免当前页面与新版职位名映射不一致。
- 新增 `REPORT_role_position_names_v1.23.0`，记录中文名从任务标签改为短职位名的命名规则和复核结果。

## 2026-06-01 02:32

- skill 对外英文名改为 `meeting-room`，中文名统一为“会议室”，固定触发句改为 `会议室 skill已触发～喵`。
- React viewer 左上角品牌改为“会议室 / Meeting Room”，同步脚本目标改为全局 `meeting-room` skill 目录。
- 更新会议触发合同检查，要求 `SKILL.md`、工作区 `AGENTS.md` 与全局同步路径均使用新名称。

## 2026-06-01 02:08

- 校正氛围状态规则：`nod` / 对对对、`reserve` / 保留意见、`thinking` / 再想想属于可发言氛围人格，`zzz` 和 `phone` 主要承担视觉状态。
- `initialize_live_meeting.ps1` 写入可发言氛围人格画像，`append_live_meeting_turn.ps1` 将可发言氛围状态加入后续候选队列。
- React viewer 删除会议产物面板，会议页下方改为全量会议记录；会后结论、实施方案和推荐员工改由聊天栏同步引导。

## 2026-06-01 01:37

- 启动“深度模式的必要性”轻度陪审团 live 会议，自动点击最新 `打开会议页` 链接。
- 修正 `start_expert_panel_meeting.ps1`：live runtime 启动时用完整源会议做陪审团结构校验，避免 runtime 中间态误拦启动。
- 新增 `live-runtime-contract-source-session` 静态回归检查，锁定唯一轻度陪审团 live 启动合同。
- 继续修正默认会议链路：用户侧不再调用 `new_visual_meeting_session.ps1` 预写整场会议，改为 `initialize_live_meeting.ps1` 初始化空 runtime，再由主进程通过 `append_live_meeting_turn.ps1` 逐条写入发言、投票和总结。
- “深度模式的必要性”会议已按 main-process live 重开并完成，当前 runtime 为 6 个正式角色 + 4 个氛围席、`turns=10`、`voteRounds=2`。

## 2026-05-31 22:18

- 收束 `agency-agents` 用户侧为唯一会议入口，禁止再询问“普通会议 / 陪审团会议”二选一。
- 修正唯一会议形态为轻度陪审团 live：默认 `jury_deliberation`，主进程写入 `meeting-runtime.json`，大屏保留 A/B 选项。
- 删除 `roundtable` 功能链路：脚本参数、生成器默认值和前端缺省 mode 均不再允许圆桌会议路径。
- 归档旧 `REPORT_light_roundtable_live_runtime_v1.1.0.md`，避免旧普通/圆桌 live 报告继续误导当前实现。
- 同步新版 `agency-agents` 到全局 skill，并通过本地/全局会议触发合同检查与前端构建。
- 修复 React viewer 中 `ambientState="zzz"` 只显示 zzz 不显示睡觉鼻涕泡的问题。
- 更新会议触发静态回归、Guide、规则文档和执行报告。

## 2026-05-29 01:46

- 删除旧 `open_inapp_browser_url.ps1` 侧栏/URL 输入自动化，停止模拟拉起右侧栏和输入链接。
- 新增 `click_latest_meeting_link.ps1` 最小自动打开脚本，只寻找最新可见的 `打开会议页` 链接并 Invoke。
- `start_expert_panel_meeting.ps1` 返回 `autoClickLinkText` 与 `autoClickScript`，默认策略改为 `click_latest_meeting_link`，SKILL 规则要求输出会议文案后强制运行该脚本。
- 启动阻塞文案改为 viewer/server/session 身份校验失败，不再归因到右侧浏览器展开状态。
## 2026-05-29 01:32

- 收束专家团会议打开方式：默认不再 UIAutomation 自动展开右侧浏览器，改为输出可点击 `[打开会议页](currentBrowserUrl)` 链接。
- `start_expert_panel_meeting.ps1` 默认 `browserOpenStrategy=clickable_link`，`servedSession.matches=true` 即输出会议运行消息，不再依赖 `browserOpened=true`。
- `open_inapp_browser_url.ps1` 仅保留为显式 `-UseInAppAutomation` 调试路径，避免聊天输出区/网页预览卡片误判为会议页。
## 2026-05-29 01:18

- 执行《会议 skill 未触发：根因与根治方案》会议结果：新增会议触发独占合同与静态回归脚本。
- `scripts/test_meeting_trigger_contract.ps1` 覆盖固定首句、触发词、禁止 deepseek 抢路由、硬启动字段、禁止兜底、served-session 身份校验和工作区 AGENTS 规则。
- 新增 `RULE_meeting_trigger_contract_v1.0.0` 与 `REPORT_meeting_trigger_execution_v1.11.0`，并把回归入口写入 SKILL 与 Guide。
## 2026-05-29 01:08

- 修复专家团 viewer 长期开启卡顿风险：DotGrid 空闲时停止 RAF 和鼠标监听，LetterGlitch 空闲时停止 React interval。
- 增加页面可见性和播放状态降载：会议结束/暂停/页面隐藏时关闭装饰无限动画。
- session 轮询分档：播放中 1s、结束空闲 10s、页面隐藏 30s。
## 2026-05-29 00:51

- 修复专家团会议旧页面误报：启动脚本必须校验 viewer 实际服务的会议 `id` 与本次 session 一致。
- 5175 被旧全局 viewer 占用时不再复用旧会议，改为尝试后续端口并只在 `servedSession.matches = true` 时导航右侧浏览器。
- 校验读取改用 UTF-8 原始流并剥离 BOM，避免本地 JSON 带 BOM 被误判为非法 JSON。
## 2026-05-29 00:10

## 2026-05-29 00:20

- 将专家团 skill 固定触发提示提升为覆盖项目通用开场的优先规则，禁止先输出 `收到计划，开始执行～喵`。
- 根目录新增 `AGENTS.md` 补充规则，在当前工作区内要求会议触发第一句固定为 `agency agents 会议skill已触发～喵`。

- 新增专家团 skill 命中提示硬规则：触发后第一可见句必须输出 `agency agents 会议skill已触发～喵`。
- 更新 `SKILL.md` 与接手 Guide，要求触发提示早于会议模式选择、会议页启动和任何后续流程。

## 2026-05-27 22:37

- 新增专家团会议硬启动脚本，串联 session 生成、viewer 启动、Codex 内置浏览器导航。
- 扩展会议 session 结构，增加可实施方案、推荐员工子任务、后续工作动画方向字段。
- 扩展 React viewer 会议产物展示区，用于展示方案、推荐员工和后续动画建议。
- 修复内置浏览器已在会议页时仍误报导航失败的问题。
- 更新 skill 规范、会议 schema、pdoc 报告和接手 Guide。

## 2026-05-27 22:45

- 硬编码专家团 Codex 侧消息模板：开会中显示主题、参会人员、裸 viewer URL；会后显示结论、实施方案、推荐员工。

## 2026-05-27 23:10

- 修复专家团 viewer 旧会议页误判：确认脚本只检查右侧内置浏览器区域，并要求匹配本次会议主题。
- React viewer 增加 current-session 轮询，新 session 写入后直接通过现有转场载入新会议，不依赖整页刷新。
- 中文议题下过滤英文/韩文资料原句，发言内部字段名转中文，参会人员职位中文化。

## 2026-05-27 23:20

- 调整会议产物加载时机：会议动画结束前不渲染实施方案与推荐员工，避免开会前提前看到结论。

## 2026-05-27 23:35

- 修复功能一会议发言机械化：移除固定九段式台词拼接，改为按边界、接话、反驳、修正、验收、收束等会议动作生成。
- 增加自然发言约束：角色资料只做判断依据，不直接摘抄进台词；同一角色二次发言必须换角度或回应具体异议。

## 2026-05-28 00:10

- 新增自然会议发言规则文档，明确用户示例只作为意图信号，不写入硬编码台词。
- 会议生成器增加角色声音画像，按产品、工程、测试、设计、学术、市场等专业镜头生成更自然的接话、反对、补充和修正。

## 2026-05-28 00:25

- 修复主持人开场无语境问题，改为正常开题、提出具体问题、邀请专家从专业角度发言。
- 专家发言改为第一人称讨论链：同意、补充、反对、修正和说明专业后果，减少直接抛方案式读稿。

## 2026-05-28 00:45

- 收窄双功能边界会议识别规则，避免普通项目优化会议因为出现“子任务/功能一”等提示而误触派工边界模板。

## 2026-05-28 02:58

- 修正专家团功能一正式入口：不再使用脚本按赞同、反对、总结等会议动作生成台词。
- `start_expert_panel_meeting.ps1` 改为支持 `-UseCurrentSession` / `-SessionFile`，正式会议只负责装载已写好的 session、启动 viewer、打开 Codex 内置浏览器。
- 更新自然会议规则：每条发言只能根据已发生对话、当前角色专业/性格和真实议题约束自由生成，不允许预设 debate move。
- 写入并载入 `E:\AI\deadman` 优化会议 authored session，参会角色来自真实专家名单，网页已确认加载本次会议。

## 2026-05-28 03:21

- 新增专家团辩论共识模式规则：主持人只抛 A/B 冲突方案，不替员工预设立场；多数派不天然胜出，少数观点可说服多数转向。
- React viewer 支持 `mode: "debate_consensus"`：大屏幕标题自动压缩并上移，左侧显示绿色 A、右侧显示红色 B。
- 铭牌支持辩论阵营边框：只根据员工自己的 `stanceSide` / `debateSide` 发言字段在播放进度中更新，普通会议不显示阵营边框。
- 更新 skill 与可视化 schema，禁止静态 `debate.stances`、`stanceByRole` 或 roleMeta 立场字段预设阵营。

## 2026-05-28 03:31

- 删除前一版 `debate_consensus` 即时站队模式，专家团冲突决策统一改为 12怒汉式 `jury_deliberation`。
- React viewer 改为读取 `deliberation.voteRounds`：初始投票、每轮发言后投票，铭牌边框只按最近可见投票轮显示。
- 大屏幕保留 A/B 和票数展示，普通发言不再通过 `stanceSide` / `debateSide` 直接改变铭牌阵营。
- 更新 skill、自然发言规则和可视化 schema：多数不自动胜利，少数观点可在后续投票中说服多数转向。

## 2026-05-28 03:38

- 写入并载入一场 `jury_deliberation` 示例会议，议题为“会议模式 vs 陪审团模式：专家团应该怎么选”。
- 示例会议包含初始投票、第一轮后投票和最终投票，票数从 A 4 / B 3 变化到 A 0 / B 7。
- 修复 `start_expert_panel_meeting.ps1` 的内置浏览器确认逻辑，使其匹配 viewer 压缩后的大屏标题，避免长标题被截断后误报失败。

## 2026-05-28 05:21

- 收束专家团 skill 主流程：在 `SKILL.md` 新增 Operational Contract，明确功能一“开会出方案”和功能二“员工执行子任务”的边界。
- 新增触发矩阵、视觉会议状态机、Codex 开会中/会后/执行中反馈模板，以及内置浏览器优先的兜底顺序。
- 更新陪审模式规则：A/B 铭牌使用小标记而非边框；后续投票只有改变立场的员工播放伸手动画。
- 新增 `pdoc/design/DESIGN_专家团skill流程收束_v1.1.0.md`，并更新接手 Guide 到 v1.1.0。

## 2026-05-28 05:44

- 将专家团功能一入口改为会前模式选择：Codex 先询问普通会议或陪审团会议，选完后才载入会议。
- 将功能一会后输出改为带执行方式选择：直接主任务执行或拉起子 agent 分工执行。
- 更新 `start_expert_panel_meeting.ps1`、流程设计文档和接手 Guide，避免会议产物刚生成就自动派工。

## 2026-05-28 06:04

- 修复 `agency-agents` skill 跨项目不触发问题：`SKILL.md` 入口文件改为 UTF-8 无 BOM，避免 YAML frontmatter 无法稳定识别。
- 强化 `description` 触发词，加入专家团、开会、陪审团、圆桌会议、12怒汉等关键词。
- 新增 `pdoc/report/REPORT_skill_trigger_bom_v1.0.0.md` 记录本次触发问题根因、编码例外和后续注意事项。
## 2026-05-28 06:25

- 固化专家团当前对话 Codex 浏览器优先策略：默认返回 `currentBrowserUrl`，由 Browser/iab 打开当前窗口。
- 将 `open_inapp_browser_url.ps1` 降级为 legacy 兜底，避免误操作其他对话窗口后误报成功。
- 优化陪审团 viewer 大屏 A/B 信息展示，增加主含义、说明行和票数布局。
- 顶部导航新增 `上一条`，与 `下一条` 对应，支持会议发言回看。

## 2026-05-28 06:35

- 修复专家团 viewer 大屏主题仍出现省略号的问题，改为提炼产品名与会议类型后展示。
- 大屏标题字体从像素字体切换为紧凑中文 UI 字体，降低英文字符占位。

## 2026-05-28 06:45

- 在专家团 viewer 会场左上空白区新增阶段进度 HUD，显示当前轮次与发言/投票/收束状态。
- HUD 兼容普通会议：无投票轮时按当前发言 `phase` 显示发言中或收束中。

## 2026-05-28 07:05

- 新增席位前立体 A/B 投票按钮，替代铭牌上的旧 A/B 小标记。
- 顶部导航新增设置入口，支持测试 A/B 亮灯效果、开启布局校准、微调铭牌和投票按钮位置。
- 布局复制数据新增 `voteButtons`，并暴露 `window.__agencyVoteButtonPlacements` 供后续固化坐标。

## 2026-05-28 07:22

- 设置面板新增布局精修区：铭牌支持位置、旋转、朝向、俯仰、斜切和宽度调整。
- 投票按钮支持位置、旋转和大小调整，便于和铭牌空间一起微调。
- 校准目标改为全座位槽位，空位也能提前调整；skill 规则要求视觉调试会议尽量补满座位。

## 2026-05-28 07:35

- 简化投票按钮：去掉字母，使用暗绿/亮绿、暗红/亮红表达关闭与亮起状态。
- 去掉投票按钮组外层胶囊底座，仅保留两个独立小圆按钮，按钮旋转范围放宽到 `-180~180`。
- 当前调试会议补满 10 个侧边席位，确保所有位置都可调整。

## 2026-05-28 13:19

- 将当前浏览器手工调整后的铭牌与投票按钮坐标固化为 viewer 默认布局。
- 新增 `pdoc/material/MAT_viewer_layout_adjustment_v1.4.3.json` 保存本次布局快照。
- 新增 `pdoc/report/REPORT_recorded_viewer_layout_v1.4.3.md` 记录采集方式、影响范围与复核要点。

## 2026-05-28 13:42

- 修正陪审团投票时序：主持人读题阶段按钮双暗，主持人投票 turn 读完后伸手投票，触碰后才亮灯。
- 当前调试会议改为主持人 Q 流程：读题、第一轮投票、第一轮发言、第二轮投票、第二轮发言、第三轮投票、全票后总结。
- 更新 skill 与视觉 transcript 规则，要求 `voteRounds.afterTurnId` 只指向主持人投票控场 turn。
- 当前调试会议 `id` 升级，确保已打开 viewer 能识别新流程并转场刷新。

## 2026-05-28 13:47

- 撤销把伸手动画挂到旋转投票按钮组上的错误实现，恢复为原席位/铭牌坐标体系里的 `seat-vote-hand` 动画。
- 投票按钮层仅保留双暗、pending 按下反馈和亮灯状态，避免手势跟随按钮旋转变形。

## 2026-05-28 14:12

- 新增舞台级 `stage-vote-hand` 伸手动画，路径由每个座位的起点与投票按钮中心终点控制。
- 设置面板新增 10 个座位的伸手起点/终点校准入口，并支持拖动与精修按钮调整。
- 从 Codex 内置浏览器本地存储读取用户手调后的 10 个伸手起点，固化为 `voteHandPlacements` 默认值。
- 设置面板测试按钮改名为 `伸手测试 A / 伸手测试 B`，便于直接观察伸手与亮灯效果。

## 2026-05-28 14:56

- 将投票手势从平移手改为肩膀锚点旋转手臂，支持肩膀、初始手位、投票手位和手臂长度调节。
- 从 Codex 内置浏览器 Local Storage 提取用户最新布局，固化座位、铭牌、按钮和部分手臂校准坐标。
- 手臂长度改为按肩膀到投票目标距离实时计算，长度上限放宽到 360，并修复测试 A/B 不触发手臂方向的问题。
- 新增 `pdoc/material/MAT_viewer_arm_layout_v1.4.7.json` 和 `pdoc/report/REPORT_frozen_vote_arm_layout_v1.4.7.md` 记录布局快照与复核结果。

## 2026-05-28 15:34

- 投票手臂末端由尖头裁剪改为圆头胶囊形态。
- 投票手臂层级改为跟随席位 `z - 1`，放在对应员工身体图层下方。
- 伸手动画拆成伸出、停顿、收回三段，拉长收回段以便肉眼看清。
- 新增 `pdoc/report/REPORT_vote_arm_visual_polish_v1.4.8.md` 记录本次视觉修正。

## 2026-05-28 15:55

- 批量生成牛牛全黑剪影素材，保留白椅子、透明边界和原图尺寸不漂移。
- viewer 底层座位图和头部遮挡图切换为 `occupied-seats-silhouette` / `occupied-seat-heads-silhouette`。
- 保留 `FaceOverlay` 眼睛嘴巴在最上层，避免剪影方案丢失表情反馈。
- 投票手臂重做为纯黑细圆臂，层级位于牛牛剪影上方、铭牌/按钮/脸部覆盖层下方。

## 2026-05-28 16:24

- 普通会议默认隐藏投票按钮，仅在陪审团投票、伸手测试或投票相关校准目标下显示。
- 投票手臂视觉层从直长柱改为 SVG 柔和弯臂剪影，保留既有肩膀、手位、按钮和长度校准数据。
- 新增 `pdoc/report/REPORT_normal_meeting_vote_buttons_hidden_v1.4.10.md` 与 `pdoc/report/REPORT_svg_curved_vote_arm_v1.4.11.md` 记录修正边界。

## 2026-05-28 16:31

- 修正 SVG 投票手臂长度偏差：`--vote-arm-length` 现在约束视觉总宽度，不再额外叠加圆掌长度。
- 投票手臂造型由厚重闭合块收敛为圆角曲线加小圆掌，降低视觉突兀感。

## 2026-05-28 16:39

- 移除投票手臂额外红/绿色触碰光点，按钮亮灯由投票按钮自身负责。
- 投票手臂从等宽曲线改为上宽下窄的填充式剪影，肩部加粗、腕部收窄、手端保持圆弧。
- SVG 手臂关闭外溢显示，减少收回状态肩膀向身体外冒的问题。

## 2026-05-28 16:45

- 投票手臂可见根部从锚点内缩约 6-8px，解决牛牛嘴下方肩膀凸起问题。
- 肩膀半径继续加粗，手端保持小圆弧，SVG 总宽度仍严格等于手臂长度设置。

## 2026-05-28 18:13

- 从 Codex 内置浏览器 Local Storage 重新读取最新布局记录，并固化当前座位、铭牌、投票按钮和投票手臂默认值。
- 修复真实陪审团会议投票手臂过早消失：延长投票 reveal 与投票 turn 额外停留时间，保证手臂完成伸出、触碰、收回后再切到稳定票态。
- 新增 `pdoc/material/MAT_latest_localstorage_layout_extracted_v1.4.16.json` 与 `pdoc/report/REPORT_hardcoded_layout_and_vote_retract_v1.4.16.md` 记录本次快照和复核结论。

## 2026-05-28 18:47

- 投票按钮卡通圆柱样式继续微调：A 暗绿压暗，B 亮红提高纯度和亮度。
- 投票手臂目标点统一上提 8px，让手臂更接近两个按钮中间而不是偏下方按钮。
- 调整按钮与手臂层级：按钮仍在桌面上方，但低于投票手臂，确保手臂按按钮时压在按钮上层。

## 2026-05-28 18:57

- 根据牛牛人格区分陪审会结论，新增 `FaceOverlay` 眼睛和嘴巴 variant 系统。
- 新增 `roleExpressionProfiles` 与关键词 fallback，让常用角色拥有稳定人格表情组合。
- 发言嘴型改为读取各嘴型自己的开合尺寸变量，不改变牛牛主体剪影、体型和座位模型。

## 2026-05-28 19:12

- 撤回未完成的随机换座实验，保留固定席位体型和“人格代表部门”的业务解释。
- 扩展 `FaceOverlay` 表情库到更多眼睛/嘴巴组合，并按部门角色稳定映射。
- 修正表情眨眼规则：除眯眼类外，其余眼睛 variant 均保留 blink 动画。

## 2026-05-28 20:08

- 在 `E:\AI\会议室\agency-agents` 工作副本新增 260 个 role slug 的全量表情预设表。
- `App.jsx` 接入 `generatedRoleExpressionProfiles`，未知角色仍保留关键词 fallback。
- 新增 `scripts/generate_role_expression_profiles.ps1`，后续可从 `roles_manifest.json` 重新生成表情映射。
## 2026-05-28 23:45

- 禁止专家团 Function 1 会议兜底：会议页未确认打开时必须中断，不再文字模拟会议或输出结论。
- `start_expert_panel_meeting.ps1` 增加 `codexLaunchBlockedMessage`、`hardStartRequired`、`textFallbackAllowed`，用脚本字段标明硬启动失败不可兜底。
- 更新 `SKILL.md`、接手 Guide 与 v1.7.0 报告，明确默认浏览器和 fallback session 不再自动用于正式会议触发。

## 2026-06-02 02:05

- 修复 live 投票归一化：投票 turn 补齐所有可见非主持席位，未知投票人不再污染票数。
- `nod` / 对对对不再固定投 B，改为跟随本轮正式席位明确多数；无明确多数则弃权。
- React viewer 大屏票数、座位按钮和铭牌投票边框统一使用补齐后的 votes 计算。

## 2026-06-02 01:36

- 修复会议页宿命论泄漏：默认 `meeting-runtime.json` 恢复为 `turns=0` 的 live shell，不再承载完整验证样本。
- 修复 React viewer 空运行态进度，从 `1 / 0` 改为“等待写入”，会议记录保持 `0 / 0`。
- 修正会议触发合同中的 progressive transcript 断言，确保只显示当前和历史 turn。

## 2026-05-28 22:20

- 收紧专家团 Function 1 用户侧话术：禁止暴露 `SCRIPT_*`、会议数据、剧本、session JSON、内部 A/B 标记等后台制作细节。
- 修复会议启动浏览器语义：`browserOpened` 仅在右侧 Codex 浏览器实际确认会议页后为 true。
- 增强 `open_inapp_browser_url.ps1`：支持侧栏可见状态检测、Browser/Expert Meeting React Viewer 控件选择、`Ctrl+Alt+B` 展开兜底和页面文本确认。
- 更新本地接手 Guide 与执行报告，暂未同步全局 skill。
## 2026-05-29 02:24

- 修复 UTF-8/BOM 陪审团 current-session：主持人读题后立即进入 `host-vote-1`，专家只发言不宣布票数或裁决。
- `start_expert_panel_meeting.ps1` 增加陪审团 Q 流程启动前校验，坏 session 不再打开 viewer。
- `test_meeting_trigger_contract.ps1` 增加当前陪审团 session 契约检查：turn id、`afterTurnId`、主持人控场、禁用旧投票索引字段。

## 2026-05-29 02:36

- 将陪审团会议硬规则升级为固定状态机：`opening` -> `host-vote-N` -> `host-rN-start` -> 陪审发言循环，最终全票统一后直接 `host-final`。
- `start_expert_panel_meeting.ps1` 校验每个非全票投票轮后必须有主持人公布票数并引导发言，发言区只能包含陪审员 `speak` turn。
- UTF-8/BOM 当前会议改为三轮投票样例，第三轮 5:0 后由主持人总结。

## 2026-05-29 02:43

- 会议大屏标题改为主动压缩到 15 字以内，不再使用省略号截断。
- UTF-8/BOM 议题标题压缩为 `UTF-8 BOM取舍`，避免显示 `...`。
- `.meeting-screen h2` 扩大可用宽度并移除标题层 `text-overflow: ellipsis`。
- 压缩 260 个角色中文展示名到 6 字以内，并把 260 行/非空/≤6 字加入回归契约。

## 2026-05-29 09:31

- 新增实时多人格子 agent 会议 runtime V1 设计文档。
- 写死主持人由主进程担任、参会最少 5 人、默认尽量 6 人、上限 10 人。
- 设计确定为：所有参会人格实时思考、并发思考、排队发言、每条发言后全员增量再思考。

## 2026-05-29 09:44

- 新增 `runtime/run_live_meeting.ps1`，先把会议从“整篇剧本播放”推进到“live session 逐条追加”的 MVP。
- `current-session.json` 已可写入 `runtime.status / round / thinking / queue / host=main-process`。
- 用当前 UTF-8/BOM 陪审团会议跑通了一次 live runtime MVP，输出 `generator=agency-agents/runtime/run_live_meeting.ps1`。

## 2026-05-29 12:40

- 固化前台展示边界：会前等待文案只出现在聊天侧，允许显示 `正在通知员工开会` 和 `XX 已进入会议室`。
- 会议页前台继续保持 authored 版本观感，不暴露子 agent 拉起、thinking、queue、随机昵称等后台细节。
## 2026-05-31 03:55

- 固化后五席 15 个氛围元素默认位置到 `AMBIENT_DECOR_DEFAULTS`，移除临时抓取桥。
- 氛围位鼻涕泡改回图片资产，补上左右翻转字段与默认值。
- 手机小屏改为：聊天 CSS 循环、视频三帧满屏补偿、小游戏切为极简打砖块。
- `new_visual_meeting_session.ps1` 改为“正式参会 + 随机氛围状态补满 10 席”，会说话的氛围位进入 turn 流。
- `run_live_meeting.ps1` 改为忠实读取 source session 参会名单和 roleMeta，不再追加固定假氛围位，并补上弃权标签字段。

## 2026-05-31 18:19

- 普通会议默认接入轻度 live runtime，启动后由 `meeting-runtime.json` 承载实时会议状态。
- `run_live_meeting.ps1` 补全 runtime 真状态字段，并改为临时文件替换写入以降低半写 JSON 风险。
- `start_expert_panel_meeting.ps1` 在 roundtable 模式后台启动 live runtime，陪审团和显式 session 路径保持不变。
- React viewer 支持同一会议 id 的增量 turns/runtime 更新，新增 turn 后可从结束态恢复继续播放。
- 修正陪审团样例生成器，氛围位不再计入正式投票，当前 `current-session.json` 重新通过会议触发合同检查。

## 2026-06-14 16:20

- 收束会议默认交付为“文字会议主流程 + 可选可视化旁观链接”，不再自动拉起 viewer。
- `start_expert_panel_meeting.ps1` 改为 viewer 可用时仅返回手动点击链接，不再把 `servedSession.matches` 当成文字会议前置门槛。
- `SKILL.md`、`AGENTS.md`、触发合同校验器与接手文档同步切换到文字优先口径。

## 2026-06-15 00:15

- 新增 `runtime/import_text_meeting_result.ps1`，支持把已完成的文字会议 transcript 和精简摘要后置导入 viewer。
- viewer 空态改为“等待文字会议导入”，不再误导成一定有实时写入流程。
- viewer 新增底部短摘要区，综合方案、推荐任务、推荐角色统一放在结尾展示。

## 2026-06-15 00:45

- 发布前收束会议室 skill：默认会议回归 `discussion` text-first live，陪审团/A-B 仅在显式投票类请求中启用。
- 同步更新 `SKILL.md`、工作区 `AGENTS.md`、触发合同、接手 GUIDE、流程设计文档和 authoring context 输出路径。
- 清理 React viewer 本地可再生成产物：`node_modules`、`dist`、`.playwright-cli`、`react-viewer-dev.log`。

## 2026-06-16 01:30

- 正式发布前补齐文字陪审/PK 导入 viewer 链路，`import_text_meeting_result.ps1` 支持 `VoteRoundsJson` 与 `DeliberationJson`。
- 新增静态回归项 `text-import-preserves-jury-votes`，防止导入脚本再次抹掉 A/B 投票轮。
- 浏览器验证 discussion 导入、实时 append、陪审投票导入三条路径均可显示对应会议内容和结尾摘要。

## 2026-06-16 01:35

- 正式发布前完成本地与全局触发合同回归，均为全绿。
- 同步全局 `meeting-room` skill 后确认发布包不含 `react-viewer/node_modules` 和临时验收 JSON。
- 重置本地与全局 runtime 为 `正式发布验收` / `discussion` / 0 turns，避免测试会议内容进入发布包。
