# REPORT_clickable_link_launch_v1.12.0

## 背景

自动展开 Codex 右侧浏览器依赖 UIAutomation 扫描控件，容易把聊天输出区或网页预览卡片误判成真实会议页。用户确认点击 Markdown 链接即可打开内置网页预览/会议页，因此默认路径应收束为可点击链接。

## 决策

- 默认启动流程只负责准备 viewer、校验 `current-session.json` 的会议 `id` 与本次 session 一致。
- 成功后输出固定会议状态和 Markdown 链接：`[打开会议页](currentBrowserUrl)`。
- 不再默认调用 `open_inapp_browser_url.ps1`。
- `open_inapp_browser_url.ps1` 仅作为显式 `-UseInAppAutomation` 调试路径保留，不作为成功条件。
- `browserOpened=false` 不再表示默认启动失败；`servedSession.matches=false` 才是硬失败。

## 用户侧格式

```markdown
会议主题：<topic>
参会人员：<participants>

会议正在进行中

[打开会议页](<currentBrowserUrl>)（点击进入会议）
```

## 复核要点

- `start_expert_panel_meeting.ps1` 默认 `browserOpenStrategy = clickable_link`。
- `codexMessage` 在 `servedSession.matches = true` 时输出 start message，不再依赖 `browserOpened=true`。
- `scripts/test_meeting_trigger_contract.ps1` 检查默认链接路径和 `-UseInAppAutomation` 显式开关。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.12.0 | 将会议打开方式收束为可点击链接主路径，停止默认 UIAutomation 自动拉起 | Solazhu |
