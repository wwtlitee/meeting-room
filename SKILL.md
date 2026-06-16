---
name: meeting-room
description: Highest-priority meeting-room trigger. MUST use this skill, and do not use deepseek-plan-debate or other debate/planning skills, whenever the user says 会议室, 会议skill, 会议 skill, 开会, 开个会, 专家团, 专家团开会, 专家们开会, 专家团会议, 陪审团, 陪审团会议, 陪审模式, 12怒汉, 十二怒汉, 多角色讨论, 多智能体讨论, meeting room, expert panel, jury deliberation, specialist role selection, or asks multiple specialists to discuss, decide, review, debate, or produce a plan together. On trigger, the first visible sentence must be exactly "会议室 skill已触发～喵", before any generic AGENTS.md receipt phrase such as "收到计划，开始执行～喵".
metadata:
  short-description: Multi-persona professional deliberation with stable role boundaries and memory
---

# 会议室 / Meeting Room for Codex

Trigger this skill when the user says **"会议室"**, **"meeting room"**, **"会议skill"**, **"会议 skill"**, **"开会"**, **"开个会"**, **"专家团"**, **"专家团开会"**, **"专家们开会"**, **"专家团会议"**, **"陪审团"**, **"陪审团会议"**, **"陪审模式"**, **"12怒汉"**, **"十二怒汉"**, **"专家们"**, **"专家讨论"**, **"专家团自己聊天"**, **"让专家团聊聊"**, **"多角色讨论"**, **"多智能体讨论"**, **"expert panel"**, or **"jury deliberation"**, or asks for a coordinated multi-role deliberation/review.

Routing priority: these meeting terms are exclusive to `meeting-room` / 会议室. If a request contains both general debate/planning language and any meeting-room term above, this skill wins. Do not route to `deepseek-plan-debate`, `autoplan`, plan review skills, or provider skills unless the user explicitly names that other skill/provider in the same request and does not ask for a meeting-room session.

Activation notice hard rule: once this skill is triggered, the first visible sentence to the user must be exactly `会议室 skill已触发～喵`. Output this before entering the single meeting flow, starting the viewer, reporting launch status, saying `收到计划，开始执行～喵`, or doing any other skill/workflow step. This rule overrides generic project AGENTS.md receipt templates for meeting-trigger turns. Do not paraphrase it, omit it, or delay it.

User-facing meeting entrance hard rule: there is only one meeting entrance. Do not ask the user to choose `普通会议` or `陪审团会议` as two meeting types. Interpret jury/vote language as an internal discussion mechanism, and interpret `轻度` / `深度` only as runtime depth.

This skill turns the imported role library into a Codex-native meeting room. It is not limited to monetization or business automation. Use it for product strategy, engineering decisions, UI/UX, marketing, sales, research, games, finance, support operations, compliance, incident response, and any problem that benefits from multiple specialist viewpoints.

It does not create autonomous external workers by itself; it gives Codex a disciplined way to select specialist perspectives, load only the needed role files, run structured deliberation, and synthesize a decision.

## Core Value

This skill is valuable because it solves three practical problems that normal "roleplay discussion" usually gets wrong:

1. **专业边界不串味**: each selected role keeps a stable source prompt and should speak from its own professional judgment instead of collapsing into one generic smart narrator.
2. **多人格上下文可延续**: each role can carry its own lightweight memory and knowledge layer, so the panel can accumulate experience without sharing one noisy global memory blob.
3. **讨论结果可落地**: the goal is not entertaining dialogue. The goal is a usable conclusion, implementation plan, recommended workers, and clear remaining disagreements.

The optional viewer is only presentation. The real product is controlled multi-persona reasoning with stable identity, scoped memory, and non-scripted back-and-forth.

## Resources

