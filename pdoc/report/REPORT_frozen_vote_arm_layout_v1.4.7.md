# REPORT_固化投票手臂布局_v1.4.7

## 变更摘要

- 从 Codex 内置浏览器 Local Storage 提取最新 `agency-agents-nameplate-calibration-v2` 布局，固化为 viewer 默认布局。
- 新增 `seatPlacements` 默认座位左右偏移，清空浏览器调试覆盖后也会回到本次人工调整的位置。
- 将投票手臂长度改为按“肩膀锚点 -> 投票目标”实时计算，长度上限从 190 放宽到 360，避免远座位手臂被截短。
- 修复 `伸手测试 A / 伸手测试 B` 只点亮按钮但不一定驱动手臂的问题，测试态会把当前 A/B 方向传给旋转手臂。
- 增强 `stage-vote-arm` 柔和三角可见性：提高默认透明度、增加高光层，并将层级放在桌面上方、座椅头部下方。

## 固化坐标

- 座位：`left1=432`、`right1=689`、`left2=423`、`right2=694`、`left3=416`、`right3=702`、`left4=411`。
- 手臂：保留用户已调好的 `left1/right1/left2` 初始手位、`right1/right4` 投票手位，其余席位默认投向按钮中心。
- 快照：`pdoc/material/MAT_viewer_arm_layout_v1.4.7.json`。

## 复核

- 已执行 `npm run build`，Vite 构建通过。
- 未做自动浏览器验收；按项目约定，视觉测试交给用户在 Codex 内置浏览器手动 Review。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-28 | v1.4.7 | 固化当前座位/按钮/铭牌布局，按肩膀到按钮距离自动计算旋转手臂长度，并增强手臂模型可见性 | Solazhu |
