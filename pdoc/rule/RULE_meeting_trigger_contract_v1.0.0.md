# RULE_meeting_trigger_contract_v1.0.0

版本：v1.7.0

## 目标

把“会议 skill 未触发”的根因修复收束为可检查合同，避免 Codex 在会议请求中绕过 `meeting-room`、拉起临时智能体、误用计划类 skill，或把可视化旁观链路错误地当成文字会议前置门槛。

## 强制合同

- 用户请求包含 `会议室`、`meeting room`、`专家团`、`会议skill`、`会议 skill`、`专家团开会`、`开会`、`开个会`、`专家团会议`、`陪审团`、`陪审团会议`、`陪审模式`、`12怒汉`、`十二怒汉`、`多角色讨论`、`多智能体讨论`、`expert panel`、`jury deliberation` 等会议触发词时，必须使用 `meeting-room`。
- 命中后第一可见句必须固定为：`会议室 skill已触发～喵`。
- 固定首句必须早于 `收到计划，开始执行～喵`、唯一会议入口启动、viewer 启动、任何通用规划回复。
- 用户侧只有一个会议入口，不得再询问会议类型；圆桌/普通会议旧二选一链路必须删除。默认会议是 text-first `discussion` live：正式邀请人 + 氛围状态补满 10 席，主进程读取人格与实时会议记录并逐条写入 `meeting-runtime.json`；只有用户明确要求陪审、PK、多轮投票时才启用 `jury_deliberation` 与 A/B 选项。
- 用户侧默认启动不得调用预写会议生成器；`meeting-runtime.json` 初始必须允许 `turns=0`，后续只允许通过主进程 append 写入发言、投票和总结。
- 不得路由到 `deepseek-plan-debate`、`autoplan`、plan review/provider 类 skill，除非用户同一句明确点名该 skill/provider 且没有要求会议室会议。
- 文字会议是默认主流程；可视化会议页只允许作为手动点击打开的可选旁观链接，不得自动拉起。
- 会议页未确认打开或实际服务的 `meeting-runtime.json` 与本次会议 `id` 不一致时，只能跳过可视化链接，不得伪造“可视化会议已打开”的状态。
- `browserOpened=true` 不再是文字会议成立的前置条件；只有在会议页真实打开且 `servedSession.matches=true` 时，它才可作为可视化旁观状态成立。

## 回归入口

每次修改以下文件后，必须运行静态回归脚本：

```powershell
.\scripts\test_meeting_trigger_contract.ps1 -SkillRoot . -WorkspaceRoot E:\AI\会议室
```

覆盖范围：

- `SKILL.md` 触发词、frontmatter、固定首句和禁止 deepseek 路由。
- `SKILL.md` 单一会议入口合同、禁止旧会议模式选择、启动脚本默认 discussion live，显式陪审请求才启用 jury deliberation。
- 工作区 `AGENTS.md` 固定首句、强制 skill、文字主流程和手动链接规则。
- `start_expert_panel_meeting.ps1` viewer 可选字段、文字主流程字段、启动说明、served session 身份校验、默认不调用预写会议生成器。
- `initialize_live_meeting.ps1` 与 `append_live_meeting_turn.ps1` 主进程 live 初始化/逐条写入合同。
- 全局 `deepseek-plan-debate` skill 不存在。
- 旧全局 `agency-agents` skill 目录不存在，避免重名旧入口复活。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-15 | v1.7.0 | 默认会议切回 discussion/text-first，陪审团仅作为显式投票/PK机制 | Unclecow |
| 2026-06-14 | v1.6.0 | 明确文字会议为主流程，可视化会议降级为手动打开的可选旁观链接 | Unclecow |
| 2026-06-01 | v1.5.0 | skill 名称改为 meeting-room / 会议室，固定触发句同步更新 | Unclecow |
| 2026-06-01 | v1.4.0 | 新增 main-process append-only live 合同，禁止用户侧预写会议生成器 | Unclecow |
| 2026-05-31 | v1.3.0 | 删除圆桌/普通会议触发与模式链路，回归脚本校验 roundtable 不可再出现于功能路径 | Unclecow |
| 2026-05-31 | v1.2.0 | 明确唯一会议为轻度陪审团 live，并要求大屏 A/B 选项存在 | Unclecow |
| 2026-05-31 | v1.1.0 | 将用户侧会议入口收束为单一入口，禁止普通/陪审团二选一提示 | Unclecow |
| 2026-05-29 | v1.0.0 | 新增会议触发独占合同与静态回归入口 | Solazhu |