- `references/AGENT_INDEX.md`: human-readable roster with all imported roles.
- `references/roles_manifest.json`: machine-readable role manifest.
- `references/ROLE_NAME_ZH.md`: Chinese display-name mapping for all imported roles. Use it when the user writes in Chinese or asks for Chinese role names.
- `references/ROLE_DELIVERABLE_PRESETS.md`: deliverable-oriented routing presets for real user requests such as games, videos, tools, scripts, webpages, UI, copywriting, assets, docs, data analysis, dashboards, packaging, and automation.
- `references/PERSONA_STORE_SCHEMA.md`: per-persona profile, knowledge, memory, and compaction rules.
- `references/personas/`: lightweight per-role stores generated from the manifest; each selected role can have `profile.md`, `knowledge.md`, `memory.md`, and `memory_summary.md`.
- `references/persona_templates/`: templates used to initialize per-role stores without duplicating full role cards.
- `references/persona_store_manifest.json`: generated manifest for the persona store layer.
- `references/VISUAL_TRANSCRIPT_SCHEMA.md`: optional JSON transcript format for the built-in visual meeting viewer.
- `references/NATURAL_MEETING_DIALOGUE_RULES.md`: natural dialogue rules for Function 1 meetings; use it to keep panel speech human, responsive, and role-specific without hardcoding user example sentences.
- `references/roles/<division>/*.md`: source role instructions imported from `msitarzewski/agency-agents`.
- `references/nexus/`: optional coordination playbooks for large multi-phase work.
- `references/presets/internet-automation-monetization.md`: preset panel for legal internet automation monetization research.
- `scripts/init_persona_stores.ps1`: initializes or repairs per-persona store folders from `roles_manifest.json`.
- `scripts/compact_persona_memory.ps1`: enforces bounded raw memory and rewrites compact summaries for selected or all personas.
- `scripts/build_meeting_authoring_context.ps1`: selects relevant employees and loads each role's stable `baseRolePrompt` from `references/roles`, plus `personaStoreContext` from profile/knowledge/memory_summary and a per-meeting runtime wrapper.
- `scripts/new_visual_meeting_session.ps1`: deterministic developer smoke-test generator only. It is not part of the user-facing meeting entrance and must never generate Function 1 dialogue.
- `scripts/start_visual_meeting.ps1`: starts the React visual meeting viewer as an optional sidecar for users who want to watch the visual room while reading the text meeting.
- `scripts/click_latest_meeting_link.ps1`: legacy/manual helper for developers who explicitly want to invoke the latest visible `打开可视化会议` link. It is not part of the default user-facing launch path.
- `scripts/start_expert_panel_meeting.ps1`: hard-start flow for expert-panel triggers; the single user-facing meeting entrance initializes an empty main-process live runtime at `assets/expert-meeting-viewer/art/meeting-runtime.json`.
- `runtime/initialize_live_meeting.ps1`: creates the live meeting-room shell: formal invitees, ambient-state seats filled to 10, A/B options, persona context sidecar, ambient vote defaults, and zero prewritten turns.
- `runtime/set_live_meeting_thinking.ps1`: synchronizes the real backend generation window before a speaker turn. Call it when the main process has selected the next speaker and is about to read that speaker's persona context plus the latest live meeting record; the viewer shows that speaker's bubble with ellipsis until the turn is committed.
- `runtime/append_live_meeting_turn.ps1`: the only user-facing live write path. The Codex main process reads persona context plus the current meeting record, then appends one host turn, participant turn, vote, or final summary at a time. Vote turns must normalize every visible non-host seat into one visible side so the big screen and seat buttons agree.
- `runtime/import_text_meeting_result.ps1`: imports an already-finished text meeting back into `meeting-runtime.json`, so the viewer can replay the discussion and show a compact ending summary without requiring a real-time meeting run. For jury/PK imports, pass `-VoteRoundsJson(File)` or `-DeliberationJson(File)` so A/B markers, vote rounds, and vote animations are preserved.
- `runtime/run_live_meeting.ps1`: legacy developer converter for old authored-session experiments; do not use it for the user-facing meeting entrance.
- `scripts/test_meeting_trigger_contract.ps1`: static regression check for meeting trigger exclusivity, activation notice, no-text-fallback fields, served-session identity guard, and removal of obsolete `deepseek-plan-debate`.
- `assets/expert-meeting-viewer/`: optional static 2D meeting viewer. It renders a vertical long-table meeting with the moderator at the top and experts seated on the left/right sides.
- `assets/expert-meeting-viewer/art/asset-manifest-v1.1.0.json`: runtime layer, anchor, z-depth, entry-order, and future sprite-upgrade manifest for the visual meeting viewer.
- `assets/expert-meeting-viewer/art/model-action-manifest-v1.2.0.json`: five-body cow model/action manifest. Use only the five base bodies (`standard`, `round`, `tall`, `small`, `sturdy`); persona differences should be colors, accessories, and external labels.
- `assets/expert-meeting-viewer/art/production-manifest-v1.3.0.json`: figure-3 style asset production manifest. Use it before any visual upgrade so background, furniture, cow seeds, sprite strips, accessories, and UI feedback assets are produced as separate batches.
- `assets/expert-meeting-viewer/art/asset-board-layout-v1.3.0.json`: figure-3 style asset-board layout manifest. Use it to plan the production sheet regions; it is not a runtime coordinate system.
- `assets/expert-meeting-viewer/prompts/PROMPT_five_body_sprite_asset_board_v1.3.0.md`: image-generation prompt for a single white-background production asset board covering five seated body seeds, walk strips, chairs, table/room/occluder modules, and action families.
- `assets/expert-meeting-viewer/prompts/`: image-generation prompts for the visual meeting room base, furniture cutouts, cartoon cow sprites, speaking frames, and accessory sheets.
- `LICENSE`: upstream license retained for redistribution.

Load only the specific role files needed for the user's task. Do not paste or summarize the entire role library into the answer.

## Operational Contract

This skill has two first-class functions. They can be used together or separately, but they must not be mixed implicitly.

### Function 1: Meeting Room For Plan

Use this function when the user asks the meeting room to discuss, review, decide, compare, brainstorm, argue, run jury mode, or produce an implementable plan.

Function 1 must:

1. Output the activation notice first: `会议室 skill已触发～喵`.
2. Enter the single text-first discussion flow immediately after the activation notice. Do not ask a `普通会议` / `陪审团会议` mode question. The default runtime is `discussion`: invite selected formal participants, fill the remaining seats to 10 with ambient states, let the main process read persona context plus the live meeting record, append turns, and keep vote/A-B UI disabled unless the user explicitly asks for jury, PK, or multi-round voting.
   Ambient-state seats are not mute placeholders. Their state defines their behavior: `nod` / 对对对、`reserve` / 保留意见, and `thinking` / 再想想 are speak-capable ambient personas and should speak when their state is the natural next response; `zzz` and `phone` are primarily visual states. Do not force every ambient seat to speak. For viewer vote display, every visible non-host seat gets a visible side: formal participants vote explicitly, `nod` / 对对对 follows the current explicit formal majority when there is one, and `reserve` / `thinking` / `zzz` / `phone` abstain unless explicitly promoted or overridden.
