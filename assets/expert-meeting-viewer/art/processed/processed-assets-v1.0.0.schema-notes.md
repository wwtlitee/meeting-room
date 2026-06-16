# processed-assets-v1.0.0.schema-notes

## 基本信息

- 项目：expert-meeting-viewer
- 素材包版本：v1.0.0
- 负责人：Solazhu
- 文件性质：processed 素材包结构说明，不替代既有 manifest，不参与运行时自动加载。
- 目标：锁定“黑色牛专家剪影 + 白色办公桌椅 + 小色块席位/身份标识”的图中素材方向，并为后续 processed SVG 素材进入 PNG/WebP 生产链路提供命名与交付约束。

## 素材方向锁定

- 场景方向：白色办公室/会议室基底，纵向长桌构图，桌椅与遮挡层清晰分离，便于按座位独立组合。
- 角色方向：统一黑色牛专家剪影，不为每个专家单独创建完全不同的身体模型。
- 差异表达：角色差异通过座位方向、体型比例、小色块徽章/席位标识表达，避免把可变文字直接烘焙进角色主体。
- 资产组织：房间、桌面、遮挡层、坐姿复合角色、最小组合预览必须可独立替换。
- 运行策略：当前 processed SVG 作为第一阶段可编辑源资产；后续 PNG/WebP 是发布与运行时优化格式。

## 目录结构建议

```text
art/processed/
├── processed-assets-v1.0.0.schema-notes.md
├── processed-assets-v1.0.0.json
├── assembly/
│   └── minimal-meeting-assembled-v1.0.0.svg
├── furniture/
│   ├── room-empty-v1.0.0.svg
│   ├── table-long-vertical-v1.0.0.svg
│   ├── table-occluder-left-v1.0.0.svg
│   ├── table-occluder-right-v1.0.0.svg
│   └── table-occluder-bottom-v1.0.0.svg
├── characters/
│   └── seated/
│       └── cow-{body}-seated-{direction}-v1.0.0.svg
├── png/
│   ├── assembly/
│   ├── furniture/
│   └── characters/
│       └── seated/
├── webp/
│   ├── assembly/
│   ├── furniture/
│   └── characters/
│       └── seated/
└── source-map/
    └── processed-source-map-v1.0.0.md
```

说明：本次只新增 schema notes 文件；现有 SVG 与 `processed-assets-v1.0.0.json` 不在本次修改范围。`png/`、`webp/` 与 `source-map/` 是后续位图化时的目标结构，避免当前任务与既有 manifest 或运行时代码冲突。

## 应包含文件

### 已有源素材层

| 文件名 | 建议尺寸 | 格式 | 用途 |
| :--- | :--- | :--- | :--- |
| `processed-assets-v1.0.0.json` | 不适用 | JSON | 现有 processed 素材包 manifest，仅用于登记当前 SVG 源资产，不在本次改动范围。 |
| `assembly/minimal-meeting-assembled-v1.0.0.svg` | 按源文件 | SVG | 最小会议组合预览，用于检查房间、桌面、遮挡层与入座复合体的层级关系。 |
| `furniture/room-empty-v1.0.0.svg` | 按源文件 | SVG | 空白会议室/办公室基底。 |
| `furniture/table-long-vertical-v1.0.0.svg` | 按源文件 | SVG | 纵向白色长桌主体。 |
| `furniture/table-occluder-left-v1.0.0.svg` | 按源文件 | SVG | 左侧桌缘遮挡层。 |
| `furniture/table-occluder-right-v1.0.0.svg` | 按源文件 | SVG | 右侧桌缘遮挡层。 |
| `furniture/table-occluder-bottom-v1.0.0.svg` | 按源文件 | SVG | 近景底部桌缘遮挡层。 |
| `characters/seated/cow-{body}-seated-{direction}-v1.0.0.svg` | 按源文件 | SVG | 黑色牛剪影 + 白色座椅的入座复合体源资产。 |

### PNG 母版层

| 文件名 | 建议尺寸 | 格式 | 用途 |
| :--- | :--- | :--- | :--- |
| `png/assembly/minimal-meeting-assembled-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 组合预览母版，用于人工验收素材方向。 |
| `png/furniture/room-empty-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 空房间母版。 |
| `png/furniture/table-long-vertical-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 长桌母版。 |
| `png/furniture/table-occluder-left-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 左侧遮挡母版。 |
| `png/furniture/table-occluder-right-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 右侧遮挡母版。 |
| `png/furniture/table-occluder-bottom-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 底部遮挡母版。 |
| `png/characters/seated/cow-{body}-seated-{direction}-v1.0.0.png` | 与 SVG 视口一致或 2x | PNG | 入座复合体母版，保留透明背景与小色块标识。 |

