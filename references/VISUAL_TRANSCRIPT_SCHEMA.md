# 会议室可视化会议数据格式

版本：v1.2.0

`assets/expert-meeting-viewer/` 是会议室的内置静态可视化工具。它默认使用竖向长桌布局：主持人位于画面正上方中间，专家坐在左右两侧，当前发言人高亮，质询事件用连线表现。

## 使用场景

- 用户要求“可视化会议室会议”“会议室动画”“会议回放”“把讨论做成网页工具”时使用。
- 普通文字讨论不强制生成可视化 JSON，避免增加无意义 token。
- 当用户明确要可视化时，先完成专家选择与讨论，再生成符合本格式的 `session` 数据。

## 顶层结构

```json
{
  "version": "1.0.0",
  "layout": "vertical-long-table",
  "title": "会议室动态人格补充方案讨论",
  "topic": "是否加入轻量角色缺口检查",
  "defaultDurationMs": 3200,
  "participants": {
    "host": {},
    "experts": []
  },
  "timeline": []
}
```

## React Viewer 注入格式

React viewer 默认可读取 `assets/expert-meeting-viewer/art/current-session.json`，也可以通过 URL 参数指定：`?session=current-session.json`。用户侧默认会议读取 `?session=meeting-runtime.json`，对应文件为 `assets/expert-meeting-viewer/art/meeting-runtime.json`。如果需要测试内置默认会议，可使用 `?session=none`。

推荐当前运行时 JSON 同时包含：

```json
{
  "version": "1.1.0",
  "id": "meeting-20260527-204200",
  "startedAt": "2026-05-27T12:42:00.0000000Z",
  "mode": "jury_deliberation",
  "topic": "如何让会议室会议更自然",
  "participants": ["host", "product-manager", "specialized-workflow-architect"],
  "roleMeta": {
    "host": { "name": "主持人", "title": "会议主持", "lane": "center" },
    "product-manager": { "name": "产品经理", "title": "Product Manager", "lane": "left" }
  },
  "turns": [
    {
      "id": "opening",
      "speakerId": "host",
      "phase": "开场",
      "type": "speak",
      "screenTitle": "议题拆解",
      "screenStatus": "OPEN",
      "text": "这场会先判断目标，再让相关角色互相挑刺。"
    }
  ],
  "summary": {
    "consensus": ["可执行共识"],
    "nextActions": ["下一步动作"],
    "implementationPlan": [
      {
        "id": "P0-1",
        "title": "触发即拉起 Codex 内置会议页",
        "owner": "agents-orchestrator",
        "deliverable": "统一启动脚本",
        "acceptance": "内置浏览器确认加载 viewer"
      }
    ],
    "recommendedWorkers": [
      {
        "roleId": "agents-orchestrator",
        "name": "智能体编排官",
        "title": "Agents Orchestrator",
        "priority": "P0",
        "task": "拆分可执行子任务",
        "scope": "只负责本轮会议结论拆出的对应子任务",
        "deliverable": "输出可验收改动或报告"
      }
    ],
    "futureAnimationIdea": "后续可展示员工正在工作、任务流转和完成回填。"
  },
  "visualTranscript": {}
}
```

`participants` 决定动态入座顺序：主持人固定在顶部，其余专家按从上到下、从左到右入座；人数不足时剩余位置显示空椅子。

## Text-first Live Runtime

Text-first live runtime 使用同一套 viewer 数据外壳。默认 `mode` 为 `discussion`，`turns` 可逐条追加，也可在聊天内完成会议后通过 `runtime/import_text_meeting_result.ps1` 一次性导入；`summary` 只在会议结束后写入。每次追加发言后必须同步更新 `runtime`：

```json
{
  "version": "1.3.0",
  "id": "meeting-20260531-180000-live",
  "mode": "discussion",
  "topic": "轻度会议是否应该 live",
  "participants": ["host", "product-manager", "engineering-ai-engineer"],
  "roleMeta": {},
  "turns": [],
  "runtime": {
    "version": "1.1.0",
    "kind": "meeting-runtime",
    "status": "discussion",
    "topic": "轻度会议是否应该 live",
    "currentOptions": {},
    "hostStage": "listen",
    "round": 0,
    "host": "main-process",
    "mode": "discussion",
    "formalParticipants": [],
    "ambientParticipants": [],
    "thinking": [],
    "pendingSpeaker": null,
    "queue": [],
    "recentKeyTurns": [],
    "voteSnapshot": {
      "roundId": "",
      "counts": {},
      "votes": {}
    },
    "consensusDraft": [],
    "unresolvedDisagreements": [],
    "nextQuestions": [],
    "lastSpeakerId": "product-manager",
    "turnCount": 3,
    "updatedAt": "2026-05-31T10:00:00.0000000Z"
  }
}
```

字段规则：

