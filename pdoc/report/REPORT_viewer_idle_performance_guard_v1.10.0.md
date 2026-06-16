# REPORT_viewer_idle_performance_guard_v1.10.0

## 背景

用户反馈 Codex 右侧会议网页长期开着后会导致卡顿，关闭网页后卡顿消失。

## 排查结论

- `DotGrid` 背景组件在页面存在期间持续 `requestAnimationFrame` 重绘 canvas，即使会议已经结束也不停。
- `LetterGlitch` 大屏装饰组件每 180ms 更新一次 108-180 个字符，持续触发 React state 更新。
- CSS 中眨眼、说话嘴型和光标闪烁为无限动画，会议结束后仍会继续运行。
- `current-session.json` 轮询固定 1 秒一次，页面空闲时仍持续请求。

## 修复

- `DotGrid` 新增 `active` 参数；空闲时只绘制静态背景，不再持续 RAF，也不挂鼠标监听。
- `LetterGlitch` 新增 `active` 参数；空闲时停止 interval，并通过 `data-active=false` 关闭 CSS 扫描和抖动动画。
- App 增加页面可见性检测；会议播放中保持动态效果，会议结束/暂停/页面隐藏时进入降载模式。
- session 轮询分档：播放中 1s、结束空闲 10s、页面隐藏 30s。
- `app-shell[data-motion=false]` 统一关闭光标、眨眼和说话嘴型无限动画。

## 复核

- `npm run build` 通过。
- `start_expert_panel_meeting.ps1` PowerShell Parser 语法检查通过。

## 风险

- 会议结束后若只依赖轮询自动切换新 session，最多可能延迟 10 秒；正常脚本导航带 `reload` 参数，实际启动新会议不受影响。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.10.0 | 增加会议 viewer 空闲降载，降低长期开启造成的持续动画和轮询开销 | Solazhu |
