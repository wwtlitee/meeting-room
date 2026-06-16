# REPORT_browser_sidebar_and_public_wording_v1.6.0

## 基本信息

- 日期：2026-05-28
- 版本：v1.6.0
- 负责人：Solazhu
- 范围：专家团 skill 用户侧话术防泄露、Codex 右侧浏览器侧栏展开、会议页导航确认语义

## 修改内容

- `SKILL.md` 新增 User-Visible Language Guard：Codex 聊天侧不得暴露 `SCRIPT_*`、会议数据、剧本、session JSON、`visualTranscript`、内部 A/B 标记等后台制作话术。
- `start_expert_panel_meeting.ps1` 默认尝试调用 `open_inapp_browser_url.ps1` 展开/选择当前 Codex 右侧浏览器；`browserOpened` 只在实际确认页面后为 true。
- `start_expert_panel_meeting.ps1` 增加用户侧文本净化，阻止 `<SCRIPT_*>`、`current-session.json`、`visualTranscript` 等内部字段进入 `codexStartMessage` / `codexFinalMessage`。
- `open_inapp_browser_url.ps1` 增加侧栏状态处理：先检查浏览器 URL 框；侧栏可见时优先按控件名选择 Browser / Expert Meeting React Viewer；侧栏疑似收起时再发送 `Ctrl+Alt+B`；最后仍以页面文本或 URL 匹配确认成功。
- `new_visual_meeting_session.ps1` 删除 fallback 文案中的“生成会议数据”等用户侧不友好描述，改为“准备会议内容”。
- `GUIDE_专家团skill接手引导.md` 更新当前启动策略、话术边界和 v1.6.0 Change Log。

## 影响范围

- 影响专家团会议启动脚本的默认行为：会主动尝试当前 Codex 右侧浏览器自动化；如自动化失败，不再伪装为已打开，而是返回 URL 和未确认提示。
- 影响 Codex 聊天侧可见文案：会议运行中只呈现主题、参会人员、会议状态和 URL；内部制作字段只保留在脚本/文档层。
- 不改变 React viewer 的会议播放结构和已有 session 数据兼容性。

## 风险与防护

- UI Automation 仍依赖 Codex 桌面控件名称与快捷键；若客户端控件名变化，脚本会返回 `browserOpened = false` 并保留 URL 兜底。
- `Ctrl+Alt+B` 只在未检测到右侧浏览器 URL 框时使用，避免已展开时被反向收起。
- 页面确认仍以本次会议主题或目标地址为准，避免仅点击输出卡片或侧栏按钮就误报成功。

## 复核结果

- PowerShell 脚本 Parser 静态语法检查通过：`start_expert_panel_meeting.ps1`、`open_inapp_browser_url.ps1`、`new_visual_meeting_session.ps1`。
- 前端 React viewer 本次未改动播放逻辑；需用户按产品侧流程最终测试右侧浏览器是否自动展开并切入会议页。
