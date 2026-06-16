# REPORT_no_fallback_meeting_launch_v1.7.0

## 基本信息

- 日期：2026-05-28
- 版本：v1.7.0
- 负责人：Solazhu
- 范围：专家团 Function 1 会议启动失败处理、文本兜底禁止规则、脚本返回语义

## 修改内容

- `SKILL.md` 将会议启动规则改为 Hard Launch：会议页未确认打开时必须停止，不允许输出文字模拟会议、会议结论、实施方案或推荐员工。
- `SKILL.md` 禁止自动默认浏览器兜底；默认浏览器只允许在用户明确要求放弃 Codex 右侧浏览器路径时使用。
- `SKILL.md` 将 `new_visual_meeting_session.ps1 -Topic` 限定为开发 smoke test，不再作为正式用户会议的自动兜底路径。
- `start_expert_panel_meeting.ps1` 新增 `codexLaunchBlockedMessage`、`hardStartRequired = true`、`textFallbackAllowed = false`，用于让调用方在未确认浏览器打开时硬中断。
- `start_expert_panel_meeting.ps1` 在 `browserOpened = false` 时不再返回“会议正在进行中”，改为“会议页未确认打开”并明确禁止文字兜底。
- `GUIDE_专家团skill接手引导.md` 同步 v1.7.0 功能边界和当前流程。

## 影响范围

- 影响所有专家团 Function 1 可视化会议触发：启动失败时不会再转为聊天文字会议。
- 不改变 React viewer 播放逻辑和会议 JSON 结构。
- 不影响用户明确要求“文字讨论 / 不要网页 / 只要结论”时的非可视化处理，但该路径必须来自用户原始请求，不得由启动失败自动触发。

## 风险与防护

- 风险：右侧浏览器控件变化会导致会议更频繁地硬中断。
- 防护：脚本仍返回 `currentBrowserUrl` 与具体阻塞消息，便于定位浏览器侧栏或页面确认问题。
- 风险：模型可能试图把启动失败解释成会议已经完成。
- 防护：规则层明确 `textFallbackAllowed = false` 为硬停止信号，禁止输出结论和推荐员工。

## 复核结果

- PowerShell Parser 静态语法检查通过：`start_expert_panel_meeting.ps1`、`open_inapp_browser_url.ps1`。
- 需由用户进行产品侧验证：触发专家团后若右侧会议页未确认打开，应只看到启动阻塞消息，不应出现文字会议结论。
