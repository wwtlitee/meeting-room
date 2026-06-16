# REPORT_skill_trigger_bom_v1.0.0

## 基本信息

- 日期：2026-05-28
- 版本：v1.0.0
- 负责人：Solazhu
- 范围：`agency-agents` skill 触发失败排查与入口修复

## 问题现象

用户在其他项目中明确说“专家团开会”，Codex 没有唤起 `agency-agents` skill，也没有进入专家团会议模式选择流程。

## 根因判断

- 当前会话的可用 skill 列表中没有 `agency-agents`。
- `C:\Users\39215\.codex\skills\agency-agents\SKILL.md` 文件头部字节为 `EF BB BF 2D 2D 2D`，即 UTF-8 BOM 后才出现 YAML frontmatter 的 `---`。
- 已正常出现在 skill 列表中的 `adopt`、`awesome-design-md` 等入口文件均直接以 `2D 2D 2D` 开头，无 BOM。
- 因此判断 `agency-agents/SKILL.md` 的 BOM 会破坏或降低 Codex skill 索引对 frontmatter 的识别稳定性。

## 修复动作

1. `SKILL.md` 入口文件改为 UTF-8 无 BOM，作为 Codex skill frontmatter 入口的编码例外。
2. 强化 `description` 触发词，加入：专家团、专家团开会、开会、专家们开会、专家团会议、普通会议、圆桌会议、陪审团、陪审团会议、陪审模式、12怒汉、十二怒汉、多角色讨论、多智能体讨论。
3. 保留其他项目文件的 UTF-8 BOM 规则，只有 `SKILL.md` 入口例外。

## 风险与注意

- 当前对话中的可用 skill 列表是会话启动时注入的，修复后可能需要新开 Codex 会话或刷新技能索引后才能在其他项目立即生效。
- 后续批量格式化时，禁止把 `agency-agents/SKILL.md` 重新写回 BOM。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-28 | v1.0.0 | 记录专家团 skill 因 BOM 和触发描述不足导致跨项目唤起失败的修复 | Solazhu |
