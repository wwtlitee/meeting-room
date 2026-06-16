# REPORT_pending_speaker_generation_sync_v1.25.0

## 背景

用户明确指出：会议页省略号不应该是“turn 已经写好以后打字前的装饰”，而应该同步后台真实生成期。除主持固定话术等极少数流程语句外，多人格发言必须先读取当前 speaker 的人格信息和最新会议实时内容，生成完成后再开始说话。

## 修改范围

- `runtime/set_live_meeting_thinking.ps1`：新增后台生成期同步脚本。主进程选定下一位非主持 speaker 后先写入 `runtime.pendingSpeaker`，同时标记需要读取人格资料与实时会议记录；主持固定控场 turn 禁止进入 pending。
- `runtime/append_live_meeting_turn.ps1`：提交真实 turn 时复用匹配的 pending `turnId`，并在写入后清空 `runtime.pendingSpeaker`；同时补齐主持固定 Q-flow 所需的 `control` turn 支持。
- `runtime/initialize_live_meeting.ps1`：初始化 runtime 时显式提供 `pendingSpeaker = null`。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：读取 `runtime.pendingSpeaker` 并合成一个 pending turn；当真实 turn 尚未提交时，发言框显示该 speaker 的姓名/职位和循环省略号。真实 turn 到达后，切换为逐字打字。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：会议记录面板改为随播放进度逐步揭示，避免 `1/N` 时提前显示后续发言、投票结果和最终结论。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：空 live runtime 顶部进度显示“等待写入”，避免用占位气泡产生 `1 / 0` 伪进度。
- `assets/expert-meeting-viewer/art/meeting-runtime.json`：恢复为 `turns=0` 的默认 live shell，完整流程验证样本不得写入默认运行态文件。
- `SKILL.md`、`references/VISUAL_TRANSCRIPT_SCHEMA.md`、Guide：同步“先 pending、再 append”的 live 会议合同。

## 影子评审

- 防止假思考：pending 状态只对应后台真实读取人格和会议内容的时间窗，不作为预写剧本或状态牌展示。
- 防止改坏主持节奏：`set_live_meeting_thinking.ps1` 禁止 host，主持人的开场、投票、轮次引导、结果公布和总结必须直接 append。
- 防止错人发言：pending turn 直接来自 `runtime.pendingSpeaker.roleId`，viewer 使用同一套 `roleMeta` 显示姓名和职位。
- 防止提交后卡省略号：`append_live_meeting_turn.ps1` 每次提交真实 turn 都清空 `pendingSpeaker`。
- 防止宿命论观感：transcript 只显示当前播放进度之前的记录，未来结论不会在会议中途露出。
- 防止测试态污染运行态：默认 `meeting-runtime.json` 不保留完整验证回合，实时会议只展示已 append 或当前 pending 的内容。
- 防止 live 追加倒退：viewer 在上一条已结束且收到新 turn 时直接跳到新 turn 播放，避免重播上一条。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-02 | v1.25.3 | 默认 runtime 恢复为空 live shell，空状态进度显示等待写入 | Unclecow |
| 2026-06-02 | v1.25.2 | 会议记录按播放进度揭示，禁止提前显示未来结论 | Unclecow |
| 2026-06-02 | v1.25.1 | 限定 pending 只包非主持发言，补齐 host control turn 支持 | Unclecow |
| 2026-06-02 | v1.25.0 | 新增 pendingSpeaker 生成期同步，让发言框省略号对应真实后台思考 | Unclecow |
