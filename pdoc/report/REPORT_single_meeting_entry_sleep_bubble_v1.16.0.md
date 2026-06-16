# REPORT_single_meeting_entry_sleep_bubble_v1.16.0

## 背景

本次修正两类偏差：用户侧仍出现“普通会议 / 陪审团会议”二选一入口；viewer 已有睡觉鼻涕泡素材与组件，但真实 `zzz` 睡觉状态没有渲染鼻涕泡。

## 修改范围

- `SKILL.md`：收束为唯一会议入口，禁止再询问普通/陪审团二选一；陪审团只作为内部讨论/投票机制，轻度/深度只作为运行深度。
- `AGENTS.md`：同步唯一会议入口补充规则，固定触发句后直接进入会议流程。
- `scripts/start_expert_panel_meeting.ps1`、`runtime/run_live_meeting.ps1` 与 `scripts/new_visual_meeting_session.ps1`：删除 `roundtable` 参数模式，默认且唯一 `Mode` 为 `jury_deliberation`，并让默认路径继续走轻度 live runtime。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：会话/历史 fallback 从 `roundtable` 改为 `jury_deliberation`。
- `scripts/test_meeting_trigger_contract.ps1`：新增单一会议入口、旧模式提示禁用、启动默认轻度陪审团 live、roundtable 功能链路删除的静态检查。
- `assets/expert-meeting-viewer/react-viewer/src/App.jsx`：`ambientState === 'zzz'` 时显示 `AmbientSleepBubble`，保留调试态全量显示能力。
- `pdoc/design/DESIGN_专家团skill流程收束_v1.1.0.md`、`pdoc/guide/GUIDE_专家团skill接手引导.md` 与 `pdoc/rule/RULE_meeting_trigger_contract_v1.0.0.md`：同步入口规则和可维护说明。
- `pdoc/design/DESIGN_live_meeting_runtime_v1.0.0.md`：删除普通/圆桌会议设计分支，明确唯一会议形态为轻度陪审团 live。
- `pdoc/archive/report/REPORT_light_roundtable_live_runtime_v1.1.0.md`：归档旧 roundtable live runtime 报告，避免继续作为活跃实现依据。

## 影子评审

- 避免把“陪审团”从触发词中删除：用户仍可能用陪审团表达投票式讨论，正确处理方式是作为内部机制自动选择，而不是用户入口层二选一。
- 避免把“单一入口”误解成自然圆桌：启动脚本默认必须是 `jury_deliberation`，否则大屏 A/B 选项会消失。
- 防止旧链路复活：`roundtable` 不再是合法脚本参数，也不再是前端缺省 mode。
- 鼻涕泡只绑定 `zzz` 与调试态，不影响 `phone`、`thinking`、`nod`、`reserve` 等其他氛围状态。
- 保留 `jury_deliberation` 结构校验，防止内部投票机制被误删导致陪审流程退化。
- 大屏 A/B 选项由 `deliberation.labelA`、`deliberation.labelB` 和 `voteRounds` 保证；会话生成烟测已确认这些字段存在。

## 后续验证要点

- 触发“开个会”时不得再询问“请选择会议模式”。
- 默认会议应进入轻度陪审团 live runtime，并输出可点击会议页链接，大屏显示 A/B 选项。
- 后五席中 `ambientState: "zzz"` 的角色应同时出现 `zzz` 文本和睡觉鼻涕泡。
- 用户显式说“12怒汉 / 陪审模式 / 方案 PK”时，应进入内部投票机制，而不是展示第二个会议入口。

## 本次复核

- `scripts/test_meeting_trigger_contract.ps1` 本地通过，包含 `roundtable-chain-removed`。
- `npm run build` 通过，构建产物包含 `sleep-bubble` 资源。
- 已同步到 `C:\Users\39215\.codex\skills\agency-agents`，全局合同检查通过。
- 临时会话生成烟测通过：`mode=jury_deliberation`，`deliberation.enabled=true`，A/B 标签与投票轮存在。

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-05-31 | v1.18.0 | 归档旧 roundtable runtime 报告，补充全局同步与 A/B 烟测复核 | Unclecow |
| 2026-05-31 | v1.17.0 | 删除 roundtable 功能链路，唯一会议固定为轻度陪审团 live | Unclecow |
| 2026-05-31 | v1.16.0 | 收束单一会议入口并补齐睡觉状态鼻涕泡真实渲染 | Unclecow |