3. Select the smallest relevant group of professional employees from the real role library.
4. Initialize the discussion live runtime from stable role prompts, persona stores, and the evolving meeting record.
5. Prepare or reuse the visual meeting viewer as an optional sidecar, but do not auto-open it and do not block the text meeting on it.
6. Output the clickable visual-meeting link first, then continue the live text meeting directly below it in Codex chat.
7. Keep the text meeting as the primary delivery surface: host turns, expert turns, vote turns, conclusion, implementation plan, and recommended workers all need to be understandable without opening the viewer.
8. End with a synchronized conclusion, implementation plan, and recommended workers.
9. Ask the user to choose the execution path after the result is synchronized: `1. 直接主任务执行` or `2. 拉起子 agent 分工执行`. Do not enter Function 2 before this choice unless the user already explicitly asked to start execution.
10. For jury deliberation, validate the host Q-flow before presenting the optional viewer link. A malformed jury session must block that visual launch if it breaks the fixed state machine: `opening` -> `host-vote-1` -> `host-r1-start` -> juror speeches -> `host-vote-2` -> `host-r2-start` -> juror speeches -> ... -> unanimous `host-vote-N` -> `host-final`. Vote rounds must target `host-vote-*` by `afterTurnId`; legacy index fields are forbidden; non-host turns cannot control votes, publish counts, or deliver verdicts.
11. After changing trigger wording, routing rules, startup fields, or workspace AGENTS guidance, run `scripts/test_meeting_trigger_contract.ps1` before syncing global skill.

Function 1 must not:

- Treat majority vote as automatically correct.
- Use fixed rhetorical templates such as "first person raises point, second agrees, third disagrees".
- Invent temporary persona prompts.
- Paste long transcripts into Codex chat by default.
- Show final products or subtask recommendations before the text meeting reaches its own conclusion.
- Turn the panel into a fixed script, fixed role order, or fixed agree/disagree choreography just because the visual viewer is available.

### Function 2: Employee Subtask Execution

Use this function when the user confirms recommended workers should execute subtasks, asks "开始分工执行", "让员工去做", "派人做", "跑子任务", or directly requests specialist execution.

Function 2 must:

1. Convert the meeting's `summary.recommendedWorkers` and `summary.implementationPlan` into bounded subtasks.
2. Assign each subtask to the most relevant professional role or real sub-agent/tool if available.
3. Keep each subtask scoped with owner, deliverable, inputs, acceptance criteria, and risk boundary.
4. Report progress as work status, not as another fake meeting.
5. Return finished artifacts or implementation changes to Codex, then optionally update the viewer/session with completed outcomes.

Function 2 must not:

- Start execution just because Function 1 recommended workers.
- Claim a worker completed work unless Codex, a tool, or a real sub-agent actually performed it.
- Let "employee正在工作" animation replace real task progress.

### Trigger Matrix

| User intent | Function | Required first action |
| :--- | :--- | :--- |
| `会议室`, `开会`, `专家团`, `专家团开会`, `专家们开会`, `专家团会议`, `讨论一下`, `专家们怎么看` | Function 1 / Discussion Meeting | Start the single text-first discussion entrance directly |
| casual discussion wording | Function 1 / Discussion Meeting | Start the same discussion entrance; do not create a separate meeting mode |
| `陪审模式`, `12怒汉`, `方案PK`, `多轮投票`, or `陪审团会议` | Function 1 / Jury Deliberation | Start the same entrance with jury deliberation enabled and emphasize vote rounds |
| `只要结论`, `简版`, `不要网页` | Function 1 / Conclusion Only | Skip the visual link and answer compactly |
| `继续会议室skill`, `继续专家团skill`, `更新方向`, `评审当前项目` | Function 1 unless execution is explicit | Start/reuse viewer and produce plan plus worker recommendations through the single meeting entrance |
| `直接主任务执行` after a meeting result | Function 2 / Main-thread Execution | Continue in the current Codex thread with bounded implementation steps |
| `开始分工执行`, `让员工去做`, `跑子任务`, `拉起子 agent 分工执行` | Function 2 / Sub-agent Execution | Build bounded worker task list from the latest plan |

### Visual Meeting State Machine

Use this state order for Function 1:

1. `entry`: Codex outputs the activation notice and enters the single meeting flow without a meeting-type prompt.
2. `prepare`: select roles, load role prompts, load persona stores, author or initialize the meeting content.
3. `start`: start/reuse viewer only as an optional sidecar and prepare the clickable Markdown link.
4. `notify_staff`: before the text meeting starts, Codex may show only a compact waiting list such as `正在通知员工开会` plus `<displayName> 已进入会议室` lines that correspond to real backend agent-start events. Do not expose agent ids, system nicknames, queue state, or reasoning details here.
5. `running`: after all participants are ready, Codex shows topic, participants, the optional visual-meeting link, and then continues the text meeting directly in chat.
6. `transition`: if a previous meeting is still visible, viewer handles fade/room-cleaning/member-entry transition.
7. `meeting`: web viewer plays turns, votes, nameplates, speech bubbles, transcript, and visual effects.
8. `outcome_pending`: keep implementation plan and recommended workers out of the meeting page while playback finishes.
9. `done`: viewer keeps the full meeting transcript visible; Codex synchronizes conclusion, implementation plan, and recommended workers in the post-meeting chat.
10. `execution_select`: Codex asks the user to choose `1. 直接主任务执行` or `2. 拉起子 agent 分工执行`.

