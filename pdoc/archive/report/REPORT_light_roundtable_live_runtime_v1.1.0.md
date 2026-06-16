# REPORT_light_roundtable_live_runtime_v1.1.0

## 基本信息

- 日期：2026-05-31
- 版本：v1.1.0
- 负责人：Unclecow
- 范围：普通会议轻度 live runtime 默认路径

## 完成内容

- 普通会议默认改为启动 `meeting-runtime.json`，不再只把整篇 `current-session.json` 当作播放剧本。
- `run_live_meeting.ps1` 补全运行态字段：当前主题、A/B 方案、主持人阶段、轮次、正式参会名单、氛围位名单、已发生 turns、投票快照、共识草稿、未解决分歧和下一步问题。
- `start_expert_panel_meeting.ps1` 在 `roundtable` 模式下后台启动单进程 live runtime，viewer 通过 `?session=meeting-runtime.json` 读取实时状态。
- React viewer 支持同一会议 `id` 的增量更新：当 turns 或 runtime 变化时更新当前会议，不再因为 id 相同而忽略后续发言。
- 播放器在 live 追加新 turn 后会从已结束状态恢复，继续播放新增发言。
- 修正陪审团样例生成器：氛围位不再进入正式投票，主持人开场和最终投票文案重新满足既有合同检查。

## 影响范围

- 普通会议：默认进入轻度 live。
- 陪审团会议：保留原 `jury_deliberation` 静态/显式 session 路径，本次不强制改成轻度 live。
- 显式 `-UseCurrentSession` / `-SessionFile`：保持原行为。

## 复核要点

- 防止并发写坏 JSON：runtime 写入改为临时文件再替换。
- 防止旧 runtime 污染新会议：启动脚本等待 `sourceSession.id + "-live"` 匹配后才把链接交给 viewer。
- 防止 viewer 停在第一批 turns：同一 id 但 runtime 签名变化时仍更新 active meeting。
- 防止普通会议误触深度路径：只在 `Mode=roundtable` 且未禁用 live runtime 时启动后台 runtime。
- 防止氛围位破坏陪审团全票合同：`deliberation.voteRounds` 只记录正式参会者投票。
- 编码处理：`SKILL.md`、JSON、前端源码和文档保持 UTF-8 无 BOM；含中文字符串且需兼容 Windows PowerShell 5.1 解析的 `.ps1` 保留 UTF-8 BOM。

## 已知边界

- 当前轻度 live 仍由主进程单写入，适合先解决“实时运行态”问题；深度子 agent 陪审团保留现有路线。
- `run_live_meeting.ps1` 目前仍以来源 session 的 turns 作为发言来源，后续可替换为真正逐人格生成发言。
- 本次按协作规则未做浏览器自动化验收，需由用户手动打开会议页验证前台播放。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-31 | v1.1.0 | 普通会议默认接入 `meeting-runtime.json` 轻度 live runtime，并修复 viewer 同 id 增量续播 | Unclecow |
