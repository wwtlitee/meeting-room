# REPORT_expression_diversity_expansion_v1.5.6

## 背景

用户确认不再推进随机换座：人格不代表固定个人，而是代表部门；参会者是该部门派出的一个人，所以同一部门在不同固定体型席位上出现可以成立。本次改动据此落实表情多样化，避免继续增加座位与体型绑定复杂度。

## 修改内容

- 撤回未完成的随机换座实验痕迹：
  - 移除 session `seatShuffle` 字段归一化。
  - 移除确定性随机种子与专家顺序 shuffle 逻辑。
  - `getMeetingSeatsForParticipants` 恢复为按参会者顺序填入固定席位。
- 扩展 `FaceOverlay` 表情库：
  - 眼睛从默认 dot 扩展为 dot / round / half / focus / surprised / tired / wide / narrow / bean。
  - 嘴型从 flat / smile / soft / firm / open 扩展为 flat / smile / soft / firm / open / small-o / long。
  - 除 half / tired / narrow 这类眯眼外，其他眼睛形态保持眨眼动画。
- 更新角色到表情的稳定映射：
  - 产品/制作类更开放，使用 wide + flat。
  - 工程/技术类更聚焦，使用 focus + long。
  - 评审/QA 类更锐利，使用 narrow + firm。
  - 创意/美术类保持 round / wide + smile。
  - 动效/游戏感类使用 surprised + small-o。
- 更新 Guide：明确“人格=部门气质，不是固定个人”，不再推进随机换座作为当前方案。

## 复核要点

- 固定席位逻辑不再读取 `seatShuffle`，避免体型、手臂、按钮、铭牌校准被随机顺序破坏。
- 新表情只使用白色剪影上层形状，不引入常态彩色眼睛，避免破坏全黑牛牛剪影风格。
- 非眯眼 variant 继续继承 `blink` 动画；眯眼类保持静态，避免细眼被压扁后闪烁突兀。
- 嘴型继续复用现有说话开合变量，不改变发言动画调用链。

## 风险

- 表情差异属于低成本视觉分化，仍不会解决“同一部门固定长相”的全部拟人化问题；但当前业务解释已经把人格收束为部门代表，风险可接受。
- 具体美感仍需用户在浏览器里肉眼 Review，尤其是 narrow / bean / small-o 在不同体型头部上的比例。
