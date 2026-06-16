# REPORT_live_runtime_launch_contract_v1.19.0

## 背景

启动“深度模式的必要性”轻度陪审团 live 会议时，`start_expert_panel_meeting.ps1` 在 runtime 刚写入初始 shell 或中间票轮时提前执行陪审团结构校验，导致完整源会议本身合法但启动被误拦截。

## 修改范围

- `scripts/start_expert_panel_meeting.ps1`：live runtime 启动时，陪审团结构校验改为校验完整源会议 `$finalMessageSession`；viewer/session 身份校验仍使用 live runtime 文件。
- `scripts/test_meeting_trigger_contract.ps1`：新增 `live-runtime-contract-source-session` 静态检查，防止后续又把中间态 runtime shell 当作完整陪审团结构校验对象。

## 影子评审

- 保留“禁止文字兜底会议”的规则：如果源会议结构本身不合法，仍然阻断启动。
- 不恢复普通/圆桌链路：`Mode` 仍只允许 `jury_deliberation`。
- 避免 live 过程中的合法中间态被误判：初始 shell 可以暂时没有完整 `voteRounds`，但完整源会议必须通过陪审团状态机校验。

## 复核结果

- “深度模式的必要性”会议重新启动成功，viewer served session identity matched。
- 自动点击最新 `打开会议页` 链接成功。
- 本地 `scripts/test_meeting_trigger_contract.ps1` 通过。
- 当前 `meeting-runtime.json`：`mode=jury_deliberation`，`voteRounds=2`，`turns=13`，`runtime.status=done`。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.19.0 | 修正轻度陪审团 live 启动校验对象，避免 runtime 中间态误拦会议启动 | Unclecow |
