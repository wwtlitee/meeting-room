# DESIGN_live_meeting_runtime_v1.0.0

## 基本信息

- 日期：2026-05-29
- 版本：v1.4.0
- 负责人：Solazhu
- 范围：会议室实时多人格会议 runtime 设计；当前唯一会议形态为轻度陪审团 live

## 设计目标

当前会议室主要依赖预写 `current-session.json` 剧本，角色发言由单一主进程统一生成，无法形成真正的独立人格思考、立场变化和自由接话。V1 目标是将会议系统升级为“实时多人格 deliberation runtime”。截至 v1.1.0，普通/圆桌会议旧链路已删除，所有用户侧开会请求统一进入轻度陪审团 live：

- 参会人格使用现有角色库和 persona store 作为稳定身份来源
- 主进程担任主持人和会议调度器
- 正式参会人格实时思考；氛围状态按自身定义参与，其中 `nod`、`reserve`、`thinking` 是可发言氛围人格，`zzz`、`phone` 主要承担视觉状态
- 会议过程以“并发思考 + 排队发言 + 每条发言后全员增量再思考”为核心机制
- viewer 改为消费增量会议状态，而非整篇预写剧本
- 用户前台体验尽量与旧版 authored 会议保持一致；真实运行差异主要体现在后台调度，而不是前台额外噪音

## 已有资产

V1 不从零开始，直接复用以下资产：

- `references/roles/`：稳定角色 prompt 源
- `references/personas/`：每个角色的 `profile.md`、`knowledge.md`、`memory.md`、`memory_summary.md`
- `references/PERSONA_STORE_SCHEMA.md`：人格资料层 schema
- `scripts/build_meeting_authoring_context.ps1`：可产出 `baseRolePrompt`、`personaStoreContext`、`meetingRuntimeContext`
- `assets/expert-meeting-viewer/react-viewer/`：现有可视化会议 viewer

结论：V1 不需要重建人格资产，只需要把运行方式从“写剧本”切换为“实时调度”。

## 硬约束

### 前台展示规则

- 会议页前台不展示子 agent 拉起细节、随机昵称、队列状态、thinking 状态或 runtime 字段
- 会前等待只允许出现在 Codex 聊天侧，格式为：
  - `正在通知员工开会`
  - `<displayName> 已进入会议室`
- 每一条“已进入会议室”必须对应一次真实后台子 agent 拉起完成事件
- 一旦所有参会人格就绪，聊天侧立即切换回固定会议开场模板；会议页前台继续保持和原 authored 版本近似的观感

### 人数规则

- 最少参会人数：`5`
- 默认目标人数：`6`
- 最大参会人数：`10`
- 用户可显式要求更多人格参与；当议题覆盖面普通时，优先控制在 6 人左右
- 画面层保持 10 席布局，不因本轮人数变化删除椅子或改镜头

### 主持人规则

- 主持人由主进程担任，不作为子 agent 存在
- 主持人负责：
  - 开题
  - 控制会议状态流转
  - 决定何时开始投票
  - 决定何时结束当前轮
  - 总结与收束
- 主持人不替专家生成专业判断，不伪造专家立场变化

### 参会人格与氛围席规则

- 正式邀请人必须真实参与思考
- 氛围席不是哑巴占位，默认以 `zzz`、`phone`、`thinking`、`nod`、`reserve` 等状态补齐 10 席
- `nod` 是“对对对”附和人格，`reserve` 是保留意见人格，`thinking` 是再想想人格；这些状态本来就会说话
- 当实时上下文需要附和、保留、犹豫或气氛反馈时，主进程应允许这些可发言氛围人格插入短发言
- 不强迫每个氛围席发言，氛围席默认不进入正式投票，除非被显式提升为正式参会者
- 不允许通过假发言或预写共识伪造多人讨论

## Runtime 总体架构

### 1. Roster Layer

输入：会议议题、会议模式、候选角色池

职责：

- 根据议题选择参会角色
- 读取每个角色的：
  - `role slug`
  - `displayName`
  - `baseRolePrompt`
  - `personaStoreContext`
  - `meetingRuntimeContext`
- 生成会议 roster

输出结构建议：

