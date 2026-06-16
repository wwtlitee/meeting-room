# REPORT_screen_title_compression_v1.13.4

## 背景

会议大屏顶部标题空间足够，但原逻辑使用 `truncateChars` 主动追加 `…`，CSS 又设置 `text-overflow: ellipsis`，导致标题显示为 `UTF-8 到底是有 BOM ...`。

## 修复

- `SCREEN_TOPIC_MAX_CHARS` 调整为 15。
- 新增标题压缩逻辑，标题过长时生成短标题，不追加省略号。
- UTF-8/BOM 议题压缩为 `UTF-8 BOM取舍`。
- `.meeting-screen h2` 扩大可用宽度，移除标题层 `text-overflow: ellipsis`。

## 复核

- `npm run build` 通过。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-29 | v1.13.4 | 会议大屏标题主动压缩到 15 字以内并禁止省略号显示 | Solazhu |
