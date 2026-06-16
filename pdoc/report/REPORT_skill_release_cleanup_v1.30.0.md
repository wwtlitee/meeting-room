# REPORT_skill_release_cleanup_v1.30.0

## 基本信息

- 日期：2026-06-15
- 版本：v1.30.0
- 负责人：Unclecow
- 范围：会议室 skill 发布前收束、默认会议模式、可视化旁观链路、本地垃圾清理

## 本次处理

- 将默认会议口径统一为 `discussion` text-first live；陪审团、A/B、方案 PK、多轮投票仅作为显式请求下的内部机制。
- 更新 `SKILL.md`、工作区 `AGENTS.md`、触发合同、接手 GUIDE、流程设计文档，避免旧“默认轻度陪审团 live”规则继续污染发布行为。
- 将 `build_meeting_authoring_context.ps1` 的输出提示从 `current-session.json` 改为 `meeting-runtime.json`，对齐当前文字会议导入和 live runtime。
- 清理 viewer 本地可再生成产物：`dist`、`.playwright-cli`、`react-viewer-dev.log`、`node_modules`。

## 复核结果

- `scripts/test_meeting_trigger_contract.ps1` 本仓回归通过。
- 残留“轻度陪审团”仅存在于历史 Change Log，不参与当前运行合同。
- 停止了占用本地 `node_modules` 的 Vite 会议 viewer 进程后完成依赖目录清理。

## 风险与边界

- 未做浏览器自动验收，按项目规则交由用户手动 Review。
- 历史 `pdoc/report` 未批量归档删除，保留审计线索；发布包同步脚本会排除 `pdoc`、`.local`、`agents` 与前端构建/依赖产物。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-15 | v1.30.0 | 发布前收束默认 discussion/text-first，并清理 viewer 本地垃圾产物 | Unclecow |