```json
{
  "roleId": "engineering-frontend-developer",
  "displayName": "前端构建",
  "baseRolePrompt": "...",
  "personaStoreContext": {
    "profile": "...",
    "knowledge": "...",
    "memory_summary": "...",
    "memory": "..."
  },
  "meetingRuntimeContext": {
    "topic": "...",
    "mode": "jury_deliberation",
    "constraints": []
  }
}
```

### 2. Meeting Runtime Layer

新增运行器路径：

- `runtime/initialize_live_meeting.ps1`
- `runtime/append_live_meeting_turn.ps1`

职责：

- 初始化空 live 会议状态，不预写 turns / summary
- 选择正式邀请人，并用氛围状态补满 10 个可视席位
- 保存 persona context sidecar，供主进程逐条读取
- 每次只追加一条主持、专家、投票或总结记录
- 持续写回 `meeting-runtime.json`

核心原则：

- 主进程每次追加前必须读取最新会议记录
- 不允许一次性生成整场会议台词、投票和总结
- 不允许用固定“先赞同、再反对、最后总结”的模板顺序
- 每出现一条新发言，下一条必须基于最新会议状态和对应人格资料生成

### 3. Agent Execution Layer

V1 采用“全员参与、轮次并发”的真实运行模型。

每轮包含两种思考：

- `full_think`：本轮首次完整思考
- `delta_think`：听到别人刚发完的一条内容后，基于增量上下文快速更新自己的立场和下一条想说的话

主进程 live 运行规则：

- 正式参会人格来自真实角色库；氛围席来自固定氛围状态表，`nod`、`reserve`、`thinking` 可发言，`zzz`、`phone` 主要展示状态
- 主进程使用现有角色资料：
  - `baseRolePrompt`
  - `personaStoreContext`
  - `meetingRuntimeContext`
- 不允许把预写 source session 当作 live

### 4. Viewer Bridge Layer

viewer 不再只消费整篇预写 `current-session.json`，而改为消费增量状态。

建议 session 结构分层：

```json
{
  "id": "meeting-...",
  "topic": "...",
  "mode": "jury_deliberation",
  "participants": [],
  "roleMeta": {},
  "runtime": {
    "status": "discussion_round_1",
    "round": 1,
    "queue": [],
    "thinking": [],
    "lastSpeakerId": "",
    "consensusState": ""
  },
  "turns": [],
  "deliberation": {
    "voteRounds": []
  },
  "summary": {}
}
```

viewer 消费原则：

- `turns`：逐条追加
- `deliberation.voteRounds`：每轮结束后追加
- `summary`：会议真正结束后再写满
- `runtime`：用于展示会议当前阶段、谁在思考、谁在排队、谁刚发言

注意：

- `runtime` 字段属于后台运行态，不是用户前台文案来源
- viewer 前台默认不直接显示 `runtime.thinking` / `runtime.queue`
- 用户可见前台应保持“会议页像以前一样”，只是在底层切成 live runtime

## 会议机制

### 陪审团模式

当前唯一保留的会议形态。轻度陪审团 live 使用正式邀请人 + 氛围状态补满 10 席；主进程读取人格资料和实时会议记录，持续写入 `meeting-runtime.json`；viewer 必须保持 A/B 选项可见。

流程：

1. 主持人开题
2. 正式参会人格并发做初始思考
3. 全员投第一轮票
4. 正式参会人格并发生成本轮候选发言，`nod`、`reserve`、`thinking` 等可发言氛围人格可在需要时提供短观察
5. 按完成时间或调度优先级进入发言队列
6. 一人发言后，其余正式人格执行 `delta_think`
7. 当本轮发言达到收束条件时，主持人宣布下一轮投票
8. 全员重新投票
9. 重复直到全票统一
10. 主持人总结

### 已删除：普通/圆桌会议模式

普通会议、圆桌会议不再作为用户入口、脚本参数或 session `mode` 存在。轻松讨论、讨论一下、开个会等措辞只影响主持人语气和议题表达，不改变运行模式，不得生成 `roundtable` session，也不得隐藏大屏 A/B 选项。

## 调度规则

### 发言队列

每轮开始时：