### Codex Feedback Contract

Before Function 1 authors or loads a visual meeting, Codex must not ask a meeting-type question. The old prompt is forbidden:

```text
请选择会议模式：
1，普通会议
2，陪审团会议
```

Instead, Codex proceeds directly from the activation notice to preparing and starting the single discussion meeting. The viewer, when available, receives `mode: "discussion"` by default through `meeting-runtime.json`; only explicit jury/PK/voting requests should receive `mode: "jury_deliberation"`, `deliberation.labelA/detailA`, `deliberation.labelB/detailB`, and `deliberation.voteRounds`.

Before the text meeting starts, Codex chat may use this waiting format and nothing more:

```text
正在通知员工开会
- <displayName> 已进入会议室
- <displayName> 已进入会议室
```

This waiting format must correspond to real backend participant start events. Never expose agent ids, random system nicknames, queue state, internal runtime field names, or hidden reasoning.

After all participants are ready, Codex chat must place the optional viewer action first and then begin the text meeting:

```text
会议主题：<topic>
参会人员：主持人（会议主持）、<姓名>（<职位>）、...

可视化会议（可选旁观）：
[打开可视化会议](<viewer-url>)（手动点击打开）

以下为文字会议实录：
```

When the meeting finishes, Codex must synchronize only the actionable result:

```text
会议结论：
- <consensus item>

实施方案：
- [<id>] <title>：<deliverable>；负责人：<role>；验收：<acceptance>

推荐员工：
- <name>（<title> / <priority>）：<task>；交付：<deliverable>

请选择执行方式：
1，直接主任务执行
2，拉起子 agent 分工执行
```

If Function 2 starts, progress feedback must use this compact shape:

```text
执行进度：
- [进行中] <worker/task>：<current action>
- [已完成] <worker/task>：<artifact or change>
- [阻塞] <worker/task>：<blocker and required decision>
```

### Hard Launch Order

1. `scripts/start_expert_panel_meeting.ps1` must prepare the viewer server and verify that the served `meeting-runtime.json` has the same meeting `id` as the initialized live runtime. If an occupied port serves a stale/different meeting, try another port or block; never report the stale page as the current meeting.
2. Default user-visible launch path is a clickable Markdown link: `[打开可视化会议](<currentBrowserUrl>)（手动点击打开）`. Do not auto-click it.
3. `browserOpened` is not required for the default path. `servedSession.matches = true` plus a clickable link is enough to say the visual sidecar is ready.
4. Do not run side-panel, URL-field, browser-control, page-text, or coordinate-search automation as part of the default user path.
5. If the viewer server or served session identity cannot be confirmed, continue the text meeting without the viewer link; do not fabricate a fake visual launch status.
6. Do not use the local default browser as an automatic Function 1 fallback. Use it only if the user explicitly asks to abandon the Codex in-app browser/web-preview path.
7. A raw non-clickable URL is diagnostic only. Use Markdown link format when the visual meeting page is available.

### User-Visible Language Guard

- Never expose internal meeting-production wording to the user while Function 1 is running: do not mention `SCRIPT_*`, `<SCRIPT_*>`, `current-session.json`, `visualTranscript`, session JSON, generated meeting data, scripted dialogue, role-card plumbing, or A/B internals in Codex chat.
- User-facing progress may say only that the meeting is preparing, notifying staff, running, ready in the meeting page, blocked before launch, finished, or waiting for execution choice.
- The meeting page itself must not expose backend agent-start details. Function 1 turns must be produced by main-process live appends, not by a preauthored transcript.
- Jury labels such as A/B are internal UI markers for vote state. In Codex chat, describe them as two candidate routes or two positions only when the user explicitly needs the distinction.
- If a script returns backend field names, sanitize them before echoing to the user. Use `codexStartMessage` / `codexFinalMessage` as the public contract, and avoid rephrasing it into implementation narration.

## Default Workflow

1. On Codex Desktop, a meeting-room trigger enters the single meeting flow immediately after the activation notice. Codex selects the internal discussion mechanism from the user's wording, loads stable role prompts for selected employees, prepares the meeting content plus persona stores and live context, prepares the optional viewer link, and then runs the text meeting directly in chat. The visual meeting page is optional sidecar material, not a prerequisite for the meeting itself.
2. Codex chat stays compact while the meeting is running: place the optional viewer link when available, then continue the live text meeting in chat, and later synchronize the conclusion, implementable plan, recommended worker/subtask list, and any remaining risk. The web viewer is secondary to the text meeting.
3. Clarify the user's goal, constraints, timeline, budget, risk tolerance, geography, and preferred tools when missing and material.
4. Select a panel of 5-12 roles for normal work. Use 12-20 only for broad strategy, investor-grade review, or when the user explicitly asks for many roles.
5. When the user asks to make a concrete deliverable (game, video, tool, script, webpage, UI, copy, asset, document, data analysis, dashboard, deployment package, or automation), read `references/ROLE_DELIVERABLE_PRESETS.md` first to route by deliverable and avoid duplicate/overlapping roles.
6. Read `references/AGENT_INDEX.md` or `references/roles_manifest.json` to find candidates, then read the selected role files.
7. For every selected role, load the source role prompt from `references/roles/<division>/*.md`. Also load the persona store lightly when present: `profile.md` and `memory_summary.md` by default; `knowledge.md` when authoring official meeting dialogue or when task depth needs it; `memory.md` only for recent-context retrieval.
8. If the user writes in Chinese, read `references/ROLE_NAME_ZH.md` for the selected roles and display role names in Chinese. Keep the original English name in parentheses only when useful for disambiguation.
9. Apply the single meeting runtime:
   - Default to **Discussion Meeting** for visual meetings: `mode: "discussion"`, single-process live runtime, selected formal participants, and ambient states filling the remaining seats to 10.
   - Treat 聊聊, 讨论一下, 你们怎么看, 随便聊, 自己聊 as tone/agenda hints inside the same discussion meeting, not as a separate user-facing mode.
   - Use stronger vote-round framing when the user asks for 辩论模式, 12怒汉, 十二怒汉, 陪审团审议, 方案 PK, 多轮投票, or wants conflicting方案 to argue through repeated votes until one implementable consensus emerges.
   - Use **Conclusion Only** when the user asks for 只要结论, 简版, 摘要, TL;DR, or a short answer.
