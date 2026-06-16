# REPORT_jury_fixed_state_machine_v1.13.3

## 背景

用户明确要求陪审团会议不能只靠写稿自觉，必须固化为主持人控场状态机：主持人读题、引导投票、公布票数并引导发言、陪审发言、下一轮投票，直到某轮全票统一后由主持人总结。

## 修复

- `SKILL.md` 写入固定状态机：
  - `opening`
  - `host-vote-1`
  - `host-r1-start`
  - 陪审员 `speak`
  - `host-vote-2`
  - `host-r2-start`
  - 陪审员 `speak`
  - 循环到全票统一的 `host-vote-N`
  - `host-final`
- `references/NATURAL_MEETING_DIALOGUE_RULES.md` 写入同一节奏，禁止把流程交给专家自行推进。
- `references/VISUAL_TRANSCRIPT_SCHEMA.md` 对齐 `host-rN-start` 命名和最终 `host-final`。
- `start_expert_panel_meeting.ps1` 的 `Test-JurySessionContract` 增加完整状态机校验：
  - 第一轮投票必须紧跟开题。
  - 每轮投票必须用 `afterTurnId = host-vote-N`。
  - 非全票轮后必须紧跟 `host-rN-start`。
  - `host-rN-start` 到下一轮投票之间只能是陪审员 `speak`。
  - 最终轮必须全票统一，并直接进入 `host-final`。
- `test_meeting_trigger_contract.ps1` 增加当前 session 的固定序列回归检查。
- UTF-8/BOM 当前会议改为三轮投票样例，第三轮 5:0 后由主持人总结。

## 复核

- 本地 PowerShell Parser 检查通过。
- 本地会议触发契约测试通过。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.13.3 | 陪审团会议流程升级为启动前强校验的固定状态机 | Solazhu |
