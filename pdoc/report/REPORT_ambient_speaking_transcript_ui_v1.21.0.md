# REPORT_ambient_speaking_transcript_ui_v1.21.0

## 背景

本次修正来自会议页 live 链路反馈：氛围状态不是全员静默占位。`nod` / 对对对、`reserve` / 保留意见、`thinking` / 再想想本来就是可发言氛围人格；`zzz` 和 `phone` 主要承担视觉状态。

同时会议页下方不再展示“会议产物”，只展示全量会议记录。会后结论、实施方案和推荐员工统一由 Codex 聊天栏同步，并作为后续执行引导。

## 修改范围

- `runtime/initialize_live_meeting.ps1`：新增氛围状态画像，写入 `canSpeak`、`speechStyle`、`defaultUtterance` 等字段；默认氛围状态顺序保证有睡觉状态和可发言氛围人格。
- `runtime/append_live_meeting_turn.ps1`：追加 turn 后把可发言氛围人格写入 `runtime.queue`，并在下一步提示里明确主进程需要读取可发言氛围状态。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：删除 viewer 端会议产物面板组件，只保留会议舞台和全量会议记录。
- `assets/expert-meeting-viewer/react-viewer/src/styles.css`：删除会议产物相关样式；会议记录区域全量展开。
- `SKILL.md`、`references/VISUAL_TRANSCRIPT_SCHEMA.md`、`pdoc/design/*`、Guide：同步可发言氛围人格和会后聊天栏同步规则。

## 影子评审

- 防止氛围人被误禁言：`nod`、`reserve`、`thinking` 均带 `canSpeak=true`，主进程可直接选择它们作为 speaker 写入 turns。
- 防止氛围人乱入投票：氛围人格可发言，但默认不计入正式投票，除非显式提升为正式参会者。
- 防止会议页提前泄露执行产物：viewer 不再渲染实施方案、推荐员工或 future animation 提示。
- 防止空 live 会议白屏：无 turns 时仍显示等待主进程写入第一条发言。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.21.0 | 校正氛围人格发言规则，并将会议页下方改为全量会议记录 | Unclecow |