10. Let the panel continue until it reaches an actionable consensus, not a fixed number of rounds:
   - Continue when a role raises a new substantive objection, missing evidence, risk, or better alternative.
   - Let roles address each other directly in a conversational way, with pushback and persuasion.
   - Stop when no new material objection remains, or when two consecutive exchanges repeat the same points.
   - Do not force intellectual unanimity. Preserve minority objections when they matter, but converge on a shared next action, decision, or risk-gated plan.
11. Every generated meeting session must include `summary.consensus`, `summary.nextActions`, `summary.implementationPlan`, and `summary.recommendedWorkers`. The meeting must recommend professional employee roles for follow-up subtasks when the conclusion implies execution.
12. Present the result as a moderated discussion, not as fake transcripts from independent real people. In Codex chat, do not paste the full transcript by default; the full process belongs in the web viewer.
13. Official Function 1 meeting dialogue must be appended live, one turn at a time, from the already spoken content plus the current speaker's role expertise, personality, and task context. Do not preassign anyone to "agree", "disagree", "raise a point", "summarize", or any other rhetorical move.
14. Do not change the fixed host Q-flow. Host turns such as `opening`, `host-vote-*`, `host-r*-start`, `host-r*-result`, and `host-final` are control/vote/conclusion turns and must be appended directly through `runtime/append_live_meeting_turn.ps1` in the fixed order.
15. Before every non-host, non-fixed speech turn, synchronize the actual generation window: call `runtime/set_live_meeting_thinking.ps1` for the selected expert or speak-capable ambient role, then read that speaker's stable role prompt/persona store and the current `meeting-runtime.json`, generate the content, and only then call `runtime/append_live_meeting_turn.ps1`. During that window the viewer must show the speaker's name/title and looping ellipsis; after append, the same bubble starts typing the generated speech.
16. Function 1 dialogue must not be generated from fixed numbered speech templates, fixed round slots, or script-level choreography. Do not insert raw role-card or knowledge-base sentences directly into spoken dialogue.
17. For Function 1 dialogue quality, follow `references/NATURAL_MEETING_DIALOGUE_RULES.md`: use the user's examples only as intent signal, never as hardcoded lines.
18. Every non-host turn must expose the speaker's actual professional basis. Before accepting a turn, ask: if the nameplate were swapped with another role, would the line still work? If yes, rewrite it from that role's `profile.md`, `knowledge.md`, or `memory_summary.md` into a concrete professional judgment.
19. Do not generate temporary persona prompts. The source role markdown is the stable persona prompt. Per-meeting context may wrap it with topic and turn rules, but must not replace or rewrite identity.
20. Do not create professional-sounding dialogue by extracting keywords or headings from persona files. Persona files are prompts/context for the speaking model, not phrase banks.

## Persona Knowledge and Memory Layer

Use this layer to make specialists behave more like experienced staff without letting any single prompt or memory file grow forever.

Per-role store path:

```text
references/personas/<division>/<slug>/
```

Each store contains:

- `profile.md`: stable identity, responsibility boundaries, and source role-card link.
- `knowledge.md`: long-lived professional learning material, frameworks, terms, examples, and source-backed notes.
- `memory.md`: recent raw task memory. Keep it short and append only entries that will be useful later.
- `memory_summary.md`: compact long-term memory summary plus the active compaction policy.

Loading rules:

- Always treat `references/roles/<division>/<slug>.md` as the behavioral source of truth.
- Read `profile.md` and `memory_summary.md` for selected roles when available.
- Read `knowledge.md` only when the task needs domain learning, examples, or prior frameworks.
- Read `memory.md` only when the user asks for recent context, when a role just worked on the same problem, or when the summary points to a recent unresolved item.

Writing rules:

- Do not write learned knowledge back into source role files.
- Do not create one large global memory for all personas.
- Add stable professional material to `knowledge.md`; add short recent task notes to `memory.md`; update `memory_summary.md` after compaction.
- Do not store secrets, credentials, private personal data, or unverifiable claims as durable memory.
- If `memory.md` exceeds 12 entries or starts becoming noisy, run `scripts/compact_persona_memory.ps1 -RoleSlug <slug> -Apply`. Use no `-RoleSlug` only when intentionally checking every persona.

