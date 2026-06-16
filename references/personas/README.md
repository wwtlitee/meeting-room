# Personas Store

本目录是 `agency-agents` 的轻量人格资料层。每个角色按 `division/slug` 拥有独立资料目录，避免所有知识和记忆写入单个巨大文件。

## 读取入口

- 角色行为入口：`../roles/<division>/<slug>.md` - v1.0.0
- 人格稳定档案：`<division>/<slug>/profile.md` - v1.0.0
- 专业学习资料：`<division>/<slug>/knowledge.md` - v1.0.0
- 近期原始记忆：`<division>/<slug>/memory.md` - v1.0.0
- 长期压缩摘要：`<division>/<slug>/memory_summary.md` - v1.0.0

## 使用规则

- 先读角色卡，再读 `profile.md` 与 `memory_summary.md` - v1.0.0
- 只有任务需要专业深度时才读 `knowledge.md` - v1.0.0
- 只有需要追溯近期上下文时才读 `memory.md` - v1.0.0
- 每个 `memory.md` 默认保留最近 12 条原始记录，旧记录压缩到 `memory_summary.md` - v1.0.0

## 维护脚本

- 初始化或补齐目录：`../../scripts/init_persona_stores.ps1` - v1.0.0
- 压缩近期记忆：`../../scripts/compact_persona_memory.ps1` - v1.0.0

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-27 | v1.0.0 | 初始化 260 个角色的独立人格资料层 | Solazhu |
