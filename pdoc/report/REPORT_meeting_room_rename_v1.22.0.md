# REPORT_meeting_room_rename_v1.22.0

## 背景

用户确认 skill 对外英文名改为 `meeting room`，机器 slug 使用 `meeting-room`，中文名统一为“会议室”。本次同步更新触发合同、网页左上角品牌、同步脚本和全局 skill 目录。

## 修改范围

- `SKILL.md`：frontmatter `name` 改为 `meeting-room`，固定触发句改为 `会议室 skill已触发～喵`。
- `AGENTS.md`：会议触发规则改为使用全局 `meeting-room` skill。
- React viewer：左上角品牌改为 `会议室`，英文 eyebrow 改为 `Meeting Room`，标记改为 `会`。
- 同步脚本：新增 `sync_meeting_room_to_global.ps1`，目标目录改为 `C:\Users\39215\.codex\skills\meeting-room`。
- `scripts/test_meeting_trigger_contract.ps1`：回归合同改为检查 `meeting-room`、新触发句和新全局 skill 规则。
- runtime generator 字段：从 `agency-agents/...` 改为 `meeting-room/...`。

## 影子评审

- 防止旧 skill 名复活：静态回归检查要求 `SKILL.md` frontmatter 为 `meeting-room`。
- 防止触发句错位：回归检查要求 `SKILL.md` 与工作区 `AGENTS.md` 同时包含 `会议室 skill已触发～喵`。
- 防止全局目录未同步：全局同步目标改为 `meeting-room`，后续需移除旧 `agency-agents` 全局目录。
- 防止 UI 漏改：viewer 左上角不再显示 `Agency Agents Live Meeting` 或 `专家团可视化会议`。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.22.0 | skill 对外命名改为 meeting-room / 会议室 | Unclecow |
