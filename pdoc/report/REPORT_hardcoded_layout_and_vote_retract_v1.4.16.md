# REPORT_hardcoded_layout_and_vote_retract_v1.4.16

## 背景

用户在 Codex 内置浏览器中完成了最新座位、铭牌、投票按钮和投票手臂定位调整，需要将当前布局固化为 viewer 默认值；同时发现真实陪审团会议投票时，伸手测试能收回，但正式流程中手臂会直接消失。

## 修改内容

- 从 Codex 内置浏览器 Local Storage 的 `agency-agents-nameplate-calibration-v2` 读取当前最新布局记录，快照保存到 `pdoc/material/MAT_latest_localstorage_layout_extracted_v1.4.16.json`。
- `App.jsx` 默认布局已固定到当前浏览器记录：`nameplatePlacements`、`seatPlacements`、`voteButtonPlacements`、`voteArmPlacements` 与最新有效字段对齐。
- 修正真实会议投票手臂收回时序：`VOTE_REVEAL_DELAY_MS` 从 `1180ms` 调整为 `2450ms`，`VOTE_TURN_EXTRA_HOLD_MS` 从 `720ms` 调整为 `1700ms`，确保最长座位手臂动画完成“伸出、触碰、收回”后再退出 pending 投票态。

## 影响范围

- 仅影响陪审团投票节点的播放节奏与默认布局。
- 普通会议仍不展示投票按钮；仅在陪审团投票、伸手测试或投票相关校准目标下显示。
- 真实会议的按钮亮灯与票数稳定显示会比原先略慢，但避免手臂中途被状态切走。

## 复核

- 已执行 `npm run build`，Vite 构建通过。
- 视觉手感仍需用户在当前内置浏览器中 Review，重点看正式会议投票后的收手是否自然、等待时间是否过长。

