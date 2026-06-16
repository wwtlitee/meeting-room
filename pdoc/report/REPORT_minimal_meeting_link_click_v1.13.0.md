# REPORT_minimal_meeting_link_click_v1.13.0

## 背景

用户确认点击 Codex 消息里的 `[打开会议页](currentBrowserUrl)` 链接即可触发 Codex 内置网页预览/侧栏打开流程。原先自动化尝试寻找侧栏、URL 输入框、浏览器控件和页面文本，路径过长且容易误判。

## 修复

- 删除 `scripts/open_inapp_browser_url.ps1`。
- 新增 `scripts/click_latest_meeting_link.ps1`。
- `start_expert_panel_meeting.ps1` 不再包含 `-UseInAppAutomation`、`-UseLegacyInAppAutomation`、`-OpenDefaultBrowserAfterInAppFailure`。
- `start_expert_panel_meeting.ps1` 返回 `autoClickLinkText = 打开会议页` 和 `autoClickScript = scripts/click_latest_meeting_link.ps1`。
- 自动打开会议页时，必须在消息渲染后调用 `click_latest_meeting_link.ps1`，寻找最新可见的 `打开会议页` 链接并 Invoke；失败才停留给用户手点。

## 禁止项

- 不再找右侧栏。
- 不再找 URL 输入框。
- 不再模拟输入 URL。
- 不再用页面文字或聊天输出区文字判断会议页是否已打开。
- 不再自动打开系统默认浏览器。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.13.1 | 将会议链接自动点击从可选改为输出文案后的强制步骤，失败才由用户手点 | Solazhu |
| 2026-05-29 | v1.13.0 | 删除旧侧栏/URL 输入自动化，新增最小点击打开会议页链接脚本 | Solazhu |
