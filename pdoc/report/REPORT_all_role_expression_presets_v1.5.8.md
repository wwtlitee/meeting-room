# REPORT_all_role_expression_presets_v1.5.8

## 背景

用户要求给全部 260 个“人格部门”预设表情，避免只有常用角色有明确表情、其他角色走默认 `dot + flat`。

## 修改内容

- 新增 `assets/expert-meeting-viewer/react-viewer/src/roleExpressionProfiles.generated.js`：
  - 从 `references/roles_manifest.json` 生成 260 条 role slug 到表情组合的静态映射。
  - 当前覆盖 manifest 中全部 260 个角色，缺失数为 0。
  - 使用 15 类眼睛/嘴巴组合，按部门 palette 与 slug/name 关键词规则分配。
- 更新 `App.jsx`：
  - 引入 `generatedRoleExpressionProfiles`。
  - `roleExpressionProfiles` 先铺入全量生成表，再保留历史调试 session 用过的少量手工 override。
- 新增 `scripts/generate_role_expression_profiles.ps1`：
  - 后续更新 `roles_manifest.json` 后可重新生成全量表。
  - 关键词只匹配 `slug + name`，不扫 description，避免 `ui` 等短词误命中普通英文片段。

## 复核

- `roles_manifest.json`：`role_count = 260`。
- 生成文件：`GeneratedSlugLines = 260`，`Missing = 0`。
- `npm run build` 已在 `E:\AI\会议室\agency-agents` 工作副本通过。

## 风险

- 260 个部门不可能在现有 9 种眼睛和 7 种嘴型下全部唯一；本版目标是“每个部门都有稳定预设”，不是“每个部门都视觉唯一”。
- 后续如果继续增加眼睛、嘴型、眉毛或配饰，可复用生成脚本扩大组合池。
