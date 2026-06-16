# REPORT_jury_moderator_flow_v1.4.4

## 基本信息

- 日期：2026-05-28
- 版本：v1.4.4
- 负责人：Solazhu
- 范围：陪审团会议主持人控场流程、投票亮灯时序、当前调试会议样例

## 修改内容

- 将 viewer 投票状态拆成三段：主持人读题阶段双暗、主持人投票 turn 读完后伸手投票、触碰后亮起本轮结果。
- 复用既有 `seat-vote-hand` 动画，不重做动效资产；伸手动作保留在原来的席位/铭牌坐标体系，避免跟随投票按钮旋转后变形。
- 当前 `current-session.json` 改为主持人 Q 流程：
  - `opening`：主持人读主题和 A/B，按钮双暗。
  - `host-vote-1`：主持人宣布第一轮投票。
  - `host-r1-start`：主持人宣布第一轮发言。
  - `host-vote-2`：主持人宣布第二轮投票。
  - `host-r2-start`：主持人宣布第二轮发言。
  - `host-vote-3`：主持人宣布第三轮投票；全票后进入总结。
- 当前调试会议 `id` 升级为 `vote-ui-alternative-jury-flow-v144-20260528`，保证已打开的 viewer 能通过轮询识别为新会议并转场。
- 更新 `SKILL.md`、`NATURAL_MEETING_DIALOGUE_RULES.md`、`VISUAL_TRANSCRIPT_SCHEMA.md`，要求陪审团投票轮只能挂在主持人投票控场 turn 上。

## 逻辑复核

- `deliberation.voteRounds[].afterTurnId` 均指向 `host-vote-*`，不再指向专家发言。
- 第一条主持人读题时没有可见票，投票按钮保持双暗。
- 主持人投票 turn 结束后才产生 pending vote，触发伸手动画和按钮按下反馈。
- `seat-vote-hand` 不再作为 `.seat-vote-buttons` 子元素渲染，按钮只负责双暗、pending 按下和亮灯状态。
- 本轮结果 reveal 后才进入稳定亮灯状态，下一条主持人/专家发言继承最近一轮投票结果。
- 普通会议没有 `deliberation.voteRounds` 时不进入陪审团投票状态机。

## 验证

- `current-session.json` 解析通过。
- `npm run build` 通过。
- 代码检查确认不存在 `.seat-vote-buttons .seat-vote-hand` 规则，伸手动画只使用 `.seat-nameplate ... .seat-vote-hand` 既有路径。