### WebP 发布层

| 文件名 | 建议尺寸 | 格式 | 用途 |
| :--- | :--- | :--- | :--- |
| `webp/assembly/minimal-meeting-assembled-v1.0.0.webp` | 同 PNG | WebP | 组合预览轻量版本。 |
| `webp/furniture/room-empty-v1.0.0.webp` | 同 PNG | WebP | 空房间运行时版本。 |
| `webp/furniture/table-long-vertical-v1.0.0.webp` | 同 PNG | WebP | 长桌运行时版本。 |
| `webp/furniture/table-occluder-left-v1.0.0.webp` | 同 PNG | WebP | 左侧遮挡运行时版本。 |
| `webp/furniture/table-occluder-right-v1.0.0.webp` | 同 PNG | WebP | 右侧遮挡运行时版本。 |
| `webp/furniture/table-occluder-bottom-v1.0.0.webp` | 同 PNG | WebP | 底部遮挡运行时版本。 |
| `webp/characters/seated/cow-{body}-seated-{direction}-v1.0.0.webp` | 同 PNG | WebP | 入座复合体运行时版本。 |

### 可选扩展层

| 文件名 | 建议尺寸 | 格式 | 用途 |
| :--- | :--- | :--- | :--- |
| `source-map/processed-source-map-v1.0.0.md` | 不适用 | Markdown | 记录 SVG 到 PNG/WebP 的导出参数、工具版本、裁切策略和人工修正记录。 |
| `png/characters/seated/cow-{body}-seated-{direction}-v1.0.0@2x.png` | 2x | PNG | 高清母版，可选。 |
| `webp/characters/seated/cow-{body}-seated-{direction}-v1.0.0@2x.webp` | 2x | WebP | 高清发布版本，可选。 |

变量约束：`body` 只能取 `standard/round/tall/small/sturdy`；`direction` 只能取 `left/right/host`。

## 命名规则

- 文件名统一小写，沿用当前 processed 包的连字符命名方式。
- 版本段统一使用 `v1.0.0`，与现有 processed SVG 和 manifest 对齐。
- PNG 与 WebP 必须同名同层级镜像，只替换扩展名。
- 同一素材在 SVG、PNG、WebP 三种格式下必须保持同一主体文件名。
- 源 SVG 若参与加工，必须在 `source-map/processed-source-map-v1.0.0.md` 记录来源文件、导出尺寸、裁切方式和人工修正项。

## SVG 到 PNG/WebP 的后续流程

1. 盘点 `art/processed/**/*.svg`，以现有 processed SVG 作为第一阶段可编辑源资产。
2. 读取每个 SVG 的 `viewBox`，按原视口或 2x 尺寸导出 PNG，禁止导出时自动裁掉透明边界，避免锚点漂移。
3. 对透明背景素材保留 alpha 通道；对白色房间/桌椅素材检查边缘是否被白底吞掉。
4. 将 PNG 母版保存到 `processed/png/` 的镜像目录，文件名主体与 SVG 完全一致。
5. 从 PNG 母版批量导出 WebP 到 `processed/webp/` 的镜像目录，不直接从 SVG 跳过 PNG 母版。
6. 导出 WebP 时检查 alpha 通道、黑色剪影边缘抗锯齿、小色块识别度、白色桌椅层次和缩放清晰度。
7. 用 `assembly/minimal-meeting-assembled-v1.0.0.svg` 对照 PNG/WebP 组合预览，确认层级、遮挡、席位方向没有错位。
8. 只有在 PNG/WebP 完成并通过人工预览后，才考虑由后续任务更新正式运行 manifest。

## 质量门槛

- 不把全部角色烘焙进单张会议室整图；角色、桌面、遮挡层必须保留独立替换能力。
- 保持当前图中“黑色牛剪影 + 白色办公家具 + 小色块标识”的方向，不额外扩展成高饱和卡通角色。
- 不让每个专家绑定唯一身体模型；五种基础体必须可复用。
- 不在素材中烘焙姓名、职位或可变文本。
- 所有可运行资产必须有 PNG 母版，WebP 只作为发布优化格式。
- 所有角色与遮挡素材必须保留透明背景，并遵循现有锚点和遮挡层思路。

## 本次交付边界

- 已定义 processed 素材包应包含的文件、命名、用途和 SVG 到 PNG/WebP 的后续生产流程。
- 未修改 JS、CSS、HTML。
- 未修改既有 manifest。
- 未生成实际 PNG/WebP 文件；本文件仅锁定后续素材包 schema 与生产约束。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-26 | v1.0.0 | 新增 processed 素材包 schema notes，锁定素材方向、文件清单、命名规则与 SVG 到 PNG/WebP 流程。 | Solazhu |
