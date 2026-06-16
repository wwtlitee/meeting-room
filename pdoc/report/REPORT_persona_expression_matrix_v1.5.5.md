# REPORT_persona_expression_matrix_v1.5.5

## 背景

根据“牛牛人格区分陪审会”的结论，第一版人格差异采用 A 方案：在 `FaceOverlay` 上层扩展眼睛和嘴巴变体，通过角色气质映射组合人格，不改牛牛主体剪影、体型和座位模型。

## 修改内容

- 新增 `roleExpressionProfiles`：
  - 精确覆盖当前常用角色，如 UI 设计师、设计系统架构师、游戏素材美术、图标设计师、动效导演、心理学家、前端工程师、视觉走查 QA、产品经理。
  - 增加 pattern fallback，未知角色可按 `designer / engineer / qa / manager / architect` 等关键词得到默认气质表情。
- `FaceOverlay` 增加：
  - `roleId` 和 `expressionProfile` 输入。
  - `data-eye-variant` 与 `data-mouth-variant` 输出到 DOM。
- CSS 增加 5 类眼睛变体：
  - `dot` 默认点眼。
  - `round` 圆润友好。
  - `half` 半眯审慎。
  - `focus` 专注硬朗。
  - `surprised` 张大眼，适合动效/创意类角色。
- CSS 增加 4 类嘴巴变体：
  - `flat` 中性平线。
  - `smile` 轻微友好。
  - `soft` 克制柔和。
  - `firm` 下压/严肃。
- 发言状态继续使用 `mouthTalk`，但改为读取每个嘴型自己的开合尺寸变量，避免所有角色说话时完全变成同一张嘴。

## 影响范围

- 仅影响最上层眼睛和嘴巴绘制。
- 不影响牛牛剪影素材、体型、座位、铭牌、投票按钮、投票手臂和会议流程。

## 复核

- 已执行 `npm run build`，Vite 构建通过。
- 视觉仍需人工确认：默认视距下不同人格是否能明显区分，且发言嘴型是否自然。