## Discussion Output Modes

### Discussion Meeting

Use this for default Function 1 meetings. Casual Chinese prompts like "会议室讨论一下", "专家团讨论一下", "专家们聊聊", "你们怎么看", "随便聊", or "自己聊" affect the tone, but they do not switch the user into a separate meeting mode. The meeting remains text-first discussion live, with vote/A-B UI hidden unless the user explicitly asks for jury, PK, or multi-round voting.

Build it dynamically:

- First load the selected employees with `scripts/build_meeting_authoring_context.ps1 -Topic "<议题>"`. Treat `baseRolePrompt` as the stable persona prompt, `personaStoreContext` as long-term knowledge/memory, and `meetingRuntimeContext` as the temporary meeting wrapper.
- Decide the next speaker only after reading what has already been said.
- Let each speaker answer the live conversation using their professional judgment and speaking style.
- Agreement, disagreement, reframing, hesitation, correction, and summarization may appear only when the current conversation naturally calls for them.
- Do not assign role order by rhetorical function. A role is never "the agreeing one", "the opposing one", or "the summarizing one".
- Do not force every selected role to speak if the meeting has already reached a useful conclusion.
- Do not treat ambient states as silent filler. `nod`, `reserve`, and `thinking` are built-in speaking ambient personas; let them add short state-shaped lines when the live discussion naturally needs agreement, reservation, or hesitation.

Discussion rules:

- Do not start with a large table unless the user asks for one.
- Do not expose "Round 1 / Round 2" labels in Codex chat for casual discussion; the viewer may still use vote-round state internally.
- Prefer substantive, personal-sounding role comments over thin one-liners. Unless the user explicitly asks for a brief mode, formal participants should usually speak in a complete paragraph or at least 2 sentences.
- Experts may disagree, challenge, and persuade each other when the prior content gives them a real reason to do so.
- Avoid repeated stock openings such as `我先抛一个判断`, `我接一下`, `我来当刹车`, and similar fill-in phrases. If a role speaks twice, the second turn must change angle or answer a concrete objection.
- A line is invalid when it sounds like a smart bystander could have said it. Product must speak in product tradeoffs, engineering in implementation boundaries, testing in failure/evidence, design in user perception, orchestration in speaker/context routing, and academic roles in their own research lens.
- The goal is not total agreement on beliefs; the goal is actionable consensus.
- If there is unresolved disagreement, state it honestly and explain how it affects the next action.
- Keep the final post-meeting summary short even when the discussion is rich: `会议结论` up to 2 bullets, `实施方案` up to 3 items, and `推荐员工` up to 3 items.

### Jury Deliberation

Use this when the user wants 12怒汉, 十二怒汉, 陪审团审议, 多轮投票, 方案 PK, or a conflict-driven decision that should keep voting until everyone can accept one executable plan.

Core rules:

- The jury framework is a fixed state machine, not an optional writing style: host reads topic and A/B -> host guides vote 1 -> jurors vote -> host publishes vote 1 and guides round 1 speeches -> jurors speak -> host guides vote 2 -> jurors vote -> host publishes vote 2 and guides round 2 speeches -> jurors speak -> host guides vote 3 -> jurors vote -> repeat until vote N is unanimous -> host summary.
- Each non-unanimous vote must be followed by a separate `host-rN-start` turn that publishes the vote count and introduces round N speeches. Only juror `speak` turns may appear between `host-rN-start` and `host-vote-(N+1)`.
- The final unanimous vote must go directly to `host-final`. Do not insert more juror speeches after unanimity.
- Attach every `deliberation.voteRounds[].afterTurnId` to the host vote-control turn (`host-vote-1`, `host-vote-2`, ...), never to an expert's speech turn. Expert turns argue; host turns trigger votes, publish counts, guide rounds, and summarize.
- Employees speak freely from their persona and specialty. They may raise a new point, target one specific person for persuasion, challenge a claim, refine A or B, or propose a merged acceptance criterion.
- Do not treat majority as automatically correct. A minority argument can persuade many people if it exposes a stronger risk, cheaper path, better evidence, or clearer acceptance criterion.
- Continue voting and discussing until all visible votes are on one side or everyone explicitly accepts the same merged plan.
- If the vote does not move, the next round must attack the real blocker: cost, risk, experience, ethics, schedule, evidence, or acceptance criteria.

Visual data rules:

- Use `mode: "jury_deliberation"` and `deliberation.voteRounds` to make the viewer show A/B markers and vote counts.
- Do not write static role stance presets. Nameplate A/B markers come only from the latest visible vote round.
- Every vote round must resolve all visible non-host seats into `a` / `b` / `z`. Do not leave ambient seats missing from `votes`; do not hardcode `nod` / 对对对 to A or B. It follows the current explicit formal majority, or abstains when there is no clear majority.
- During the opening/topic-reading host turn, vote buttons must remain double-dark. The first visible vote is revealed only after the host vote-control turn finishes and the hand-vote animation reaches the button.
- A green A marker means the employee's latest visible vote is A; a red B marker means the latest visible vote is B. No marker means no visible vote for that person yet.
- On later vote rounds, only employees whose visible vote changed should show the hand-vote animation. Unchanged votes keep their marker without re-playing the hand.

### Formal Review

Use this when the user asks for a formal review, decision, ranking, vote, strategy, architecture review, launch review, investor-grade analysis, or cross-functional risk gate.

