# REPORT_牛牛剪影素材替换_v1.4.9

## 变更摘要

- 批量生成 15 张座位牛牛剪影素材与 15 张头部剪影素材，输出到 `art/imagegen/extracted/*-silhouette/`。
- `meetingSceneData.js` 已切换为读取剪影版底层座位图与头部遮挡图。
- 保留现有 `FaceOverlay`，眼睛与嘴巴仍然在最上层绘制，不参与剪影压黑。
- 投票手臂改为纯黑细圆臂，层级在黑色牛牛上方、铭牌/按钮/脸部覆盖层下方。

## 实现说明

- 未调用 imagegen API：本机未设置 `OPENAI_API_KEY`，且重绘素材存在坐标漂移风险。
- 使用 `pdoc/script/SCRIPT_generate_cow_silhouettes_v1.4.9.py` 基于原 PNG 深色区域生成剪影，保留白色椅子、透明边界和原始尺寸。

## 复核

- 已执行 `npm run build`，Vite 构建通过。
- 构建产物中已包含 30 张剪影 PNG。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-28 | v1.4.9 | 生成并接入牛牛全黑剪影素材，保留脸部覆盖层，重做纯黑卡通投票手臂 | Solazhu |
