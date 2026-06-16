# REPORT_recorded_viewer_layout_v1.4.3

## 基本信息

- 日期：2026-05-28
- 版本：v1.4.3
- 负责人：Solazhu
- 范围：专家团 viewer 铭牌与投票按钮布局固化

## 修改内容

- 将当前浏览器中手工调好的铭牌坐标写回 `App.jsx` 的 `nameplatePlacements` 默认值。
- 将当前浏览器中手工调好的投票按钮坐标写回 `App.jsx` 的 `voteButtonPlacements` 默认值。
- 新增 `pdoc/material/MAT_viewer_layout_adjustment_v1.4.3.json`，独立保存本次布局快照。
- 记录采集方式：剪贴板复制被浏览器拒绝，`window.__agencyLayoutPlacements` 与 localStorage 未能作为数据源读取，因此以当前可视 DOM style 值作为固化依据。

## 复核要点

- 布局数据覆盖 host、left1-left5、right1-right5，共 11 个槽位。
- 投票按钮数据覆盖 host、left1-left5、right1-right5，共 11 个槽位。
- 投票按钮保留旋转后的下压方向补偿，不改变 A/B 选中状态逻辑。
- 本次只固化默认坐标和记录材料，不改会议流程、导航流程、投票计算与会话 JSON schema。

## 风险说明

- 若当前浏览器后续还存在未导出的 localStorage 覆盖值，页面显示可能优先使用覆盖值；默认值已按本次可视布局记录。
- 本次坐标来自当前视窗 DOM，可作为继续微调的基准，不代表最终视觉方案冻结。