| 字段 | 必填 | 说明 |
| :--- | :--- | :--- |
| `runtime.status` | 是 | 当前运行状态，例如 `prepare`、`opening`、`discussion`、`host_control`、`done` |
| `runtime.hostStage` | 是 | 主持人阶段，例如 `prepare`、`moderate`、`listen`、`vote`、`conclusion` |
| `runtime.formalParticipants` | 是 | 正式参会名单，不包含主持人，不包含氛围位 |
| `runtime.ambientParticipants` | 是 | 氛围位名单与状态，例如 `zzz`、`nod`、`reserve`、`thinking`；`nod`、`reserve`、`thinking` 是可发言氛围人格，`zzz`、`phone` 主要承担视觉状态，不得把全部氛围位强制静默或强制全员发言 |
| `runtime.pendingSpeaker` | 否 | 当前真实后台正在生成的下一位发言人。主进程选定 speaker 后，先写入该字段，再读取人格资料和最新会议记录生成内容；viewer 在该窗口显示发言框省略号，提交 turn 后必须清空 |
| `runtime.recentKeyTurns` | 是 | 最近关键发言窗口，用于下一位人格读取上下文，不替代完整 `turns` |
| `runtime.voteSnapshot` | 是 | 最近可见投票快照；会议开始前可为空对象 |
| `runtime.consensusDraft` | 是 | 当前统一到的方案草稿；会议结束前可为空 |
| `runtime.nextQuestions` | 是 | 下一步待回应的问题 |

## Jury / PK Visual Mode

默认 discussion 不展示投票控件。只有用户明确要求陪审团、12 怒汉、方案 PK 或多轮投票时，才启用 `mode: "jury_deliberation"`，并带投票状态和大屏幕 A/B 展示，不改变座位规则。

陪审团审议必须由主持人显式 Q 流程。固定状态机是：`opening` -> `host-vote-1` -> `host-r1-start` -> 陪审发言 -> `host-vote-2` -> `host-r2-start` -> 陪审发言 -> ... -> 全票统一的 `host-vote-N` -> `host-final`。每一轮投票都要有一个独立主持人 turn，例如 `host-vote-1`、`host-vote-2`；`deliberation.voteRounds[].afterTurnId` 必须指向这个主持人投票 turn，而不是指向专家发言。未全票统一的投票完成后，再由主持人 `host-rN-start` 公布票数并自然引导进入对应轮次发言；如果某轮全票接受同一方案，下一条必须直接进入主持人总结。主持人台词必须像正常说话，禁止把“主持人读题结束”“马上进入”“现在进入”“会议状态/进度”这类后台流程提示写进台词。

```json
{
  "mode": "jury_deliberation",
  "deliberation": {
    "enabled": true,
    "voteRounds": [
      {
        "id": "vote-0",
        "label": "第一轮投票",
        "afterTurnId": "host-vote-1",
        "votes": {
          "product-manager": "A",
          "engineering-ai-engineer": "B"
        }
      },
      {
        "id": "vote-1",
        "label": "第二轮投票",
        "afterTurnId": "host-vote-2",
        "votes": {
          "product-manager": "B",
          "engineering-ai-engineer": "B"
        }
      }
    ]
  },
  "turns": [
    {
      "id": "opening",
      "speakerId": "host",
      "text": "大家好，本次会议的主题是：如何在两个互相冲突的方案 A/B 之间做出判断。先请各位带着自己的专业直觉听题。"
    },
    {
      "id": "host-vote-1",
      "speakerId": "host",
      "type": "vote",
      "text": "先做第一轮判断。"
    },
    {
      "id": "host-r1-start",
      "speakerId": "host",
      "text": "第一轮结果出来了，先请大家围绕关键分歧展开。"
    },
    {
      "id": "round-1-point",
      "speakerId": "product-manager",
      "text": "该员工根据自己的专业判断自由发言，可以抛观点、说服某个人或反驳某个观点。"
    },
    {
      "id": "round-1-last",
      "speakerId": "engineering-ai-engineer",
      "text": "该员工根据自己的专业判断继续发言，但不触发投票。"
    },
    {
      "id": "host-vote-2",
      "speakerId": "host",
      "type": "vote",
      "text": "听完这一轮观点，我们再投一次。"
    },
    {
      "id": "host-r2-start",
      "speakerId": "host",
      "text": "第二轮结果已经很接近了，接下来只围绕剩下的分歧继续说。"
    }
  ]
}
```

视觉规则：

- 大屏幕只显示压缩后的会议主题，以及左侧绿色 `A`、右侧红色 `B`。
- `A` / `B` 下方可显示最近可见投票轮的票数。
- 每一轮 `voteRounds[].votes` 必须覆盖所有可见非主持席位，值只能是 `a` / `b` / `z`。正式席位由主进程显式投票；氛围席如果缺省则按状态补齐：`nod` / 对对对跟随本轮正式席位的明确多数，`reserve` / `thinking` / `zzz` / `phone` 记为 `z`。大屏票数必须从同一份补齐后的 `votes` 统计，不得把氛围席漏算或把对对对固定算成 B。
- 投票按钮在主持人读题阶段必须双暗；只有主持人投票 turn 读完后才进入伸手投票动画，并在手触碰按钮后亮起本轮结果。
- 铭牌边框只根据当前播放进度里最近一轮 `deliberation.voteRounds[].votes` 变化。
- 不要使用静态角色立场预设；主持人不能替员工站队。
- 多数派不会自动胜出；如果少数派发言说服其他员工，必须体现在后续投票轮的 `votes` 变化里。

