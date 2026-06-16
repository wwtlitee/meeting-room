export const meetingScript = [
  {
    id: 'opening',
    speakerId: 'host',
    phase: '议题开场',
    type: 'speak',
    screenTitle: '工具边界复盘',
    screenStatus: 'OPENING',
    text: '这次开会复盘工具接入边界。前提很简单：任何外部能力都要先确认归属，不能因为方便就塞进不该塞的模块。'
  },
  {
    id: 'product-scope',
    speakerId: 'product-manager',
    phase: '产品判断',
    type: 'speak',
    screenTitle: '先定归属',
    screenStatus: 'POINT',
    text: '我建议先把能力分成独立工具、会议室流程和可视化会议三类。属于工具的就独立调用，不要污染会议室的人格资料层。'
  },
  {
    id: 'ai-routing',
    speakerId: 'engineering-ai-engineer',
    phase: '模型路由',
    type: 'speak',
    screenTitle: '独立网关',
    screenStatus: 'ROUTE',
    text: '技术上应该做成独立 provider。它可以处理摘要、改写、草稿生成，但调用入口和配置都放在自己的 skill 里。'
  },
  {
    id: 'backend-adapter',
    speakerId: 'engineering-backend-architect',
    phase: '后端方案',
    type: 'challenge',
    screenTitle: '不要写死',
    screenStatus: 'BUILD',
    text: '我反对把外部调用散落到业务代码里。先做统一接口：model、messages、temperature、timeout、fallback。Key 只走本机私有配置。'
  },
  {
    id: 'workflow-gates',
    speakerId: 'specialized-workflow-architect',
    phase: '流程分层',
    type: 'challenge',
    screenTitle: '分层使用',
    screenStatus: 'FLOW',
    text: '流程上分三层：外部工具只产草稿；主线程负责复核；真正写入项目或 skill 前必须明确目标路径和边界。'
  },
  {
    id: 'security-limits',
    speakerId: 'engineering-security-engineer',
    phase: '安全边界',
    type: 'speak',
    screenTitle: '隐私红线',
    screenStatus: 'SECURITY',
    text: '安全上先立红线：浏览器端不放 API Key；私有配置不进报告；外发内容必须裁剪，只传任务所需片段。'
  },
  {
    id: 'api-testing',
    speakerId: 'testing-api-tester',
    phase: 'API 验证',
    type: 'challenge',
    screenTitle: '先测契约',
    screenStatus: 'TEST',
    text: '落地前先做契约测试：鉴权、超时、限流、错误码、并发、长文本、中文输出稳定性。失败时必须回退，不要让会议卡死。'
  },
  {
    id: 'docs-runbook',
    speakerId: 'engineering-technical-writer',
    phase: '文档要求',
    type: 'speak',
    screenTitle: '配置说明',
    screenStatus: 'DOC',
    text: '文档要写清楚：配置放哪里、哪些任务会调用外部能力、哪些内容绝不外发、如何看调用日志、如何一键停用。'
  },
  {
    id: 'host-close',
    speakerId: 'host',
    phase: '主持收束',
    type: 'speak',
    screenTitle: '结论',
    screenStatus: 'DONE',
    text: '结论：外部能力要独立成 skill。会议室保持会议室，工具保持工具；跨模块写入必须由用户明确指定。'
  }
];

export const roleBySeatLabel = {
  主持人: 'host',
  产品经理: 'product-manager',
  AI工程师: 'engineering-ai-engineer',
  后端架构师: 'engineering-backend-architect',
  工作流架构师: 'specialized-workflow-architect',
  安全工程师: 'engineering-security-engineer',
  API测试工程师: 'testing-api-tester',
  技术文档工程师: 'engineering-technical-writer'
};

export const roleMeta = {
  host: { name: '主持人', title: '会议主持', lane: 'center' },
  'product-manager': { name: '产品经理', title: 'Product Manager', lane: 'left' },
  'engineering-ai-engineer': { name: 'AI工程师', title: 'AI Engineer', lane: 'right' },
  'engineering-backend-architect': { name: '后端架构师', title: 'Backend Architect', lane: 'left' },
  'specialized-workflow-architect': { name: '工作流架构师', title: 'Workflow Architect', lane: 'right' },
  'engineering-security-engineer': { name: '安全工程师', title: 'Security Engineer', lane: 'left' },
  'testing-api-tester': { name: 'API测试工程师', title: 'API Tester', lane: 'right' },
  'engineering-technical-writer': { name: '技术文档工程师', title: 'Technical Writer', lane: 'left' }
};

export const faceAnchors = {
  standard: {
    front: { eyes: { x: 48.6, y: 18.9 }, mouth: { x: 48.6, y: 34.1 } },
    left: { eyes: { x: 59.3, y: 14.9 }, mouth: { x: 67.7, y: 29.8 } },
    right: { eyes: { x: 37, y: 11.7 }, mouth: { x: 33.3, y: 28.8 } }
  },
  round: {
    front: { eyes: { x: 50, y: 27 }, mouth: { x: 50, y: 39 } },
    left: { eyes: { x: 63.2, y: 12.5 }, mouth: { x: 69.3, y: 29 } },
    right: { eyes: { x: 39.5, y: 12.2 }, mouth: { x: 30.1, y: 25.4 } }
  },
  tall: {
    front: { eyes: { x: 50, y: 24 }, mouth: { x: 50, y: 35 } },
    left: { eyes: { x: 62.6, y: 11.1 }, mouth: { x: 62.6, y: 26.8 } },
    right: { eyes: { x: 35.5, y: 13.9 }, mouth: { x: 34.3, y: 28 } }
  },
  small: {
    front: { eyes: { x: 50, y: 28 }, mouth: { x: 50, y: 39 } },
    left: { eyes: { x: 63.3, y: 7.8 }, mouth: { x: 67.8, y: 22.8 } },
    right: { eyes: { x: 39.1, y: 7.8 }, mouth: { x: 31.3, y: 20.2 } }
  },
  sturdy: {
    front: { eyes: { x: 50, y: 26 }, mouth: { x: 50, y: 38 } },
    left: { eyes: { x: 62.8, y: 12.5 }, mouth: { x: 65.6, y: 28.8 } },
    right: { eyes: { x: 38.7, y: 13.5 }, mouth: { x: 35.4, y: 28.5 } }
  }
};

export function getDefaultFaceAnchor(body, direction) {
  return faceAnchors[body]?.[direction] || faceAnchors.standard[direction] || faceAnchors.standard.front;
}
