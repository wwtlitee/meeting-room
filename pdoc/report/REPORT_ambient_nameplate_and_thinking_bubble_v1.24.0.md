# REPORT_ambient_nameplate_and_thinking_bubble_v1.24.0

## 背景

本次修正来自 live 会议页反馈：氛围只是座位状态，不应该替代受邀人的身份。铭牌必须继续显示真实邀请角色；`睡觉中`、`对对对`、`再想想`、`保留意见`、`看手机` 只能作为内部状态或动作表现存在，不得追加状态牌。

同时实时会议发言人在生成内容前，需要先在发言框正文区显示循环省略号，表达“正在思考”；思考结束后再进入逐字打字。

## 修改范围

- `runtime/initialize_live_meeting.ps1`：初始化 live runtime 时先按会议主题取足 10 个真实角色；正式席之外的氛围席继续使用真实角色 `displayName` / `roleName`，氛围状态只写入 `ambientState`、`ambientLabel`、`stateLabel` 等字段。
- `scripts/start_expert_panel_meeting.ps1`：启动消息中的参会人列表改为正式席 + 氛围席的真实角色，避免只展示正式席导致会议页实际 10 席与聊天提示不一致。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：铭牌主文本固定取座位角色名；氛围状态不再渲染到铭牌区域。`TypewriterText` 在 `isTyping && !text` 时渲染 `ThinkingEllipsis`，第一字出现后切换为正常打字。
- `assets/expert-meeting-viewer/react-viewer/src/styles.css`：仅保留发言框省略号循环动画；关闭 motion 时省略号停止动画。

## 影子评审

- 防止身份被状态覆盖：`Get-AmbientStateProfile` 不再返回 `name` / `title`，氛围席的身份来源只允许来自真实角色。
- 防止可见参会列表漏人：`Get-VisibleMeetingParticipantIds` 在 runtime formalParticipants 后继续追加 ambientParticipants。
- 防止发言框空白误判卡死：正文为空且仍在 typing 时显示循环省略号；正文开始出现后恢复正常文字和光标。
- 防止视觉喧宾夺主：状态不落铭牌，不追加状态牌；视觉状态只通过已有动作反馈表达。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.24.1 | 移除铭牌状态牌，氛围状态不再落到铭牌区域 | Unclecow |
| 2026-06-01 | v1.24.0 | 修正氛围铭牌身份语义，并新增实时发言思考省略号 | Unclecow |