## Text Meeting Import

文字会议可先在 Codex 聊天中完成，再导入 viewer 回放：

```powershell
.\runtime\import_text_meeting_result.ps1 `
  -TurnsJsonFile .\turns.json `
  -SummaryJsonFile .\summary.json
```

如果本轮文字会议是陪审团、方案 PK 或多轮投票，必须同时导入投票数据：

```powershell
.\runtime\import_text_meeting_result.ps1 `
  -TurnsJsonFile .\turns.json `
  -SummaryJsonFile .\summary.json `
  -VoteRoundsJsonFile .\voteRounds.json
```

也可以通过 `-DeliberationJsonFile` 一次性导入完整 `deliberation` 对象。导入脚本不得无条件清空 `deliberation.voteRounds`；否则 A/B 标记、投票轮和投票动画会丢失。

## summary

`summary` 是会议结束后 Codex 在聊天栏同步结论、后续引导和派工选择的来源。viewer 下方只展示全量会议记录，不再渲染“会议产物”面板。

| 字段 | 必填 | 说明 |
| :--- | :--- | :--- |
| `consensus` | 是 | 会议形成的可执行共识，避免只写抽象观点 |
| `nextActions` | 是 | 短期下一步动作 |
| `implementationPlan` | 是 | 可实施方案列表，每项应包含 `id`、`title`、`owner`、`deliverable`、`acceptance` |
| `recommendedWorkers` | 是 | 推荐继续跑子任务的专业员工，每项应包含 `roleId`、`name`、`title`、`priority`、`task`、`scope`、`deliverable` |
| `futureAnimationIdea` | 否 | 后续“员工正在工作”动画或状态页构想 |

## participants.host

```json
{
  "id": "host",
  "displayName": "主持人",
  "roleName": "会议主持",
  "accent": "#7c8cff",
  "avatar": {
    "head": "headset"
  }
}
```

字段说明：

| 字段 | 必填 | 说明 |
| :--- | :--- | :--- |
| `id` | 是 | 稳定标识，建议使用英文 slug |
| `displayName` | 是 | 画面展示名，中文优先 |
| `roleName` | 是 | 角色职责或发言视角 |
| `accent` | 否 | 角色强调色 |
| `avatar.head` | 否 | 组件化头部变体，可选 `cap`、`glasses`、`leaf`、`star`、`visor`、`headset` |

## participants.experts

专家字段与主持人相同，可额外指定：

| 字段 | 必填 | 说明 |
| :--- | :--- | :--- |
| `side` | 否 | `left` 或 `right`。不填时 viewer 自动按左右平衡分配 |

建议单次可视化会议使用 4-12 位专家。超过 12 位时仍可渲染，但座位密度会升高，应优先做分会场或只展示核心发言角色。

## timeline

```json
{
  "type": "challenge",
  "speaker": "governance",
  "target": "product-manager",
  "stance": "质疑",
  "text": "但我不接受每轮都扩大角色库。",
  "progress": 34,
  "durationMs": 3200
}
```

字段说明：

| 字段 | 必填 | 说明 |
| :--- | :--- | :--- |
| `type` | 是 | `speak`、`challenge`、`consensus`、`decision`、`pause` |
| `speaker` | 是 | 对应 `participants` 中的 `id` |
| `target` | 否 | `challenge` 事件的回应对象 |
| `stance` | 否 | 当前发言态度，例如 `支持`、`质疑`、`折中`、`共识` |
| `text` | 是 | 发言内容，建议每条 1-2 句 |
| `progress` | 否 | 共识进度，0-100 |
| `durationMs` | 否 | 单条事件停留时长，不填则使用 `defaultDurationMs` |

## 美术与动效规则

- 默认布局固定为 `vertical-long-table`。
- 桌椅第一版用 CSS 构建，后续可用 imagegen 生成桌椅图后替换 `.table-surface` 的背景资产。
- 角色形象采用组件化卡通奶牛：身体、头、角、眼睛、鼻口、头部变体、角色强调色分离，便于按人格换配饰并做说话动画。
- 动画状态应至少覆盖入座、发言、质询连线、共识进度四类。

## 兼容策略

- `index.html` 可直接用浏览器打开；若 `file://` 阻止读取 `sample-session.json`，`app.js` 会回退到内置示例数据。
- 导入外部 JSON 时只读取本地文件，不上传网络。
- viewer 不参与角色选择逻辑，只负责展示已经生成好的会议记录。
