# REPORT_main_process_live_meeting_v1.20.0

## 背景

“深度模式的必要性”会议暴露出关键架构偏差：默认链路仍先调用 `new_visual_meeting_session.ps1` 生成完整 turns / voteRounds / summary，再由 runtime 播放。这不是用户定义的 live。

用户确认的唯一会议合同是：群邀请正式角色，氛围状态补满 10 个位置；只用主进程读取人格和实时会议记录，逐条回复并写入会议记录。

## 修改范围

- `runtime/initialize_live_meeting.ps1`：新增空 live runtime 初始化脚本，写入正式邀请人、氛围席、A/B 选项和 `meeting-runtime.context.json`，初始 `turns=0`。
- `runtime/append_live_meeting_turn.ps1`：新增主进程逐条写入脚本，支持追加发言、投票和最终 summary。
- `scripts/start_expert_panel_meeting.ps1`：默认用户侧入口改为 `initialize_live_meeting.ps1`，不再调用预写 session 生成器；`-DisableLiveRuntime` 用户侧禁用。
- `scripts/build_meeting_authoring_context.ps1`：增强“深度 / 轻度 / live / runtime / 主进程 / 会议记录”议题的角色选择权重，优先选择产品、工作流、编排、AI、后端、资深开发等相关角色。
- `scripts/test_meeting_trigger_contract.ps1`：新增 main-process live 初始化、append-only 写入、默认路径不调用模板生成器、10 席填充和 A/B 选项检查。
- `SKILL.md`、Guide、Rule、Design 文档：同步改为 main-process append-only live 合同。

## 影子评审

- 防止“假 live”：默认启动后 `meeting-runtime.json` 必须允许 `turns=0`，后续由主进程逐条 append。
- 防止模板复活：默认启动脚本不得引用 `newSessionScript` 或调用 `new_visual_meeting_session.ps1`。
- 防止第二会议入口复活：`Mode` 仍只允许 `jury_deliberation`；深度只能作为后续 `runtimeDepth` 内部状态。
- 防止画面席位缺失：正式参与者 + 氛围状态必须合计 10 个可视席位。

## 复核结果

- “深度模式的必要性”会议已重新用 main-process live 打开：6 个正式角色 + 4 个氛围席。
- 会议记录由主进程逐条 append：最终 `turns=10`、`voteRounds=2`、`runtime.status=done`。
- 本地静态合同检查通过。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.20.0 | 默认会议改为 main-process append-only live，删除用户侧预写模板播放链路 | Unclecow |