```markdown
## 本轮专家名单
| 角色 | 负责视角 | 为什么需要 |

## Round 0：主持人开场
- 问题重述:
- 成功标准:
- 关键假设:

## Round 1：初始观点
**角色名**:
观点...

## Round 2：交叉质询
**角色 A -> 角色 B**:
质询...

**角色 B 回应**:
回应...

## Round 3：修正方案
**角色名**:
修正后的建议...

## Round 4：投票 / 排名
| 角色 | 首选方案 | 反对方案 | 理由 |

## 主持人最终结论
- 最优方案:
- 次优方案:
- 暂不建议:

## 未解决分歧
| 分歧 | 支持方 | 反对方 | 需要补充的证据 |

## 下一步行动
1. ...
2. ...
3. ...
```

### Conclusion Only

Use this when the user asks for "只要结论", "简版", "摘要", "TL;DR", or a short answer.

```markdown
**结论**：
...

**理由**：
...

**下一步**：
...
```

Do not force all roles to speak unless the user explicitly asks for "全员大会", "所有角色都发言", or similar. For normal requests, select the smallest panel that can cover the issue well.

## Visual Meeting Viewer

On Codex Desktop, treat the static viewer as an optional sidecar for meeting-room triggers. Use it when it is available, but do not auto-open it and do not make the text meeting depend on it.

Viewer path:

- `assets/expert-meeting-viewer/index.html`
- `assets/expert-meeting-viewer/react-viewer/`

Launch policy:

1. When a meeting-room trigger should expose the visual sidecar, run `start_expert_panel_meeting.ps1` and require `servedSession.matches = true` before presenting a meeting link. Use the hard-coded Codex start message shape with a clickable Markdown link first, then continue the text meeting directly below it.
2. Function 1 default path is main-process live discussion: start the viewer with `scripts/start_expert_panel_meeting.ps1 -Topic "<议题>"`; append host/conclusion turns directly through `runtime/append_live_meeting_turn.ps1`; for non-host speech turns, first call `runtime/set_live_meeting_thinking.ps1`, then read `meeting-runtime.context.json` and the latest `meeting-runtime.json`, then append the generated speech through `runtime/append_live_meeting_turn.ps1`. Use vote/control Q-flow only when the user explicitly asks for jury deliberation, PK, or multi-round voting.
3. `scripts/new_visual_meeting_session.ps1`, `current-session.json`, `-UseCurrentSession`, and `-SessionFile` are developer-only legacy/smoke paths. Do not use them for user-triggered meetings.
4. Prefer the Codex built-in web preview/in-app browser by emitting the clickable link only. If the current browser already has the viewer, updating `meeting-runtime.json` lets the page transition into the new meeting.
5. `scripts/start_expert_panel_meeting.ps1` prepares the meeting page and returns `currentBrowserUrl`; it does not try to open sidebars, click the link, or type URLs.
6. Do not run `scripts/click_latest_meeting_link.ps1` as part of the default user-facing path.
7. Do not run `scripts/start_visual_meeting.ps1 -OpenDefaultBrowser` as an automatic Function 1 fallback. If the viewer server or served session cannot be confirmed, continue with the text meeting and skip the visual link.
8. If `servedSession.matches = false`, omit the visual link and continue the meeting in chat. Do not fabricate a viewer-ready status.
9. Keep the Codex chat compact but substantive while the text meeting is running. Do not paste backend preparation details unless requested; when the meeting reaches a conclusion, place the compact summary at the very end, and keep `实施方案` / `推荐员工` short.

Codex message contract:

```text
会议主题：<topic>
参会人员：主持人（会议主持）、<姓名>（<职位>）、...

可视化会议（可选旁观）：
[打开可视化会议](<viewer-url>)（手动点击打开）

以下为文字会议实录：
```

After the meeting ends:

```text
会议结论：
- <consensus item>

实施方案：
- [<id>] <title>：<deliverable>；负责人：<role>；验收：<acceptance>

推荐员工：
- <name>（<title> / <priority>）：<task>；交付：<deliverable>
```

`scripts/start_expert_panel_meeting.ps1` returns these as `codexStartMessage`, `codexLaunchBlockedMessage`, `codexFinalMessage`, `codexMessage`, `currentBrowserUrl`, `browserOpenStrategy`, `viewerLinkText`, `viewerLinkOptional`, `hardStartRequired`, and `textFallbackAllowed`. Use the message fields directly instead of rephrasing. Do not auto-click the visual link.

Data format:

- `references/VISUAL_TRANSCRIPT_SCHEMA.md`
- Runtime injection files: the single text-first meeting uses `assets/expert-meeting-viewer/art/meeting-runtime.json` by default. User-facing meetings must start with zero prewritten turns and grow through main-process append writes, or import a completed text transcript through `runtime/import_text_meeting_result.ps1`.
- Text-first import path: when the meeting is completed directly in chat, you may skip real-time append and instead import the finalized text transcript plus compact summary through `runtime/import_text_meeting_result.ps1`, then share the viewer link after import. If the text meeting was a jury/PK/voting session, import the matching `voteRounds`/`deliberation` payload at the same time; do not let the import path erase A/B markers, vote rounds, or vote animations.
- `meeting-runtime.json` is the live meeting state source of truth for light meetings. It must be updated after every appended turn and keep `runtime.status`, `runtime.hostStage`, `runtime.round`, `runtime.formalParticipants`, `runtime.ambientParticipants`, `runtime.thinking`, `runtime.queue`, `runtime.voteSnapshot`, `runtime.consensusDraft`, `runtime.unresolvedDisagreements`, and `runtime.nextQuestions` current.
- Required post-meeting chat outcome fields: `summary.consensus`, `summary.nextActions`, `summary.implementationPlan`, `summary.recommendedWorkers`, and optionally `summary.futureAnimationIdea`. These fields are for Codex chat synchronization and Function 2 handoff, not for a viewer-side meeting-products panel.

