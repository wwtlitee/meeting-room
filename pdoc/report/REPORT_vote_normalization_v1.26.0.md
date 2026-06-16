# REPORT_vote_normalization_v1.26.0

## 背景

用户指出会议页投票存在不一致：所有人，尤其是氛围状态席位的投票选择和大屏票数需要重新检查；其中 `nod` / 对对对不应被固定算到某一边。

## 修改范围

- `runtime/initialize_live_meeting.ps1`：将 `nod` 的默认投票意图从固定 `b` 改为 `agree`，语义改为跟随当前明确正式多数。
- `runtime/append_live_meeting_turn.ps1`：新增投票归一化链路，投票 turn 会过滤未知投票人，并补齐所有可见非主持席位。
- `runtime/append_live_meeting_turn.ps1`：氛围状态投票补齐规则为：`nod` 跟随本轮正式席位明确多数；没有明确多数则 `z`；`reserve` / `thinking` / `zzz` / `phone` 默认 `z`。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：前端投票统计改为同一套全可见席位归一化逻辑，旧 session 缺氛围票时也能补齐显示。
- `scripts/test_meeting_trigger_contract.ps1`：新增运行态投票归一化和 viewer 投票归一化合同检查。

## 影子评审

- 防止对对对硬编码：`nod` 不再固定投 A 或 B，只能跟随正式票明确多数。
- 防止票数和按钮不一致：后端写入与前端大屏统计都基于同一份补齐后的 visible voter map。
- 防止未知角色污染票数：`VotesJson` 中不在当前可见非主持席位内的 roleId 会被忽略。
- 防止漏投导致总数漂移：未显式投票的正式席位补 `z`，氛围席按状态补齐。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-02 | v1.26.0 | 修复全可见席位投票归一化与大屏统计一致性 | Unclecow |