- 正式参会人格并发思考
- 思考完成即提交候选发言和当前立场
- runtime 把完成者放入候选队列

队列排序策略建议：

1. 先按思考完成时间入队
2. 再由主持人规则裁剪：
   - 避免连续同质角色发言
   - 优先选择能回应上一条分歧的人
   - 陪审团模式下优先选择可能导致票数变化的人

### 增量再思考

每次有新发言落地后：

- 其余正式人格收到：
  - 最新 turn
  - 当前轮已有关键分歧
  - 自己上一轮立场
- 重新输出：
  - 当前立场是否变化
  - 是否准备发言
  - 如果发言，候选发言内容是什么

## 收敛条件

### 陪审团模式

- 全员投票统一
- 主持人确认不存在必须继续追问的关键风险

### 已删除旧模式

- 普通/圆桌会议没有独立收敛分支
- 所有收敛判断进入陪审团 vote rounds 与主持人总结
- 若后续需要新运行深度，必须新增深度字段或调度策略，不得恢复旧会议类型

## 数据契约

### 子 agent 输入

每个子 agent 至少接收：

- 角色显示名
- `baseRolePrompt`
- `personaStoreContext`
- 当前会议议题
- 当前会议模式
- 最近若干条关键发言
- 当前轮次状态
- 自己上一轮立场 / 投票

### 子 agent 输出

V1 建议统一结构：

```json
{
  "roleId": "engineering-frontend-developer",
  "ready": true,
  "stance": "b",
  "confidence": 0.78,
  "wantsToSpeak": true,
  "replyTo": "windows-compatibility-engineer",
  "candidateTurn": {
    "type": "speak",
    "phase": "第二轮发言",
    "text": "..."
  },
  "vote": "b",
  "reasoningSummary": "..."
}
```

## V1 范围控制

V1 明确不做：

- 会后完整人格记忆自动写回闭环
- 10 人高频高质量长期并发性能优化
- 普通/圆桌会议兼容分支
- 多线程 viewer 动画与 runtime 双向控制台

V1 先做：

- 轻度陪审团 live 唯一入口优先
- 5-6 人默认规模稳定运行
- 10 人协议和 viewer 席位兼容
- 主进程主持 + 正式参会人格参与；可发言氛围人格按状态参与短发言
- viewer 增量消费 session

## 实施顺序

1. 写 runtime 设计和数据契约
2. 实现 `initialize_live_meeting.ps1`
3. 实现 `append_live_meeting_turn.ps1`
4. viewer 接入运行中状态与增量 turn
5. 删除普通/圆桌/预写 session 兼容分支并加入回归检查
6. 再做深度运行态触发规则与上下文预算优化

## 风险

- 全员并发会明显抬高延迟和成本
- 旧普通/圆桌兼容分支残留会导致大屏 A/B 选项消失
- 预写 session 生成器残留会把 live 退化成模板播放
- 如果 delta context 过长，子 agent 会逐轮变慢
- viewer 若仍按完整剧本思维设计，会与增量 session 冲突

## 成功标准

- 同一场会议里，不同人格能够出现真实立场差异
- 发言顺序不再由预写剧本决定
- 每条发言后，其余人格会产生可观察的立场更新
- 陪审团票数变化能够对应到上一轮真实发言
- 主持人由主进程稳定控场，不再冒充专家人格

## Change Logs

| 日期 | 版本号 | 变更描述 | 负责人 |
| :--- | :--- | :--- | :--- |
| 2026-06-01 | v1.4.0 | 对外命名改为 meeting-room / 会议室，设计文档同步新名称 | Unclecow |
| 2026-06-01 | v1.3.0 | 校正氛围席规则：`nod`/对对对、`reserve`/保留意见、`thinking`/再想想属于可发言氛围人格 | Unclecow |
| 2026-06-01 | v1.2.0 | 改为 main-process append-only live，禁止预写 session 作为用户侧默认链路 | Unclecow |
| 2026-05-31 | v1.1.0 | 删除普通/圆桌会议设计分支，唯一会议形态固定为轻度陪审团 live | Unclecow |
| 2026-05-29 | v1.0.0 | 建立实时多人格子 agent 会议 runtime 第一版设计 | Solazhu |