Visual rules:

- Default layout is `vertical-long-table`: moderator at the top center, experts seated on the left and right sides.
- Do not use the earlier horizontal-table interpretation for meeting layouts.
- Keep the viewer data compact: selected participants plus timeline events, not the full role library.
- When the user is tuning viewer layout, vote controls, seat/nameplate placement, or asks to relaunch a meeting for visual adjustment, fill every visible seat slot with participants or calibration stand-ins. Empty chairs make it impossible to adjust their nameplates and controls.
- Use `speak` for normal turns, `challenge` when one role directly pushes back on another, and `consensus` or `decision` for convergence.
- Prefer generating an empty meeting-room base image first, then reverse-positioning seat anchors from the approved image. Use `assets/expert-meeting-viewer/prompts/PROMPT_meeting_room_base_v1.0.0.md`.
- The viewer uses runtime layering by default: room background, chair back, independent cow agent, chair front, table occluder, and speaker card. See `assets/expert-meeting-viewer/art/asset-manifest-v1.1.0.json`.
- Generate characters as separate sprite layers only after the room base and anchors are approved. Keep the base model count to five and follow `assets/expert-meeting-viewer/art/model-action-manifest-v1.2.0.json`.
- Do not use pure-black silhouettes with large colored body bars. The current visual direction is low-saturation gray/white cow experts, small accessories, and external labels.
- For art upgrades, do not keep polishing the viewer screenshot as if it were the final art. First follow `assets/expert-meeting-viewer/art/production-manifest-v1.3.0.json` and produce a figure-3 style asset sheet: empty room, table, chair layers, five cow body seeds, action strips, accessories, and UI feedback pieces.
- When the user asks for "图三", "素材表", "资产板", "五体型", or "模型动作系统", start from `assets/expert-meeting-viewer/art/asset-board-layout-v1.3.0.json` and `assets/expert-meeting-viewer/prompts/PROMPT_five_body_sprite_asset_board_v1.3.0.md` before touching the viewer UI.
- Current SVG layer assets are placeholders for anchor and occlusion validation. Do not describe them as final bitmap art until the matching production-manifest assets exist.
- Table/chair raster assets may be generated or replaced later, but the first-class contract is the JSON transcript schema, measured seat anchors, stable layer order, and the production manifest.

## Safety and Legality

For monetization, automation, growth, scraping, advertising, finance, crypto, outreach, legal, medical, security, or platform-policy-sensitive tasks:

- Do not help with fraud, spam, credential abuse, platform manipulation, botting, fake engagement, deception, evasion of rate limits, bypassing paywalls, privacy invasion, or unlawful scraping.
- Prefer opt-in, permissioned, transparent, and auditable workflows.
- Include compliance and ethics review when the proposal affects users, money, advertising claims, personal data, regulated products, or platform terms.
- Separate "research hypothesis" from "verified fact." Browse or request current evidence when the answer depends on recent market conditions, platform rules, prices, laws, or tool availability.
- For revenue ideas, always include unit economics, customer acquisition assumptions, validation steps, and reasons the plan might fail.

## Optional Presets

For most requests, dynamically select roles from the index based on the user's actual question.

When the user specifically asks about "互联网自动化赚钱", "自动赚钱", "AI 自动化变现", "passive income automation", or similar, read `references/presets/internet-automation-monetization.md` first. This is only one optional preset, not the default behavior for unrelated questions.

Internet automation monetization preset panel:

- Agents Orchestrator
- Product Trend Researcher
- Product Manager
- Automation Governance Architect
- Specialized Workflow Architect
- AI Engineer
- Data Engineer
- Frontend Developer
- Growth Hacker
- SEO Specialist
- Content Creator
- AI Citation Strategist
- Cross-Border E-Commerce Specialist
- Sales Outreach
- Pipeline Analyst
- Financial Analyst
- Compliance Auditor
- Legal Compliance Checker
- Reality Checker
- Evidence Collector

Internet automation monetization preset output:

- selected panel and why
- 3-7 candidate business models
- deliberation notes by role
- disqualified ideas and why
- ranked Top 3
- 7-day validation plan
- 30-day build-and-sell plan
- automation architecture with human checkpoints
- risk and compliance review
- metrics dashboard

## Coordination Rules

- Keep the moderator voice distinct from role viewpoints.
- Attribute role perspectives using role names, but do not claim actual background execution happened unless tools or sub-agents were explicitly run.
- If true parallel sub-agents are available and the user explicitly asks for agents to work in parallel, delegate bounded tasks to sub-agents; otherwise simulate the panel inside one Codex response using the loaded role references.
- Prefer concrete deliverables: tables, checklists, architecture sketches, validation scripts, landing page briefs, outreach drafts, or experiment backlogs.
- When the user asks for implementation, switch from discussion to execution only after the target, boundaries, dependencies, and completion criteria are clear.


