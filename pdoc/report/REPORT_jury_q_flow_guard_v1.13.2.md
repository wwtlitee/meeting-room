# REPORT_jury_q_flow_guard_v1.13.2

## 背景

本次 UTF-8/BOM 陪审团会议使用了旧版数据结构：`deliberation.voteRounds` 仍以索引字段触发投票，且部分“投票结果/终局裁决”由 `repository-governance-judge` 发言承担，导致主持人 Q 流程断裂。

## 修复

- 重写 `assets/expert-meeting-viewer/art/current-session.json`，改为主持人 Q 流程：
  - `opening`：主持人读题并定义 A/B。
  - `host-vote-1`：主持人立即宣布第一轮投票。
  - `host-r1-start`：主持人宣布第一轮票数并进入发言。
  - 专家只发言，不宣布票数、不裁决。
  - `host-vote-2`：主持人宣布第二轮投票。
  - `host-final`：主持人宣布最终票数和裁决。
- `deliberation.voteRounds[]` 只使用 `afterTurnId`，且均指向 `host-vote-*`。
- `start_expert_panel_meeting.ps1` 增加 `Test-JurySessionContract`，坏陪审团 session 会在启动 viewer 前阻断。
- `test_meeting_trigger_contract.ps1` 增加当前陪审团 session 契约检查，覆盖主持人开场、turn id、`afterTurnId`、非主持人控场禁令。

## 复核

- 本地 PowerShell Parser 检查通过。
- 本地 `test_meeting_trigger_contract.ps1` 通过。
- 当前 session 已确认首两条为 `opening` / `host-vote-1`，且第一轮投票紧跟主持人读题。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.13.2 | 修复 UTF-8/BOM 陪审团主持人 Q 流程，并增加启动前结构校验 | Solazhu |
