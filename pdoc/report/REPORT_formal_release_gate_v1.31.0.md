# REPORT_formal_release_gate_v1.31.0

## 基本信息

- 日期：2026-06-16
- 版本：v1.31.0
- 负责人：Unclecow
- 范围：会议室 skill 正式发布前自测、文字导入 viewer、陪审/PK 投票导入保真

## 本次处理

- `runtime/import_text_meeting_result.ps1` 新增 `-VoteRoundsJson(File)` 与 `-DeliberationJson(File)`，支持文字陪审/PK 会议完成后导入 viewer 时保留 A/B 选项、投票轮和投票动画。
- `scripts/test_meeting_trigger_contract.ps1` 新增 `text-import-preserves-jury-votes` 回归项，防止导入脚本再次无条件清空 `deliberation.voteRounds`。
- `SKILL.md`、`VISUAL_TRANSCRIPT_SCHEMA.md`、接手 GUIDE 同步补充：默认 discussion 导入可清空投票；显式陪审/PK/多轮投票导入必须带投票轮数据。
- 清理本地浏览器历史中的临时测试标题，避免发布 Review 时混入测试噪声。

## 验证结果

- 本仓触发合同回归通过。
- 文字 discussion 导入路径通过：导入后 `mode=discussion`、turns 与 summary 正常，viewer 结尾摘要在最后显示。
- 实时 append 路径通过：主持、专家发言、总结逐条写入，runtime 状态从 `host_control` 到 `discussion` 到 `done`。
- 文字陪审/PK 导入路径通过：导入后 `mode=jury_deliberation`、`voteRoundCount=2`，viewer 可见 A/B 大屏、票数和铭牌投票标记，结尾摘要在最后显示。
- 发布同步路径通过：已同步到 `C:\Users\39215\.codex\skills\meeting-room`，本地与全局触发合同回归均通过。
- 发布包清洁检查通过：本地与全局 `react-viewer/node_modules` 均不存在，5175/5176 测试端口均未监听，临时验收 JSON 已清理。
- 当前 runtime 已重置为干净的 `正式发布验收` / `discussion` / 0 turns，避免测试会议内容进入发布包。

## 风险与边界

- 当前 viewer 历史会议来自浏览器 localStorage，不属于发布包；正式发布前可清空本地历史以避免测试会议干扰人工 Review。
- 投票导入要求调用方提供合法 `afterTurnId`，且 `afterTurnId` 必须指向导入 turns 中存在的主持投票 turn。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-16 | v1.31.0 | 补齐文字陪审/PK 导入 viewer 时保留 A/B 投票轮的发布门禁 | Unclecow |
