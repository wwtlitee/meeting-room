import { useEffect, useMemo, useRef, useState } from 'react';
import {
  getSeatHeadAsset,
  getSeatPlacement,
  emptySeats,
  meetingSeats,
  occupiedSeats,
  stageMetrics,
  tableAsset
} from './meetingSceneData.js';
import {
  getDefaultFaceAnchor,
  meetingScript as fallbackMeetingScript,
  roleBySeatLabel,
  roleMeta as fallbackRoleMeta
} from './meetingAnimationData.js';
import DotGrid from './react-bits/DotGrid/DotGrid.jsx';
import LetterGlitch from './react-bits/LetterGlitch/LetterGlitch.jsx';
import { generatedRoleExpressionProfiles } from './roleExpressionProfiles.generated.js';
import sleepBubbleAsset from './ambient-assets/sleep-bubble.png';
import chatFrame1 from './ambient-assets/chat-1.png';
import chatFrame2 from './ambient-assets/chat-2.png';
import chatFrame3 from './ambient-assets/chat-3.png';
import videoFrame1 from './ambient-assets/video-1.png';
import videoFrame2 from './ambient-assets/video-2.png';
import videoFrame3 from './ambient-assets/video-3.png';
import gameFrame1 from './ambient-assets/game-1.png';
import gameFrame2 from './ambient-assets/game-2.png';
import gameFrame3 from './ambient-assets/game-3.png';

const DEFAULT_MEETING_TOPIC = '工具边界复盘';
const DEFAULT_MEETING_SCRIPT = fallbackMeetingScript;
const EMPTY_LIVE_TURN = {
  id: 'live-waiting',
  speakerId: 'host',
  phase: '等待导入',
  type: 'speak',
  screenTitle: '文字会议待导入',
  screenStatus: 'IMPORT',
  text: '当前可先完成文字会议，结束后再把发言记录和精简结论导入这里展示。'
};
const DEFAULT_ROLE_META = fallbackRoleMeta;
const DEFAULT_SESSION_URL = 'current-session.json';
const SESSION_ACTIVE_POLL_MS = 1000;
const SESSION_IDLE_POLL_MS = 10000;
const SESSION_HIDDEN_POLL_MS = 30000;
const TYPE_INITIAL_DELAY_MS = 360;
const TYPE_MS_PER_CHARACTER = 86;
const TURN_HOLD_MS = 1500;
const TYPE_TICK_MS = 43;
const VOTE_REVEAL_DELAY_MS = 2450;
const VOTE_TURN_EXTRA_HOLD_MS = 1700;
const MEETING_RESULT_BRIDGE_URL = 'http://127.0.0.1:5176/visual-meeting-result';
const MEETING_HISTORY_STORAGE_KEY = 'meeting-room-meeting-history-v1';
const NAMEPLATE_CALIBRATION_STORAGE_KEY = 'meeting-room-nameplate-calibration-v2';
const NAMEPLATE_CALIBRATION_OPEN_KEY = 'meeting-room-nameplate-calibration-open-v2';
const NAMEPLATE_VISUAL_SCALE = 0.62;
const MEETING_HISTORY_LIMIT = 100;
const TRANSITION_STEP_MS = 1150;
const TRANSITION_FADE_OUT_MS = 650;
const SCREEN_TOPIC_MAX_CHARS = 15;
const SCREEN_OPTION_LABEL_MAX_CHARS = 14;
const SCREEN_OPTION_DETAIL_MAX_CHARS = 24;
const VOTE_ARM_TARGET_LIFT_Y = 8;
const TRANSITION_STEPS_WITH_PREVIOUS = ['正在整理会议室', '正在梳理会议流程', '会议开启'];
const TRANSITION_STEPS_FRESH = ['正在整理会议室', '正在梳理会议流程', '会议开启'];
const AMBIENT_DEBUG_SLOT_IDS = ['right3', 'left4', 'right4', 'left5', 'right5'];
const AMBIENT_DECOR_DEFAULTS = {
  right3: {
    zzz: { x: 694, y: 367.4, rotate: 8 },
    bubble: { x: 664, y: 399.8, scale: 1.6, rotate: 12 },
    phone: { x: 655.2, y: 426.2, rotate: -69 }
  },
  left4: {
    zzz: { x: 414, y: 471.4, rotate: -8 },
    bubble: { x: 450, y: 503.8, scale: 1.4, rotate: -12, mirrorX: true },
    phone: { x: 457.2, y: 539, rotate: 69 }
  },
  right4: {
    zzz: { x: 703, y: 470.4, rotate: 8 },
    bubble: { x: 678, y: 501.8, scale: 1.4, rotate: 12 },
    phone: { x: 661.6, y: 532.7, rotate: -64 }
  },
  left5: {
    zzz: { x: 400, y: 586.4, rotate: -8 },
    bubble: { x: 437, y: 616.8, scale: 1.5, rotate: -12, mirrorX: true },
    phone: { x: 453.8, y: 642.8, rotate: 44 }
  },
  right5: {
    zzz: { x: 716, y: 582.4, rotate: 8 },
    bubble: { x: 679, y: 617.8, scale: 1.5, rotate: 12 },
    phone: { x: 671.8, y: 639.4, rotate: -39 }
  }
};
const AMBIENT_PHONE_SCREEN_BY_SLOT = {
  right3: 'chat',
  left4: 'video',
  right4: 'game',
  left5: 'chat',
  right5: 'video'
};
const PHONE_FRAME_ASSETS = {
  chat: [chatFrame1, chatFrame2, chatFrame3],
  video: [videoFrame1, videoFrame2, videoFrame3, videoFrame1],
  game: [gameFrame1, gameFrame2, gameFrame3]
};
const PHONE_SCREEN_TIMING_BY_SLOT = {
  right3: { delay: '-0.2s', duration: '3s' },
  left4: { delay: '-1.1s', duration: '6s' },
  right4: { delay: '-0.6s', duration: '4.8s' },
  left5: { delay: '-1.6s', duration: '3s' },
  right5: { delay: '-2.4s', duration: '6s' }
};
const nameplatePlacements = {
  host: { x: 561, y: 131, rotate: 0, tilt: 0, width: 92 },
  left1: { x: 503.6, y: 238.5, rotate: -3, tilt: -4, width: 122 },
  right1: { x: 621.1, y: 235, rotate: 2, tilt: 4, width: 111 },
  left2: { x: 497.9, y: 347.6, rotate: -2, tilt: -4, width: 111 },
  right2: { x: 620.8, y: 351.2, rotate: 2, tilt: 4, width: 111 },
  left3: { x: 489.4, y: 454.3, rotate: -2, tilt: -4, width: 106 },
  right3: { x: 627.4, y: 463.3, rotate: 2, tilt: 4, width: 116 },
  left4: { x: 486.7, y: 567.1, rotate: -2, tilt: -4, width: 111 },
  right4: { x: 633.2, y: 570.1, rotate: 2, tilt: 4, width: 111 },
  left5: { x: 486.4, y: 664, rotate: -2, tilt: -4, width: 111 },
  right5: { x: 637.5, y: 662.4, rotate: 2, tilt: 4, width: 111 }
};
const seatPlacements = {
  left1: { x: 434 },
  right1: { x: 689 },
  left2: { x: 423 },
  right2: { x: 694 },
  left3: { x: 416 },
  right3: { x: 702 },
  left4: { x: 411 }
};
const voteButtonPlacements = {
  host: { x: 560, y: 154, rotate: 0, scale: 1 },
  left1: { x: 469.6, y: 211.3, rotate: -90, scale: 0.56 },
  right1: { x: 652.7, y: 208, rotate: 88, scale: 0.56 },
  left2: { x: 465.1, y: 319.2, rotate: -93, scale: 0.56 },
  right2: { x: 655, y: 326.8, rotate: 88, scale: 0.56 },
  left3: { x: 461.7, y: 430.6, rotate: -93, scale: 0.56 },
  right3: { x: 658.2, y: 433.2, rotate: 88, scale: 0.56 },
  left4: { x: 455.2, y: 539, rotate: -88, scale: 0.56 },
  right4: { x: 662.6, y: 540.7, rotate: 88, scale: 0.56 },
  left5: { x: 451.8, y: 643.8, rotate: -93, scale: 0.56 },
  right5: { x: 670.8, y: 643.4, rotate: 88, scale: 0.56 }
};
const voteArmPlacements = {
  left1: { shoulderOffsetX: 5.3, shoulderOffsetY: -6.7, restOffsetX: 8.2, restOffsetY: 30.6 },
  right1: { shoulderOffsetX: -6.3, shoulderOffsetY: -14.7, targetX: 650.7, targetY: 208, restOffsetX: -7.2, restOffsetY: 30.6 },
  left2: { shoulderOffsetX: 8, shoulderOffsetY: -16.3, restOffsetX: 9.2, restOffsetY: 31.6 },
  right2: { shoulderOffsetX: -6, shoulderOffsetY: -14.3 },
  left3: { shoulderOffsetX: 10.8, shoulderOffsetY: -16.9 },
  right3: { shoulderOffsetX: -11.8, shoulderOffsetY: -17.9 },
  left4: { shoulderOffsetX: 7.6, shoulderOffsetY: -26.5 },
  right4: { shoulderOffsetX: -5.6, shoulderOffsetY: -31.5, targetX: 661.6, targetY: 540.7 },
  left5: { shoulderOffsetX: 12.3, shoulderOffsetY: -30.2 },
  right5: { shoulderOffsetX: -10.3, shoulderOffsetY: -30.2 }
};
const screenPlacement = { x: 560, y: 63, width: 560, height: 124 };
const seatMotionProfiles = {
  host: { blinkDuration: 5.2, blinkDelay: -0.4, voteDuration: 1.04, voteDelay: 0.05 },
  left1: { blinkDuration: 4.1, blinkDelay: -1.2, voteDuration: 0.92, voteDelay: 0 },
  right1: { blinkDuration: 5.7, blinkDelay: -2.6, voteDuration: 1.18, voteDelay: 0.12 },
  left2: { blinkDuration: 3.8, blinkDelay: -0.7, voteDuration: 1.06, voteDelay: 0.22 },
  right2: { blinkDuration: 6.1, blinkDelay: -3.1, voteDuration: 0.98, voteDelay: 0.34 },
  left3: { blinkDuration: 4.6, blinkDelay: -2.0, voteDuration: 1.24, voteDelay: 0.08 },
  right3: { blinkDuration: 5.0, blinkDelay: -0.9, voteDuration: 0.9, voteDelay: 0.28 },
  left4: { blinkDuration: 6.4, blinkDelay: -3.7, voteDuration: 1.14, voteDelay: 0.18 },
  right4: { blinkDuration: 4.3, blinkDelay: -1.6, voteDuration: 1.3, voteDelay: 0.04 },
  left5: { blinkDuration: 5.9, blinkDelay: -2.3, voteDuration: 1.02, voteDelay: 0.3 },
  right5: { blinkDuration: 3.6, blinkDelay: -0.3, voteDuration: 1.2, voteDelay: 0.16 }
};
const defaultExpressionProfile = { eyeVariant: 'dot', mouthVariant: 'flat' };
const roleExpressionProfiles = {
  host: { eyeVariant: 'dot', mouthVariant: 'flat' },
  ...generatedRoleExpressionProfiles,
  'ambient-sleeper': { eyeVariant: 'half', mouthVariant: 'flat' },
  'ambient-nodder': { eyeVariant: 'wide', mouthVariant: 'smile' },
  'ambient-reserved': { eyeVariant: 'narrow', mouthVariant: 'firm' },
  'ambient-thinking': { eyeVariant: 'half', mouthVariant: 'soft' },
  'ambient-phone': { eyeVariant: 'half', mouthVariant: 'flat' },
  'design-ui-designer': { eyeVariant: 'wide', mouthVariant: 'smile' },
  'design-system-architect': { eyeVariant: 'narrow', mouthVariant: 'long' },
  'game-asset-artist': { eyeVariant: 'round', mouthVariant: 'smile' },
  'icon-designer': { eyeVariant: 'bean', mouthVariant: 'firm' },
  'motion-graphics-director': { eyeVariant: 'surprised', mouthVariant: 'small-o' },
  'academic-psychologist': { eyeVariant: 'half', mouthVariant: 'soft' },
  'engineering-frontend-developer': { eyeVariant: 'focus', mouthVariant: 'long' },
  'visual-qa-inspector': { eyeVariant: 'narrow', mouthVariant: 'firm' },
  'product-manager': { eyeVariant: 'wide', mouthVariant: 'flat' },
  'design-ux-architect': { eyeVariant: 'half', mouthVariant: 'soft' },
  'technical-artist': { eyeVariant: 'focus', mouthVariant: 'small-o' },
  'browser-game-producer': { eyeVariant: 'bean', mouthVariant: 'flat' },
  'game-ui-hud-designer': { eyeVariant: 'round', mouthVariant: 'smile' },
  'game-feel-designer': { eyeVariant: 'wide', mouthVariant: 'smile' }
};
const roleExpressionPatternProfiles = [
  { pattern: /qa|inspector|reviewer|auditor|reality/i, profile: { eyeVariant: 'narrow', mouthVariant: 'firm' } },
  { pattern: /psychologist|researcher|architect|system/i, profile: { eyeVariant: 'half', mouthVariant: 'soft' } },
  { pattern: /artist|designer|visual|creative|story/i, profile: { eyeVariant: 'round', mouthVariant: 'smile' } },
  { pattern: /motion|feel|animation|gameplay/i, profile: { eyeVariant: 'surprised', mouthVariant: 'small-o' } },
  { pattern: /icon|brand|identity/i, profile: { eyeVariant: 'bean', mouthVariant: 'firm' } },
  { pattern: /engineer|developer|technical|frontend/i, profile: { eyeVariant: 'focus', mouthVariant: 'long' } },
  { pattern: /manager|producer|product|shepherd/i, profile: { eyeVariant: 'wide', mouthVariant: 'flat' } }
];

function clampPercent(value) {
  return Math.max(4, Math.min(96, Math.round(value * 10) / 10));
}

function clampNumber(value, min, max) {
  return Math.max(min, Math.min(max, Math.round(value)));
}

function clampStageValue(value, min, max) {
  return Math.max(min, Math.min(max, Math.round(value * 10) / 10));
}

function clampDecimal(value, min, max, decimals = 2) {
  const factor = 10 ** decimals;
  return Math.max(min, Math.min(max, Math.round(value * factor) / factor));
}

function readStoredJson(key, fallback) {
  if (typeof window === 'undefined') {
    return fallback;
  }

  try {
    const stored = window.localStorage.getItem(key);
    return stored ? JSON.parse(stored) : fallback;
  } catch {
    return fallback;
  }
}

function usePageVisible() {
  const [pageVisible, setPageVisible] = useState(() => {
    if (typeof document === 'undefined') {
      return true;
    }

    return document.visibilityState !== 'hidden';
  });

  useEffect(() => {
    if (typeof document === 'undefined') {
      return undefined;
    }

    const updateVisibility = () => setPageVisible(document.visibilityState !== 'hidden');
    document.addEventListener('visibilitychange', updateVisibility);
    return () => document.removeEventListener('visibilitychange', updateVisibility);
  }, []);

  return pageVisible;
}

function normalizeStoredLayoutOverrides(overrides) {
  if (!overrides || typeof overrides !== 'object' || Array.isArray(overrides)) {
    return {};
  }

  const { voteHands, ambientCalibrations, ...rest } = overrides;
  const ambientDecor = rest.ambientDecor && typeof rest.ambientDecor === 'object' && !Array.isArray(rest.ambientDecor)
    ? rest.ambientDecor
    : ambientCalibrations && typeof ambientCalibrations === 'object' && !Array.isArray(ambientCalibrations)
      ? ambientCalibrations
      : undefined;
  if (ambientDecor) {
    rest.ambientDecor = ambientDecor;
  }
  return rest;
}

function formatMeetingTime(value) {
  try {
    return new Intl.DateTimeFormat('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }).format(new Date(value));
  } catch {
    return '未知时间';
  }
}

function getMeetingHistoryTime(meeting) {
  return meeting?.loadedAt || meeting?.startedAt;
}

function truncateChars(value, maxChars) {
  const chars = Array.from(String(value || '').trim());
  if (chars.length <= maxChars) {
    return chars.join('');
  }

  return `${chars.slice(0, Math.max(1, maxChars - 1)).join('')}…`;
}

function limitChars(value, maxChars) {
  return Array.from(String(value || '').trim()).slice(0, maxChars).join('');
}

function compactQuestionTopic(topic) {
  let compact = String(topic || '')
    .replace(/\s+/g, ' ')
    .replace(/[“”"']/g, '')
    .trim();

  if (/utf-?8/i.test(compact) && /\bBOM\b/i.test(compact)) {
    if (/有\s*BOM|没有\s*BOM|无\s*BOM|带\s*BOM|不带\s*BOM/i.test(compact)) {
      return 'UTF-8 BOM取舍';
    }
    return 'UTF-8 BOM';
  }

  compact = compact
    .replace(/到底是/g, '')
    .replace(/到底/g, '')
    .replace(/好还是/g, '或')
    .replace(/有没有/g, '有无')
    .replace(/要不要/g, '是否')
    .replace(/该不该/g, '是否')
    .replace(/是否需要/g, '是否')
    .replace(/讨论一下/g, '')
    .replace(/开个会/g, '')
    .replace(/开会/g, '')
    .replace(/陪审团模式/g, '')
    .replace(/陪审团/g, '')
    .replace(/会议/g, '')
    .replace(/\s+/g, '');

  return compact;
}

function getCompactScreenTopic(topic) {
  const normalized = String(topic || DEFAULT_MEETING_TOPIC).replace(/\s+/g, ' ').trim();
  const pathTrimmed = normalized.replace(/[A-Za-z]:\\(?:[^\\/:：]+\\)*([^\\/:：\s]+)\s*/g, '$1 ');
  const primary = (pathTrimmed.split(/[：:]/)[0] || pathTrimmed)
    .replace(/[“”"']/g, '')
    .replace(/\b(application|app)\b/gi, '')
    .replace(/项目优化讨论会/g, '优化会')
    .replace(/优化讨论会/g, '优化会')
    .replace(/优化方向/g, '优化会')
    .replace(/讨论会/g, '会')
    .replace(/\s+/g, ' ')
    .trim();
  const meetingType = /陪审|jury|12怒汉/i.test(normalized)
    ? '陪审会'
    : /评审|review/i.test(normalized)
      ? '评审会'
      : /优化|方向|upgrade|improve/i.test(normalized)
        ? '优化会'
        : '会议';

  if (/记忆对话/.test(primary)) {
    const productName = /\bdeadman\b/i.test(primary) ? 'deadman 记忆对话' : '记忆对话';
    return limitChars(`${productName}${meetingType}`, SCREEN_TOPIC_MAX_CHARS);
  }

  const compactQuestion = compactQuestionTopic(primary || pathTrimmed || DEFAULT_MEETING_TOPIC);
  return limitChars(compactQuestion || primary || pathTrimmed || DEFAULT_MEETING_TOPIC, SCREEN_TOPIC_MAX_CHARS);
}

function normalizeVoteSide(value) {
  const side = String(value || '').trim().toUpperCase();
  if (['A', 'SIDE_A', '方案A', '支持A', 'GREEN'].includes(side)) {
    return 'a';
  }
  if (['B', 'SIDE_B', '方案B', '支持B', 'RED'].includes(side)) {
    return 'b';
  }
  if (['Z', 'ABSTAIN', '弃权', '保留', 'RESERVE'].includes(side)) {
    return 'z';
  }

  return '';
}

function normalizeDeliberationConfig(deliberation) {
  if (!deliberation || typeof deliberation !== 'object' || Array.isArray(deliberation)) {
    return null;
  }

  return {
    ...deliberation,
    enabled: deliberation.enabled !== false,
    labelA: getDeliberationOptionLabel(deliberation, 'a'),
    labelB: getDeliberationOptionLabel(deliberation, 'b'),
    labelZ: getDeliberationOptionLabel(deliberation, 'z'),
    detailA: getDeliberationOptionDetail(deliberation, 'a'),
    detailB: getDeliberationOptionDetail(deliberation, 'b'),
    detailZ: getDeliberationOptionDetail(deliberation, 'z')
  };
}

function stripOptionPrefix(value) {
  return String(value || '')
    .replace(/^\s*(方案\s*)?[AB]\s*[：:、.\-\s]+/i, '')
    .trim();
}

function getDeliberationOptionLabel(deliberation, side) {
  const upperSide = side.toUpperCase();
  const labelKey = `label${upperSide}`;
  const labels = deliberation?.optionLabels || deliberation?.labels || {};
  const direct = deliberation?.[labelKey] || deliberation?.[`${side}Label`] || labels?.[side] || labels?.[upperSide];

  if (direct) {
    const directLabel = stripOptionPrefix(direct);
    if (directLabel && !new RegExp(`^方案\\s*${upperSide}$`, 'i').test(directLabel)) {
      return truncateChars(directLabel, SCREEN_OPTION_LABEL_MAX_CHARS);
    }
  }

  const option = stripOptionPrefix(getDeliberationOptionText(deliberation, side));
  const primary = option.split(/[，。；;,.：:]/)[0] || option;

  return truncateChars(primary || `方案${upperSide}`, SCREEN_OPTION_LABEL_MAX_CHARS);
}

function getDeliberationOptionText(deliberation, side) {
  const upperSide = side.toUpperCase();
  const optionKey = `option${upperSide}`;
  const options = deliberation?.options || deliberation?.optionDetails || {};

  return deliberation?.[optionKey]
    || deliberation?.[`${side}Option`]
    || options?.[side]
    || options?.[upperSide]
    || '';
}

function getDeliberationOptionDetail(deliberation, side) {
  const option = stripOptionPrefix(getDeliberationOptionText(deliberation, side));
  const parts = option.split(/[：:]/).map((part) => part.trim()).filter(Boolean);
  const detail = parts.length > 1 ? parts.slice(1).join('：') : option.split(/[。；;.]/).slice(1).join('；');

  return detail ? truncateChars(detail, SCREEN_OPTION_DETAIL_MAX_CHARS) : '';
}

function isJuryDeliberationMeeting(meeting) {
  return meeting?.mode === 'jury_deliberation'
    || meeting?.mode === 'twelve_angry_men'
    || Array.isArray(meeting?.deliberation?.voteRounds);
}

function normalizeVoteMap(votes, allowedRoleIds = null) {
  const sides = {};
  const allowed = allowedRoleIds ? new Set(allowedRoleIds) : null;

  if (!votes || typeof votes !== 'object' || Array.isArray(votes)) {
    return sides;
  }

  Object.entries(votes).forEach(([roleId, side]) => {
    const normalized = normalizeVoteSide(side);
    if (normalized && roleId !== 'host' && (!allowed || allowed.has(roleId))) {
      sides[roleId] = normalized;
    }
  });

  return sides;
}

function getMeetingVoterIds(meeting) {
  return (Array.isArray(meeting?.participants) ? meeting.participants : [])
    .filter((speakerId) => speakerId && speakerId !== 'host');
}

function getDominantExplicitFormalVoteSide(votes, roleMeta = {}) {
  const counts = { a: 0, b: 0 };
  Object.entries(votes || {}).forEach(([roleId, side]) => {
    if (roleMeta?.[roleId]?.ambientState) {
      return;
    }
    if (side === 'a' || side === 'b') {
      counts[side] += 1;
    }
  });

  if (counts.a > counts.b) {
    return 'a';
  }
  if (counts.b > counts.a) {
    return 'b';
  }
  return 'z';
}

function getAmbientDefaultVoteSide(roleMeta, roleId, explicitVotes) {
  const meta = roleMeta?.[roleId] || {};
  const state = String(meta.ambientState || '').trim().toLowerCase();
  if (!state) {
    return 'z';
  }

  const dominantFormalSide = getDominantExplicitFormalVoteSide(explicitVotes, roleMeta);
  if (state === 'nod') {
    return dominantFormalSide;
  }

  const ambientVote = normalizeVoteSide(meta.ambientVote);
  return ambientVote || 'z';
}

function getVoteRoundActivationIndex(round, turns, fallbackIndex) {
  if (typeof round?.afterTurnIndex === 'number') {
    return round.afterTurnIndex;
  }
  if (typeof round?.beforeTurnIndex === 'number') {
    return round.beforeTurnIndex - 1;
  }
  if (round?.afterTurnId) {
    const index = turns.findIndex((turn) => turn.id === round.afterTurnId);
    return index >= 0 ? index : fallbackIndex;
  }
  if (round?.beforeTurnId) {
    const index = turns.findIndex((turn) => turn.id === round.beforeTurnId);
    return index >= 0 ? index - 1 : fallbackIndex;
  }
  if (typeof round?.turnIndex === 'number') {
    return round.turnIndex;
  }

  return fallbackIndex;
}

function getVoteRoundsWithActivation(meeting) {
  const voteRounds = Array.isArray(meeting?.deliberation?.voteRounds) ? meeting.deliberation.voteRounds : [];
  if (voteRounds.length === 0) {
    return [];
  }

  const turns = getMeetingTurns(meeting);
  return voteRounds
    .map((round, index) => ({
      ...round,
      roundIndex: index,
      activationIndex: getVoteRoundActivationIndex(round, turns, index === 0 ? 0 : turns.length + index)
    }));
}

function getVoteRoundForIndex(meeting, currentIndex) {
  return getVoteRoundsWithActivation(meeting)
    .find((round) => round.activationIndex === currentIndex) || null;
}

function getVisibleVoteRound(meeting, currentIndex, includeCurrent = false) {
  return getVoteRoundsWithActivation(meeting)
    .filter((round) => round.activationIndex < currentIndex || (includeCurrent && round.activationIndex === currentIndex))
    .sort((left, right) => right.activationIndex - left.activationIndex)
    [0] || null;
}

function getJuryVotesForRound(meeting, round) {
  if (!round) {
    return {};
  }

  const voterIds = getMeetingVoterIds(meeting);
  const roleMeta = getMeetingRoleMeta(meeting);
  const explicitVotes = normalizeVoteMap(round?.votes, voterIds);

  return Object.fromEntries(
    voterIds.map((roleId) => [
      roleId,
      explicitVotes[roleId] || getAmbientDefaultVoteSide(roleMeta, roleId, explicitVotes)
    ])
  );
}

function getJuryVotesForIndex(meeting, currentIndex, includeCurrent = false) {
  if (!isJuryDeliberationMeeting(meeting)) {
    return {};
  }

  return getJuryVotesForRound(meeting, getVisibleVoteRound(meeting, currentIndex, includeCurrent));
}

function getJuryVoteAnimationMapForRound(meeting, visibleRound) {
  if (!isJuryDeliberationMeeting(meeting)) {
    return {};
  }

  if (!visibleRound) {
    return {};
  }

  const currentVotes = getJuryVotesForRound(meeting, visibleRound);
  const voteRounds = Array.isArray(meeting?.deliberation?.voteRounds) ? meeting.deliberation.voteRounds : [];
  const previousVotes = visibleRound.roundIndex > 0
    ? getJuryVotesForRound(meeting, voteRounds[visibleRound.roundIndex - 1])
    : {};

  return Object.fromEntries(
    Object.entries(currentVotes).map(([speakerId, side]) => [
      speakerId,
      Boolean(
        side &&
        (
          (visibleRound.roundIndex > 0 && previousVotes[speakerId] !== side) ||
          (visibleRound.roundIndex === 0 && side !== 'z')
        )
      )
    ])
  );
}

function getJuryVoteAnimationMap(meeting, currentIndex, includeCurrent = false) {
  return getJuryVoteAnimationMapForRound(meeting, getVisibleVoteRound(meeting, currentIndex, includeCurrent));
}

function getAmbientState(roleMeta, roleId) {
  return String(roleMeta?.[roleId]?.ambientState || '').trim().toLowerCase();
}

function getJuryVoteCounts(votes) {
  return Object.values(votes || {}).reduce(
    (counts, side) => {
      if (side === 'a') {
        counts.a += 1;
      }
      if (side === 'b') {
        counts.b += 1;
      }
      if (side === 'z') {
        counts.z += 1;
      }
      return counts;
    },
    { a: 0, b: 0, z: 0 }
  );
}

function getAmbientIndicatorText(roleMeta, roleId) {
  const state = getAmbientState(roleMeta, roleId);
  if (state === 'zzz') {
    return 'zzz';
  }
  if (state === 'thinking') {
    return '...';
  }
  return '';
}

function isAmbientDebugSlot(slotId) {
  return AMBIENT_DEBUG_SLOT_IDS.includes(slotId);
}

function parseAmbientDecorTarget(selectedTarget) {
  const match = String(selectedTarget || '').match(/^ambient-(phone|zzz|bubble):(.+)$/);
  if (!match) {
    return null;
  }

  return {
    decorType: match[1],
    roleId: match[2]
  };
}

function isTransientFallbackMeeting(item) {
  return item?.topic === DEFAULT_MEETING_TOPIC && !item.summary && !item.generator && !item.loadedAt;
}

function normalizeMeetingHistory(items) {
  const seen = new Set();

  return (Array.isArray(items) ? items : [])
    .filter((item) => item?.id && item?.startedAt && item?.topic)
    .filter((item) => !isTransientFallbackMeeting(item))
    .map((item) => {
      const turns = Array.isArray(item.turns) && item.turns.length > 0 ? item.turns : DEFAULT_MEETING_SCRIPT;

      return {
        ...item,
        mode: item.mode || 'jury_deliberation',
        deliberation: normalizeDeliberationConfig(item.deliberation),
        topic: item.topic || DEFAULT_MEETING_TOPIC,
        turns,
        roleMeta: item.roleMeta && typeof item.roleMeta === 'object' && !Array.isArray(item.roleMeta) ? item.roleMeta : DEFAULT_ROLE_META,
        participants: Array.isArray(item.participants) ? item.participants : turns.map((turn) => turn.speakerId),
        loadedAt: item.loadedAt || item.startedAt
      };
    })
    .filter((item) => {
      if (seen.has(item.id)) {
        return false;
      }

      seen.add(item.id);
      return true;
    })
    .sort((left, right) => new Date(getMeetingHistoryTime(right)).getTime() - new Date(getMeetingHistoryTime(left)).getTime())
    .slice(0, MEETING_HISTORY_LIMIT);
}

function getUniqueSpeakerIds(turns) {
  const speakerIds = [];
  const seen = new Set();

  (Array.isArray(turns) ? turns : []).forEach((turn) => {
    if (!turn?.speakerId || seen.has(turn.speakerId)) {
      return;
    }

    seen.add(turn.speakerId);
    speakerIds.push(turn.speakerId);
  });

  return speakerIds;
}

function createMeetingHistoryEntry() {
  const now = new Date();
  const turns = DEFAULT_MEETING_SCRIPT.map((turn) => ({ ...turn }));

  return {
    id: `meeting-${now.getTime()}-${Math.random().toString(36).slice(2, 8)}`,
    startedAt: now.toISOString(),
    topic: DEFAULT_MEETING_TOPIC,
    mode: 'discussion',
    transient: true,
    status: 'running',
    turns,
    roleMeta: DEFAULT_ROLE_META,
    participants: getUniqueSpeakerIds(turns)
  };
}

function normalizeTurnFromTimeline(event, index) {
  const speakerId = event.speakerId || event.speaker || 'host';
  const phase = event.phase || event.stance || event.type || '发言';

  return {
    id: event.id || `turn-${index + 1}`,
    speakerId,
    phase,
    type: event.type || 'speak',
    targetId: event.targetId || event.target,
    screenTitle: event.screenTitle || event.stance || phase,
    screenStatus: event.screenStatus || String(event.progress ?? '').slice(0, 10) || 'MEETING',
    text: event.text || ''
  };
}

function normalizeExternalRoleMeta(session) {
  if (session?.roleMeta && typeof session.roleMeta === 'object' && !Array.isArray(session.roleMeta)) {
    return { ...DEFAULT_ROLE_META, ...session.roleMeta };
  }

  const host = session?.participants?.host || {};
  const experts = Array.isArray(session?.participants?.experts) ? session.participants.experts : [];
  const roleMeta = {
    host: {
      name: host.displayName || host.name || '主持人',
      title: host.roleName || host.title || '会议主持',
      lane: 'center'
    }
  };

  experts.forEach((expert, index) => {
    const id = expert.id || expert.slug;
    if (!id) {
      return;
    }

    roleMeta[id] = {
      name: expert.displayName || expert.name || id,
      title: expert.roleName || expert.title || expert.name || '专家',
      lane: expert.side || (index % 2 === 0 ? 'left' : 'right')
    };
  });

  return { ...DEFAULT_ROLE_META, ...roleMeta };
}

function createMeetingHistoryEntryFromSession(session) {
  if (!session || typeof session !== 'object') {
    return null;
  }

  const turnsSource = Array.isArray(session.turns) && session.turns.length > 0
    ? session.turns
    : Array.isArray(session.timeline)
      ? session.timeline.map(normalizeTurnFromTimeline)
      : [];
  const turns = turnsSource
    .map((turn, index) => normalizeTurnFromTimeline(turn, index))
    .filter((turn) => turn.speakerId && turn.text);

  const roleMeta = normalizeExternalRoleMeta(session);
  const participants = Array.isArray(session.participants)
    ? session.participants
    : getUniqueSpeakerIds(turns);
  const loadedAt = new Date().toISOString();

  return {
    id: session.id || `meeting-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    startedAt: session.startedAt || new Date().toISOString(),
    loadedAt: session.loadedAt || loadedAt,
    endedAt: session.endedAt,
    topic: session.topic || session.title || DEFAULT_MEETING_TOPIC,
    generator: session.generator,
    mode: session.mode || 'discussion',
    deliberation: normalizeDeliberationConfig(session.deliberation),
    status: session.status || session.runtime?.status || 'running',
    turns,
    roleMeta,
    participants,
    runtime: session.runtime,
    summary: session.summary
  };
}

function getRequestedSessionUrl(searchParams) {
  const requested = searchParams.get('session');

  if (requested === 'none') {
    return '';
  }

  return requested || DEFAULT_SESSION_URL;
}

function getNoStoreSessionUrl(sessionUrl) {
  const separator = sessionUrl.includes('?') ? '&' : '?';
  return `${sessionUrl}${separator}_=${Date.now()}`;
}

function getMeetingTurns(meeting) {
  return Array.isArray(meeting?.turns) ? meeting.turns : DEFAULT_MEETING_SCRIPT;
}

function getMeetingRoleMeta(meeting) {
  return meeting?.roleMeta && typeof meeting.roleMeta === 'object' && !Array.isArray(meeting.roleMeta)
    ? { ...DEFAULT_ROLE_META, ...meeting.roleMeta }
    : DEFAULT_ROLE_META;
}

function getMeetingParticipants(meeting) {
  const turns = getMeetingTurns(meeting);
  const participants = Array.isArray(meeting?.participants) && meeting.participants.length > 0
    ? meeting.participants
    : getUniqueSpeakerIds(turns);

  return getUniqueSpeakerIds(participants.map((speakerId) => ({ speakerId })));
}

function getMeetingThinkingRoleIds(meeting) {
  if (!meeting?.runtime?.thinking || !Array.isArray(meeting.runtime.thinking)) {
    return [];
  }

  return meeting.runtime.thinking
    .map((item) => item?.roleId)
    .filter(Boolean);
}

function getMeetingPendingTurn(meeting) {
  const pending = meeting?.runtime?.pendingSpeaker;
  const speakerId = String(pending?.roleId || '').trim();
  if (!speakerId) {
    return null;
  }

  return {
    id: String(pending.turnId || `pending-${speakerId}`),
    speakerId,
    phase: String(pending.phase || '正在思考'),
    type: String(pending.type || 'speak'),
    screenTitle: String(pending.screenTitle || '实时讨论'),
    screenStatus: String(pending.screenStatus || 'THINK'),
    text: '',
    pending: true,
    startedAt: pending.startedAt || ''
  };
}

function getMeetingLiveSignature(meeting) {
  const turns = getMeetingTurns(meeting);
  const runtime = meeting?.runtime || {};
  const summarySize = Array.isArray(meeting?.summary?.consensus) ? meeting.summary.consensus.length : 0;
  const pending = runtime.pendingSpeaker || {};

  return [
    meeting?.id || '',
    turns.length,
    runtime.status || '',
    runtime.turnCount || '',
    runtime.lastSpeakerId || '',
    pending.roleId || '',
    pending.turnId || '',
    pending.startedAt || '',
    runtime.updatedAt || '',
    summarySize,
    meeting?.endedAt || ''
  ].join('|');
}

function getMeetingSeatsForParticipants(participants, roleMeta) {
  const hostTemplate = meetingSeats.find((seat) => getSeatSlotId(seat) === 'host') || meetingSeats[0];
  const expertTemplates = meetingSeats.filter((seat) => getSeatSlotId(seat) !== 'host');
  const expertIds = participants.filter((speakerId) => speakerId && speakerId !== 'host');
  const hostMeta = roleMeta.host || DEFAULT_ROLE_META.host;
  const seats = [
    {
      ...hostTemplate,
      roleId: 'host',
      empty: false,
      label: hostMeta?.name || '主持人'
    }
  ];

  expertTemplates.forEach((template, index) => {
    const roleId = expertIds[index];
    const meta = roleId ? roleMeta[roleId] : null;

    seats.push({
      ...template,
      roleId,
      empty: !roleId,
      label: roleId ? meta?.name || getRoleLabel(roleId) : ''
    });
  });

  return seats;
}

function getAllCalibrationSeatTargets(seatPlan) {
  const bySlot = new Map((seatPlan || []).map((seat) => [getSeatSlotId(seat), seat]));

  return meetingSeats.map((seat) => {
    const liveSeat = bySlot.get(getSeatSlotId(seat));
    if (liveSeat && !liveSeat.empty) {
      return liveSeat;
    }

    return {
      ...seat,
      roleId: seat.roleId || getSeatSlotId(seat),
      label: seat.label || getRoleLabel(getSeatSlotId(seat)),
      empty: false
    };
  });
}

function getMergedFaceAnchor(seat, overrides) {
  const base = getDefaultFaceAnchor(seat.body, seat.direction);
  const override = overrides?.[seat.body]?.[seat.direction] || {};

  return {
    eyes: { ...base.eyes, ...override.eyes },
    mouth: { ...base.mouth, ...override.mouth }
  };
}

function getRoleLabel(roleId) {
  const seat = meetingSeats.find((item) => getSeatSlotId(item) === roleId);
  return seat?.label || roleId;
}

function getRoleExpressionProfile(roleId) {
  const normalizedRoleId = String(roleId || '');
  const exactProfile = roleExpressionProfiles[normalizedRoleId];

  if (exactProfile) {
    return exactProfile;
  }

  return roleExpressionPatternProfiles.find((item) => item.pattern.test(normalizedRoleId))?.profile || defaultExpressionProfile;
}

function getSeatMotionVars(slotId) {
  const profile = seatMotionProfiles[slotId] || seatMotionProfiles.host;
  const voteDuration = Math.round(profile.voteDuration * 1.68 * 100) / 100;
  const voteDelay = Math.round(profile.voteDelay * 1.18 * 100) / 100;
  const markerDelay = Math.round((voteDelay + voteDuration * 0.46) * 100) / 100;

  return {
    '--blink-duration': `${profile.blinkDuration}s`,
    '--blink-delay': `${profile.blinkDelay}s`,
    '--vote-hand-duration': `${voteDuration}s`,
    '--vote-hand-delay': `${voteDelay}s`,
    '--vote-marker-duration': `${Math.max(0.96, voteDuration * 0.8).toFixed(2)}s`,
    '--vote-marker-delay': `${markerDelay}s`
  };
}

function mergeNameplatePlacement(roleId, overrides) {
  return {
    ...(nameplatePlacements[roleId] || nameplatePlacements.host),
    ...(overrides?.[roleId] || {})
  };
}

function getMergedNameplatePlacements(overrides) {
  return Object.fromEntries(
    Object.keys(nameplatePlacements).map((roleId) => [roleId, mergeNameplatePlacement(roleId, overrides)])
  );
}

function mergeVoteButtonPlacement(roleId, overrides) {
  return {
    ...(voteButtonPlacements[roleId] || voteButtonPlacements.host),
    ...(overrides?.[roleId] || {})
  };
}

function getMergedVoteButtonPlacements(overrides) {
  return Object.fromEntries(
    Object.keys(voteButtonPlacements).map((roleId) => [roleId, mergeVoteButtonPlacement(roleId, overrides)])
  );
}

function getDistanceBetweenPoints(from, to) {
  return Math.hypot(to.x - from.x, to.y - from.y);
}

function getAngleBetweenPoints(from, to) {
  return Math.round((Math.atan2(to.y - from.y, to.x - from.x) * 180 / Math.PI) * 10) / 10;
}

function getPointFromAngle(origin, angle, length) {
  const radians = (angle * Math.PI) / 180;

  return {
    x: clampStageValue(origin.x + Math.cos(radians) * length, 0, stageMetrics.width),
    y: clampStageValue(origin.y + Math.sin(radians) * length, 0, stageMetrics.height)
  };
}

function mergeSeatPlacement(seat, overrides) {
  const slotId = getSeatSlotId(seat);
  const base = {
    ...getSeatPlacement(seat),
    ...(seatPlacements[slotId] || {})
  };

  return {
    ...base,
    ...(overrides?.[slotId] || {}),
    y: base.y
  };
}

function getMergedSeatPlacements(seatPlan, overrides) {
  return Object.fromEntries(
    (seatPlan || meetingSeats).map((seat) => [getSeatSlotId(seat), mergeSeatPlacement(seat, overrides)])
  );
}

function getDefaultVoteArmOffset(seat) {
  const slotId = getSeatSlotId(seat);
  const calibratedArm = voteArmPlacements[slotId] || {};
  const directionSign = seat.role === 'left' ? 1 : -1;

  return {
    shoulderOffsetX: calibratedArm.shoulderOffsetX ?? directionSign * 14,
    shoulderOffsetY: calibratedArm.shoulderOffsetY ?? 4,
    restOffsetX: calibratedArm.restOffsetX,
    restOffsetY: calibratedArm.restOffsetY,
    targetX: calibratedArm.targetX,
    targetY: calibratedArm.targetY
  };
}

function getDefaultVoteArmPlacement(seat, seatPlacement, voteButtonPlacement, override = {}) {
  const defaultOffset = getDefaultVoteArmOffset(seat);
  const shoulder = {
    x: clampStageValue(seatPlacement.x + (override.shoulderOffsetX ?? defaultOffset.shoulderOffsetX), 0, stageMetrics.width),
    y: clampStageValue(seatPlacement.y + (override.shoulderOffsetY ?? defaultOffset.shoulderOffsetY), 0, stageMetrics.height)
  };
  const targetBaseY = override.targetY ?? defaultOffset.targetY ?? voteButtonPlacement.y;
  const target = {
    x: override.targetX ?? defaultOffset.targetX ?? voteButtonPlacement.x,
    y: clampStageValue(targetBaseY - VOTE_ARM_TARGET_LIFT_Y, 0, stageMetrics.height)
  };
  const defaultLength = clampStageValue(getDistanceBetweenPoints(shoulder, target), 24, 360);
  const length = clampStageValue(override.length ?? defaultLength, 24, 360);
  const directionSign = seat.role === 'left' ? 1 : -1;
  const restOffsetX = override.restOffsetX ?? defaultOffset.restOffsetX;
  const restOffsetY = override.restOffsetY ?? defaultOffset.restOffsetY;
  const restPoint = {
    x: restOffsetX !== undefined
      ? clampStageValue(shoulder.x + restOffsetX, 0, stageMetrics.width)
      : clampStageValue(shoulder.x + directionSign * Math.min(18, length * 0.22), 0, stageMetrics.width),
    y: restOffsetY !== undefined
      ? clampStageValue(shoulder.y + restOffsetY, 0, stageMetrics.height)
      : clampStageValue(shoulder.y + Math.min(78, length * 0.92), 0, stageMetrics.height)
  };

  return {
    shoulderX: shoulder.x,
    shoulderY: shoulder.y,
    shoulderOffsetX: shoulder.x - seatPlacement.x,
    shoulderOffsetY: shoulder.y - seatPlacement.y,
    restX: restPoint.x,
    restY: restPoint.y,
    restOffsetX: restPoint.x - shoulder.x,
    restOffsetY: restPoint.y - shoulder.y,
    targetX: target.x,
    targetY: target.y,
    length
  };
}

function mergeVoteArmPlacement(seat, seatPlacement, voteButtonPlacement, overrides) {
  const slotId = getSeatSlotId(seat);

  return getDefaultVoteArmPlacement(seat, seatPlacement, voteButtonPlacement, overrides?.[slotId] || {});
}

function getMergedVoteArmPlacements(seatPlan, seatPlacements, voteButtons, overrides) {
  return Object.fromEntries(
    (seatPlan || meetingSeats)
      .filter((seat) => getSeatRoleId(seat) !== 'host')
      .map((seat) => {
        const slotId = getSeatSlotId(seat);
        const seatPlacement = seatPlacements?.[slotId] || getSeatPlacement(seat);
        const voteButtonPlacement = voteButtons?.[slotId] || voteButtonPlacements[slotId] || voteButtonPlacements.host;

        return [slotId, mergeVoteArmPlacement(seat, seatPlacement, voteButtonPlacement, overrides)];
      })
  );
}

function mergeScreenPlacement(overrides) {
  return {
    ...screenPlacement,
    ...(overrides || {}),
    width: screenPlacement.width,
    height: screenPlacement.height
  };
}

function getStagePointFromPointer(event, element) {
  const canvas = element?.closest('.stage-canvas');
  const rect = canvas?.getBoundingClientRect();

  if (!rect || rect.width === 0 || rect.height === 0) {
    return null;
  }

  return {
    x: clampStageValue(((event.clientX - rect.left) / rect.width) * stageMetrics.width, 0, stageMetrics.width),
    y: clampStageValue(((event.clientY - rect.top) / rect.height) * stageMetrics.height, 0, stageMetrics.height)
  };
}

function useLayoutDrag({ enabled, targetId, placement, onSelect, onMove }) {
  const targetRef = useRef(null);
  const offsetRef = useRef({ x: 0, y: 0 });
  const [dragging, setDragging] = useState(false);

  const moveToPoint = (point) => {
    onMove({
      x: clampStageValue(point.x - offsetRef.current.x, 0, stageMetrics.width),
      y: clampStageValue(point.y - offsetRef.current.y, 0, stageMetrics.height)
    });
  };

  useEffect(() => {
    if (!dragging) {
      return undefined;
    }

    const handlePointerMove = (event) => {
      const point = getStagePointFromPointer(event, targetRef.current);
      if (point) {
        moveToPoint(point);
      }
    };
    const handlePointerUp = () => setDragging(false);

    window.addEventListener('pointermove', handlePointerMove);
    window.addEventListener('pointerup', handlePointerUp, { once: true });

    return () => {
      window.removeEventListener('pointermove', handlePointerMove);
      window.removeEventListener('pointerup', handlePointerUp);
    };
  }, [dragging, onMove]);

  const startDrag = (event) => {
    if (!enabled) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.focus();
    onSelect(targetId);

    const point = getStagePointFromPointer(event, event.currentTarget);
    if (!point) {
      return;
    }

    offsetRef.current = {
      x: point.x - placement.x,
      y: point.y - placement.y
    };
    setDragging(true);
  };

  const handleKeyDown = (event) => {
    const deltas = {
      ArrowLeft: [-1, 0],
      ArrowRight: [1, 0],
      ArrowUp: [0, -1],
      ArrowDown: [0, 1]
    };
    const delta = deltas[event.key];

    if (!enabled || !delta) {
      return;
    }

    event.preventDefault();
    onSelect(targetId);

    const step = event.shiftKey ? 10 : event.altKey ? 0.5 : 1;
    onMove({
      x: clampStageValue(placement.x + delta[0] * step, 0, stageMetrics.width),
      y: clampStageValue(placement.y + delta[1] * step, 0, stageMetrics.height)
    });
  };

  return {
    ref: targetRef,
    role: enabled ? 'button' : undefined,
    tabIndex: enabled ? 0 : undefined,
    dragging,
    onPointerDown: enabled ? startDrag : undefined,
    onKeyDown: enabled ? handleKeyDown : undefined
  };
}

function useStageScale(stageRef) {
  useEffect(() => {
    const stage = stageRef.current;
    if (!stage) {
      return undefined;
    }

    const updateStageScale = () => {
      const rect = stage.getBoundingClientRect();
      const scale = Math.min(rect.width / stageMetrics.width, rect.height / stageMetrics.height);
      stage.style.setProperty('--stage-scale', String(scale || 1));
    };

    updateStageScale();

    if ('ResizeObserver' in window) {
      const resizeObserver = new ResizeObserver(updateStageScale);
      resizeObserver.observe(stage);
      return () => resizeObserver.disconnect();
    }

    window.addEventListener('resize', updateStageScale);
    return () => window.removeEventListener('resize', updateStageScale);
  }, [stageRef]);
}

function StageImage({ className, src, alt, role, state, active, style }) {
  return (
    <img
      className={className}
      src={src}
      alt={alt}
      data-role={role}
      data-state={state}
      data-active={active ? 'true' : 'false'}
      loading="eager"
      style={style}
    />
  );
}

function getSeatSlotId(seat) {
  return seat.slotId || getSeatRoleId(seat);
}

function getSeatRoleId(seat) {
  return seat.roleId || roleBySeatLabel[seat.label] || seat.role;
}

function getTurnTextCompleteMs(turn) {
  return TYPE_INITIAL_DELAY_MS + turn.text.length * TYPE_MS_PER_CHARACTER;
}

function getTurnDuration(turn, hasVoteMoment = false) {
  return getTurnTextCompleteMs(turn) + TURN_HOLD_MS + (hasVoteMoment ? VOTE_TURN_EXTRA_HOLD_MS : 0);
}

function getVisibleTurnText(turn, elapsedMs) {
  const typedMs = Math.max(0, elapsedMs - TYPE_INITIAL_DELAY_MS);
  const visibleCharacters = Math.min(turn.text.length, Math.floor(typedMs / TYPE_MS_PER_CHARACTER));

  return turn.text.slice(0, visibleCharacters);
}

function getSeatState(roleId, turn, isSpeaking) {
  if (roleId === turn.speakerId) {
    return isSpeaking ? 'talk' : 'listening';
  }

  return 'listening';
}

function FaceOverlay({ seat, roleId, state, anchor, layoutPlacements, expressionProfile, calibration = { enabled: false } }) {
  const overlayRef = useRef(null);
  const [draggingPart, setDraggingPart] = useState(null);
  const placement = getSeatLayoutPlacement(seat, layoutPlacements);
  const canCalibrate = calibration.enabled && calibration.selectedBody === seat.body;
  const motionVars = getSeatMotionVars(getSeatSlotId(seat));
  const faceExpression = expressionProfile || getRoleExpressionProfile(roleId || getSeatRoleId(seat));

  const updateAnchorFromPointer = (event, part) => {
    const rect = overlayRef.current?.getBoundingClientRect();
    if (!rect) {
      return;
    }

    calibration.onAnchorChange(seat.body, seat.direction, part, {
      x: clampPercent(((event.clientX - rect.left) / rect.width) * 100),
      y: clampPercent(((event.clientY - rect.top) / rect.height) * 100)
    });
  };

  const updateAnchorFromKeyboard = (event, part) => {
    const deltas = {
      ArrowLeft: [-1, 0],
      ArrowRight: [1, 0],
      ArrowUp: [0, -1],
      ArrowDown: [0, 1]
    };
    const delta = deltas[event.key];

    if (!delta) {
      return;
    }

    event.preventDefault();

    const step = event.shiftKey ? 5 : event.altKey ? 0.2 : 1;
    const current = anchor[part];

    calibration.onAnchorChange(seat.body, seat.direction, part, {
      x: clampPercent(current.x + delta[0] * step),
      y: clampPercent(current.y + delta[1] * step)
    });
  };

  useEffect(() => {
    if (!draggingPart) {
      return undefined;
    }

    const handlePointerMove = (event) => updateAnchorFromPointer(event, draggingPart);
    const handlePointerUp = () => setDraggingPart(null);

    window.addEventListener('pointermove', handlePointerMove);
    window.addEventListener('pointerup', handlePointerUp, { once: true });
    return () => {
      window.removeEventListener('pointermove', handlePointerMove);
      window.removeEventListener('pointerup', handlePointerUp);
    };
  }, [draggingPart, calibration, seat.body, seat.direction]);

  return (
    <div
      ref={overlayRef}
      className="face-overlay"
      data-state={state}
      data-direction={seat.direction}
      data-role={seat.role}
      data-eye-variant={faceExpression.eyeVariant || defaultExpressionProfile.eyeVariant}
      data-mouth-variant={faceExpression.mouthVariant || defaultExpressionProfile.mouthVariant}
      data-calibrating={canCalibrate ? 'true' : 'false'}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`,
        width: `${seat.role === 'host' ? stageMetrics.hostWidth : stageMetrics.seatWidth}px`,
        '--scale': String(seat.scale),
        '--z': '70',
        '--eye-x': `${anchor.eyes.x}%`,
        '--eye-y': `${anchor.eyes.y}%`,
        '--mouth-x': `${anchor.mouth.x}%`,
        '--mouth-y': `${anchor.mouth.y}%`,
        ...motionVars
      }}
    >
      <span
        className="face-eyes"
        role={canCalibrate ? 'button' : undefined}
        tabIndex={canCalibrate ? 0 : undefined}
        aria-label={canCalibrate ? `${seat.body} ${seat.direction} 眼睛` : undefined}
        onPointerDown={
          canCalibrate
            ? (event) => {
                event.preventDefault();
                event.currentTarget.focus();
                setDraggingPart('eyes');
                updateAnchorFromPointer(event, 'eyes');
              }
            : undefined
        }
        onKeyDown={canCalibrate ? (event) => updateAnchorFromKeyboard(event, 'eyes') : undefined}
      >
        <i />
        <i />
      </span>
      <span
        className="face-mouth"
        role={canCalibrate ? 'button' : undefined}
        tabIndex={canCalibrate ? 0 : undefined}
        aria-label={canCalibrate ? `${seat.body} ${seat.direction} 嘴巴` : undefined}
        onPointerDown={
          canCalibrate
            ? (event) => {
                event.preventDefault();
                event.currentTarget.focus();
                setDraggingPart('mouth');
                updateAnchorFromPointer(event, 'mouth');
              }
            : undefined
        }
        onKeyDown={canCalibrate ? (event) => updateAnchorFromKeyboard(event, 'mouth') : undefined}
      />
    </div>
  );
}

function MeetingSeat({
  seat,
  turn,
  isSpeaking,
  isThinking = false,
  meetingRoleMeta,
  faceOverrides,
  layoutPlacements,
  layoutCalibration,
  voteSide,
  ambientDebugEnabled = false
}) {
  const placement = getSeatLayoutPlacement(seat, layoutPlacements);
  const seatWidth = seat.role === 'host' ? stageMetrics.hostWidth : stageMetrics.seatWidth;
  const roleId = getSeatRoleId(seat);
  const slotId = getSeatSlotId(seat);
  const state = getSeatState(roleId, turn, isSpeaking && roleId === turn.speakerId);
  const active = roleId === turn.speakerId;
  const faceAnchor = getMergedFaceAnchor(seat, faceOverrides);
  const ambientState = getAmbientState(meetingRoleMeta, roleId);
  const expressionProfile = ambientState === 'zzz'
    ? roleExpressionProfiles['ambient-sleeper'] || getRoleExpressionProfile(roleId)
    : ambientState === 'thinking'
      ? roleExpressionProfiles['ambient-thinking'] || getRoleExpressionProfile(roleId)
      : ambientState === 'nod'
        ? roleExpressionProfiles['ambient-nodder'] || getRoleExpressionProfile(roleId)
        : ambientState === 'reserve'
          ? roleExpressionProfiles['ambient-reserved'] || getRoleExpressionProfile(roleId)
          : ambientState === 'phone'
            ? roleExpressionProfiles['ambient-phone'] || getRoleExpressionProfile(roleId)
            : getRoleExpressionProfile(roleId);
  const slotIsAmbientDebug = isAmbientDebugSlot(slotId);
  const shouldShowDebugDecor = ambientDebugEnabled && slotIsAmbientDebug;
  const shouldShowPhone = ambientState === 'phone' || shouldShowDebugDecor;
  const shouldShowZzz = ambientState === 'zzz' || shouldShowDebugDecor;
  const shouldShowSleepBubble = ambientState === 'zzz' || shouldShowDebugDecor;
  const ambientIndicatorText = getAmbientIndicatorText(meetingRoleMeta, roleId);
  const sharedStyle = {
    left: `${placement.x}px`,
    top: `${placement.y}px`,
    width: `${seatWidth}px`,
    '--scale': String(seat.scale)
  };
  const zzzPlacement = layoutPlacements?.ambientDecor?.[slotId]?.zzz || getMergedAmbientDecorPlacement(seat, layoutPlacements, {}, 'zzz');
  const zzzStyle = {
    left: `${zzzPlacement.x}px`,
    top: `${zzzPlacement.y}px`,
    '--z': '58',
    '--thinking-rotate': `${zzzPlacement.rotate || 0}deg`
  };
  const upperLayerSrc = getSeatHeadAsset(seat.body, seat.direction);
  const upperLayerClass = 'stage-seat stage-seat-head';
  const nameplate = getNameplatePlacement(seat, layoutPlacements);
  const nameplateDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId: slotId,
    placement: nameplate,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveNameplate(slotId, point)
  });
  const zzzTargetId = `ambient-zzz:${slotId}`;
  const zzzDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId: zzzTargetId,
    placement: zzzPlacement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveAmbientDecor?.(slotId, 'zzz', point)
  });

  return (
    <>
      <StageImage
        className="stage-seat stage-seat-body"
        src={occupiedSeats[seat.body][seat.direction]}
        alt={`${seat.label} 有人座位`}
        role={seat.role}
        state={state}
        active={active}
        style={{ ...sharedStyle, '--z': String(seat.z) }}
      />
      <StageImage
        className={upperLayerClass}
        src={upperLayerSrc}
        alt={`${seat.label} 牛头遮挡层`}
        role={seat.role}
        state={state}
        active={active}
        style={{ ...sharedStyle, '--z': '52' }}
      />
      {shouldShowPhone && roleId !== 'host' && (
        <AmbientPhoneGesture seat={seat} layoutPlacements={layoutPlacements} layoutCalibration={layoutCalibration} />
      )}
      {shouldShowSleepBubble && roleId !== 'host' && (
        <AmbientSleepBubble seat={seat} layoutPlacements={layoutPlacements} layoutCalibration={layoutCalibration} />
      )}
      {(isThinking || ambientIndicatorText || shouldShowZzz) && roleId !== 'host' && (
        <span
          ref={shouldShowZzz ? zzzDrag.ref : undefined}
          className="stage-seat-thinking"
          data-calibrating={shouldShowZzz && layoutCalibration.enabled ? 'true' : 'false'}
          data-selected={shouldShowZzz && layoutCalibration.selectedTarget === zzzTargetId ? 'true' : 'false'}
          data-dragging={shouldShowZzz && zzzDrag.dragging ? 'true' : 'false'}
          role={shouldShowZzz ? zzzDrag.role : undefined}
          tabIndex={shouldShowZzz ? zzzDrag.tabIndex : undefined}
          onPointerDown={shouldShowZzz ? zzzDrag.onPointerDown : undefined}
          onKeyDown={shouldShowZzz ? zzzDrag.onKeyDown : undefined}
          aria-label={shouldShowZzz && layoutCalibration.enabled ? `${seat.label} zzz` : undefined}
          aria-hidden="true"
          style={shouldShowZzz ? zzzStyle : {
            left: `${placement.x}px`,
            top: `${Math.round(placement.y - seatWidth * 0.6)}px`,
            '--z': '58',
            '--thinking-rotate': '0deg'
          }}
        >
          {Array.from((shouldShowZzz ? 'zzz' : '') || ambientIndicatorText || '...').map((char, index) => (
            <i key={`${roleId}-thinking-${index}`}>{char}</i>
          ))}
        </span>
      )}
      <span
        ref={nameplateDrag.ref}
        className="seat-nameplate"
        data-role={seat.role}
        data-seat-side={seat.role}
        data-vote-side={voteSide || ''}
        data-active={roleId === turn.speakerId ? 'true' : 'false'}
        data-calibrating={layoutCalibration.enabled ? 'true' : 'false'}
        data-selected={layoutCalibration.selectedTarget === slotId ? 'true' : 'false'}
        data-dragging={nameplateDrag.dragging ? 'true' : 'false'}
        role={nameplateDrag.role}
        tabIndex={nameplateDrag.tabIndex}
        aria-label={layoutCalibration.enabled ? `${seat.label} 铭牌` : undefined}
        onPointerDown={nameplateDrag.onPointerDown}
        onKeyDown={nameplateDrag.onKeyDown}
        style={{
          '--plate-x': `${nameplate.x}px`,
          '--plate-y': `${nameplate.y}px`,
          '--plate-rotate': `${nameplate.rotate}deg`,
          '--plate-tilt': `${nameplate.tilt}deg`,
          '--plate-width': `${Math.round(nameplate.width * NAMEPLATE_VISUAL_SCALE)}px`,
          '--label-chars': String(Math.max(4, Array.from(seat.label).length)),
          '--z': String(66)
        }}
      >
        <strong>{seat.label}</strong>
      </span>
      <FaceOverlay
        seat={seat}
        roleId={roleId}
        state={state}
        anchor={faceAnchor}
        layoutPlacements={layoutPlacements}
        expressionProfile={expressionProfile}
      />
    </>
  );
}

function getNameplatePlacement(seat, layoutPlacements) {
  const slotId = getSeatSlotId(seat);
  return layoutPlacements?.nameplates?.[slotId] || nameplatePlacements[slotId] || nameplatePlacements.host;
}

function getVoteButtonPlacement(seat, layoutPlacements) {
  const slotId = getSeatSlotId(seat);
  return layoutPlacements?.voteButtons?.[slotId] || voteButtonPlacements[slotId] || voteButtonPlacements.host;
}

function getSeatLayoutPlacement(seat, layoutPlacements) {
  const slotId = getSeatSlotId(seat);
  return layoutPlacements?.seats?.[slotId] || getSeatPlacement(seat);
}

function getVoteArmPlacement(seat, layoutPlacements) {
  const slotId = getSeatSlotId(seat);
  const seatPlacement = getSeatLayoutPlacement(seat, layoutPlacements);
  const voteButtonPlacement = getVoteButtonPlacement(seat, layoutPlacements);
  return layoutPlacements?.voteArms?.[slotId] || getDefaultVoteArmPlacement(seat, seatPlacement, voteButtonPlacement);
}

function getVoteArmSilhouettePath(length, seatSide) {
  const safeLength = Math.max(26, Math.round(length));
  const height = 24;
  const centerY = height / 2;
  const rootInset = Math.max(5.8, Math.min(8.4, safeLength * 0.1));
  const shoulderHalf = Math.max(9.2, Math.min(11.8, safeLength * 0.15));
  const wristHalf = Math.max(3.4, Math.min(4.7, safeLength * 0.055));
  const palmRadius = Math.max(4.2, Math.min(5.4, safeLength * 0.058));
  const bendDirection = seatSide === 'right' ? -1 : 1;
  const bend = Math.max(1.2, Math.min(2.8, safeLength * 0.025)) * bendDirection;
  const palmX = Math.max(18, safeLength - palmRadius);
  const wristX = Math.max(14, palmX - palmRadius * 0.55);
  const controlA = Math.max(rootInset + 7, safeLength * 0.32);
  const controlB = Math.max(14, safeLength * 0.68);
  const topShoulder = centerY - shoulderHalf;
  const bottomShoulder = centerY + shoulderHalf;
  const topWrist = centerY - wristHalf;
  const bottomWrist = centerY + wristHalf;

  return {
    width: safeLength,
    height,
    centerY,
    viewBox: `0 0 ${safeLength} ${height}`,
    d: [
      `M ${rootInset} ${topShoulder}`,
      `C ${controlA} ${topShoulder + bend * 0.18}, ${controlB} ${topWrist + bend}, ${wristX} ${topWrist}`,
      `C ${palmX - palmRadius * 0.35} ${centerY - palmRadius}, ${safeLength} ${centerY - palmRadius}, ${safeLength} ${centerY}`,
      `C ${safeLength} ${centerY + palmRadius}, ${palmX - palmRadius * 0.35} ${centerY + palmRadius}, ${wristX} ${bottomWrist}`,
      `C ${controlB} ${bottomWrist + bend}, ${controlA} ${bottomShoulder + bend * 0.18}, ${rootInset} ${bottomShoulder}`,
      `Q ${rootInset - 1.6} ${centerY} ${rootInset} ${topShoulder}`,
      'Z'
    ].join(' ')
  };
}

function AmbientSleepBubble({ seat, layoutPlacements, layoutCalibration }) {
  const slotId = getSeatSlotId(seat);
  const placement = layoutPlacements?.ambientDecor?.[slotId]?.bubble || getMergedAmbientDecorPlacement(seat, layoutPlacements, {}, 'bubble');
  const targetId = `ambient-bubble:${slotId}`;
  const decorDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId,
    placement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveAmbientDecor?.(slotId, 'bubble', point)
  });

  return (
    <span
      ref={decorDrag.ref}
      className="stage-sleep-bubble"
      data-calibrating={layoutCalibration.enabled ? 'true' : 'false'}
      data-selected={layoutCalibration.selectedTarget === targetId ? 'true' : 'false'}
      data-dragging={decorDrag.dragging ? 'true' : 'false'}
      role={decorDrag.role}
      tabIndex={decorDrag.tabIndex}
      onPointerDown={decorDrag.onPointerDown}
      onKeyDown={decorDrag.onKeyDown}
      aria-label={layoutCalibration.enabled ? `${seat.label} 睡觉鼻涕泡` : undefined}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`,
        '--sleep-bubble-scale': String(placement.scale || 1),
        '--sleep-bubble-rotate': `${placement.rotate || 0}deg`,
        '--sleep-bubble-flip': placement.mirrorX ? '-1' : '1'
      }}
    >
      <img className="stage-sleep-bubble-img" src={sleepBubbleAsset} alt="" />
    </span>
  );
}

function AmbientPhoneGesture({ seat, layoutPlacements, layoutCalibration }) {
  const placement = getVoteArmPlacement(seat, layoutPlacements);
  const silhouette = getVoteArmSilhouettePath(placement.length, seat.role);
  const shoulder = { x: placement.shoulderX, y: placement.shoulderY };
  const target = { x: placement.targetX, y: placement.targetY };
  const targetAngle = getAngleBetweenPoints(shoulder, target);
  const slotId = getSeatSlotId(seat);
  const devicePlacement = layoutPlacements?.ambientDecor?.[slotId]?.phone || getMergedAmbientDecorPlacement(seat, layoutPlacements, {}, 'phone');
  const deviceTilt = seat.role === 'right' ? 26 : -26;
  const phoneMode = getAmbientPhoneScreenMode(slotId);
  const phoneFrames = PHONE_FRAME_ASSETS[phoneMode] || PHONE_FRAME_ASSETS.chat;
  const phoneTiming = getAmbientPhoneTiming(slotId, phoneMode);
  const targetId = `ambient-phone:${slotId}`;
  const decorDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId,
    placement: devicePlacement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveAmbientDecor?.(slotId, 'phone', point)
  });

  return (
    <>
      <span
        className="stage-phone-gesture"
        data-seat-side={seat.role}
        aria-hidden="true"
        style={{
          left: `${placement.shoulderX}px`,
          top: `${placement.shoulderY}px`,
          '--phone-arm-length': `${placement.length}px`,
          '--phone-arm-visual-width': `${silhouette.width}px`,
          '--phone-arm-visual-height': `${silhouette.height}px`,
          '--phone-arm-angle': `${targetAngle}deg`
        }}
      >
        <svg className="stage-phone-arm-svg" viewBox={silhouette.viewBox} preserveAspectRatio="none" focusable="false">
          <path className="stage-phone-arm-silhouette" d={silhouette.d} />
        </svg>
      </span>
      <span
        ref={decorDrag.ref}
        className="stage-phone-device"
        data-mode={phoneMode}
        data-calibrating={layoutCalibration.enabled ? 'true' : 'false'}
        data-selected={layoutCalibration.selectedTarget === targetId ? 'true' : 'false'}
        data-dragging={decorDrag.dragging ? 'true' : 'false'}
        role={decorDrag.role}
        tabIndex={decorDrag.tabIndex}
        onPointerDown={decorDrag.onPointerDown}
        onKeyDown={decorDrag.onKeyDown}
        aria-label={layoutCalibration.enabled ? `${seat.label} 手机` : undefined}
        style={{
          left: `${devicePlacement.x}px`,
          top: `${devicePlacement.y}px`,
          '--phone-device-rotate': `${deviceTilt + (devicePlacement.rotate || 0)}deg`,
          '--phone-screen-delay': phoneTiming.delay,
          '--phone-screen-duration': phoneTiming.duration
        }}
        >
          <span className="stage-phone-screen">
          {phoneMode === 'chat' ? (
            <span className="stage-phone-chat-marquee" aria-hidden="true">
              {Array.from({ length: 2 }).map((_, groupIndex) => (
                <span className="stage-phone-chat-feed" key={`chat-feed-${groupIndex}`}>
                  <i className="stage-phone-chat-row left size-medium">
                    <b className="line long" />
                    <b className="line short" />
                  </i>
                  <i className="stage-phone-chat-row right size-short">
                    <b className="line medium" />
                  </i>
                  <i className="stage-phone-chat-row left size-long">
                    <b className="line medium" />
                    <b className="line long" />
                  </i>
                  <i className="stage-phone-chat-row right size-medium">
                    <b className="line short" />
                    <b className="line medium" />
                  </i>
                  <i className="stage-phone-chat-row left size-short">
                    <b className="line medium" />
                  </i>
                  <i className="stage-phone-chat-row right size-long">
                    <b className="line long" />
                    <b className="line short" />
                  </i>
                </span>
              ))}
            </span>
          ) : phoneMode === 'game' ? (
            <span className="stage-phone-breakout-board" aria-hidden="true">
              <span className="breakout-bricks">
                {Array.from({ length: 12 }).map((_, index) => (
                  <i key={`brick-${index}`} className={`breakout-brick brick-${index + 1}`} />
                ))}
              </span>
              <i className="breakout-ball" />
              <i className="breakout-paddle" />
              <i className="breakout-hit breakout-hit-a" />
              <i className="breakout-hit breakout-hit-b" />
            </span>
          ) : (
            <span className="stage-phone-frame-strip" data-mode={phoneMode} aria-hidden="true">
              {phoneFrames.map((frameSrc, index) => (
                <img key={`${phoneMode}-${index}`} className="stage-phone-frame" src={frameSrc} alt="" />
              ))}
            </span>
          )}
        </span>
        <span className="stage-phone-camera" />
      </span>
    </>
  );
}

function VoteArmGesture({ seat, pendingSide, shouldAnimateVote, layoutPlacements, isCalibrating = false }) {
  const slotId = getSeatSlotId(seat);
  const placement = getVoteArmPlacement(seat, layoutPlacements);
  const motionVars = getSeatMotionVars(slotId);
  const shoulder = { x: placement.shoulderX, y: placement.shoulderY };
  const restAngle = getAngleBetweenPoints(shoulder, { x: placement.restX, y: placement.restY });
  const targetAngle = getAngleBetweenPoints(shoulder, { x: placement.targetX, y: placement.targetY });
  const silhouette = getVoteArmSilhouettePath(placement.length, seat.role);

  return (
    <span
      className="stage-vote-arm"
      data-seat-side={seat.role}
      data-option={pendingSide || ''}
      data-active={shouldAnimateVote && pendingSide ? 'true' : 'false'}
      data-calibrating={isCalibrating ? 'true' : 'false'}
      aria-hidden="true"
      style={{
        left: `${placement.shoulderX}px`,
        top: `${placement.shoulderY}px`,
        '--vote-arm-length': `${placement.length}px`,
        '--vote-arm-visual-width': `${silhouette.width}px`,
        '--vote-arm-visual-height': `${silhouette.height}px`,
        '--vote-arm-rest-angle': `${restAngle}deg`,
        '--vote-arm-target-angle': `${targetAngle}deg`,
        ...motionVars
      }}
    >
      <svg className="stage-vote-arm-svg" viewBox={silhouette.viewBox} preserveAspectRatio="none" focusable="false">
        <path className="stage-vote-arm-silhouette" d={silhouette.d} />
      </svg>
    </span>
  );
}

function VoteArmCalibrationPoint({ seat, pointType, layoutPlacements, layoutCalibration }) {
  const slotId = getSeatSlotId(seat);
  const placement = getVoteArmPlacement(seat, layoutPlacements);
  const pointByType = {
    shoulder: { x: placement.shoulderX, y: placement.shoulderY },
    rest: { x: placement.restX, y: placement.restY },
    target: { x: placement.targetX, y: placement.targetY }
  };
  const point = pointByType[pointType];
  const targetId = `arm-${pointType}:${slotId}`;
  const armPointDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId,
    placement: point,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (nextPoint) => layoutCalibration.onMoveVoteArmPoint(slotId, pointType, nextPoint)
  });

  if (!layoutCalibration.enabled || !point) {
    return null;
  }

  return (
    <span
      ref={armPointDrag.ref}
      className="stage-vote-arm-point"
      data-point={pointType}
      data-seat-side={seat.role}
      data-selected={layoutCalibration.selectedTarget === targetId ? 'true' : 'false'}
      data-dragging={armPointDrag.dragging ? 'true' : 'false'}
      role={armPointDrag.role}
      tabIndex={armPointDrag.tabIndex}
      aria-label={`${seat.label} ${pointType === 'shoulder' ? '肩膀锚点' : pointType === 'rest' ? '初始手位' : '投票手位'}`}
      onPointerDown={armPointDrag.onPointerDown}
      onKeyDown={armPointDrag.onKeyDown}
      style={{
        left: `${point.x}px`,
        top: `${point.y}px`
      }}
    />
  );
}

function SeatVoteButtons({ seat, selectedSide, pendingSide, shouldAnimateVote, layoutPlacements, layoutCalibration }) {
  const slotId = getSeatSlotId(seat);
  const placement = getVoteButtonPlacement(seat, layoutPlacements);
  const pressRadians = ((placement.rotate || 0) * Math.PI) / 180;
  const pressFull = {
    x: Math.round(Math.sin(pressRadians) * 3 * 100) / 100,
    y: Math.round(Math.cos(pressRadians) * 3 * 100) / 100
  };
  const pressRebound = {
    x: Math.round(Math.sin(pressRadians) * 1 * 100) / 100,
    y: Math.round(Math.cos(pressRadians) * 1 * 100) / 100
  };
  const motionVars = getSeatMotionVars(slotId);
  const voteButtonDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId: `vote:${slotId}`,
    placement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveVoteButton(slotId, point)
  });

  return (
    <div
      ref={voteButtonDrag.ref}
      className="seat-vote-buttons"
      data-seat-side={seat.role}
      data-vote-side={selectedSide || ''}
      data-calibrating={layoutCalibration.enabled ? 'true' : 'false'}
      data-selected={layoutCalibration.selectedTarget === `vote:${slotId}` ? 'true' : 'false'}
      data-dragging={voteButtonDrag.dragging ? 'true' : 'false'}
      role={voteButtonDrag.role}
      tabIndex={voteButtonDrag.tabIndex}
      aria-label={layoutCalibration.enabled ? `${seat.label} 投票按钮` : undefined}
      onPointerDown={voteButtonDrag.onPointerDown}
      onKeyDown={voteButtonDrag.onKeyDown}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`,
        '--vote-buttons-rotate': `${placement.rotate || 0}deg`,
        '--vote-buttons-scale': String(placement.scale || 1),
        '--vote-button-upright-rotate': `${-(placement.rotate || 0)}deg`,
        '--vote-press-x': `${pressFull.x}px`,
        '--vote-press-y': `${pressFull.y}px`,
        '--vote-rebound-x': `${pressRebound.x}px`,
        '--vote-rebound-y': `${pressRebound.y}px`,
        ...motionVars
      }}
    >
      {['a', 'b'].map((side) => {
        const isSelected = selectedSide === side;
        const isPending = !isSelected && pendingSide === side;
        const isClearing = shouldAnimateVote && pendingSide === 'z' && (selectedSide === 'a' || selectedSide === 'b');
        const shouldPress = shouldAnimateVote && (isSelected || isPending) && (side === 'a' || side === 'b') && pendingSide !== 'z';

        return (
          <span
            key={side}
            className="seat-vote-button"
            data-option={side}
            data-active={isSelected ? 'true' : 'false'}
            data-pending={isPending ? 'true' : 'false'}
            data-clearing={isClearing ? 'true' : 'false'}
            data-pressed={shouldPress ? 'true' : 'false'}
            aria-label={`${side.toUpperCase()} ${isSelected ? '亮起' : isPending ? '投票中' : '关闭'}`}
          >
            <span className="seat-vote-button-shape" aria-hidden="true" />
          </span>
        );
      })}
    </div>
  );
}

function SeatCalibrationPoint({ seat, layoutPlacements, layoutCalibration }) {
  const slotId = getSeatSlotId(seat);
  const placement = getSeatLayoutPlacement(seat, layoutPlacements);
  const seatDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId: `seat:${slotId}`,
    placement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: (point) => layoutCalibration.onMoveSeat(slotId, point)
  });

  if (!layoutCalibration.enabled || getSeatRoleId(seat) === 'host') {
    return null;
  }

  return (
    <span
      ref={seatDrag.ref}
      className="stage-seat-point"
      data-seat-side={seat.role}
      data-selected={layoutCalibration.selectedTarget === `seat:${slotId}` ? 'true' : 'false'}
      data-dragging={seatDrag.dragging ? 'true' : 'false'}
      role={seatDrag.role}
      tabIndex={seatDrag.tabIndex}
      aria-label={`${seat.label} 座位左右位置`}
      onPointerDown={seatDrag.onPointerDown}
      onKeyDown={seatDrag.onKeyDown}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`
      }}
    />
  );
}

function EmptySeat({ seat, layoutPlacements }) {
  const placement = getSeatLayoutPlacement(seat, layoutPlacements);
  const seatWidth = seat.role === 'host' ? stageMetrics.hostWidth : stageMetrics.seatWidth;
  const emptyWidth = Math.round(seatWidth * 0.92);
  const emptyScale = Math.round(seat.scale * 0.89 * 100) / 100;

  return (
    <StageImage
      className="stage-seat stage-seat-empty"
      src={emptySeats[seat.direction]}
      alt="空椅子"
      role={seat.role}
      state="empty"
      active={false}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`,
        width: `${emptyWidth}px`,
        '--scale': String(emptyScale),
        '--z': String(seat.z)
      }}
    />
  );
}

function MeetingScreen({ topic, placement, layoutCalibration, deliberation, voteRound, voteCounts, motionEnabled }) {
  const screenDrag = useLayoutDrag({
    enabled: layoutCalibration.enabled,
    targetId: 'screen',
    placement,
    onSelect: layoutCalibration.onSelectTarget,
    onMove: layoutCalibration.onMoveScreen
  });
  const compactTopic = getCompactScreenTopic(topic);
  const showJuryVote = Boolean(deliberation?.enabled || voteRound);
  const labelA = deliberation?.labelA || '方案A';
  const labelB = deliberation?.labelB || '方案B';
  const labelZ = deliberation?.labelZ || '弃权';
  const detailA = deliberation?.detailA;
  const detailB = deliberation?.detailB;
  const detailZ = deliberation?.detailZ;

  return (
    <section
      ref={screenDrag.ref}
      className="meeting-screen"
      data-calibrating={layoutCalibration.enabled ? 'true' : 'false'}
      data-selected={layoutCalibration.selectedTarget === 'screen' ? 'true' : 'false'}
      data-dragging={screenDrag.dragging ? 'true' : 'false'}
      role={screenDrag.role}
      tabIndex={screenDrag.tabIndex}
      aria-label="会议主题大屏幕"
      onPointerDown={screenDrag.onPointerDown}
      onKeyDown={screenDrag.onKeyDown}
      style={{
        left: `${placement.x}px`,
        top: `${placement.y}px`,
        width: `${placement.width}px`,
        height: `${placement.height}px`
      }}
    >
      <LetterGlitch className="screen-letter-glitch" text="AGENCY MEETING" cellCount={108} active={motionEnabled} />
      <h2 title={topic}>{compactTopic}</h2>
      {showJuryVote && (
        <div className="screen-jury-vote" aria-label="审议投票">
          <span data-side="a" title={`A：${getDeliberationOptionText(deliberation, 'a') || labelA}`}>
            <strong className="screen-jury-main">
              <b>A</b>
              <em>{labelA}</em>
              {voteRound && <i>{voteCounts?.a ?? 0}票</i>}
            </strong>
            {detailA && <small>{detailA}</small>}
          </span>
          <span data-side="z" title={`Z：${getDeliberationOptionText(deliberation, 'z') || labelZ}`}>
            <strong className="screen-jury-main">
              <b>Z</b>
              <em>{labelZ}</em>
              {voteRound && <i>{voteCounts?.z ?? 0}票</i>}
            </strong>
            {detailZ && <small>{detailZ}</small>}
          </span>
          <span data-side="b" title={`B：${getDeliberationOptionText(deliberation, 'b') || labelB}`}>
            <strong className="screen-jury-main">
              <b>B</b>
              <em>{labelB}</em>
              {voteRound && <i>{voteCounts?.b ?? 0}票</i>}
            </strong>
            {detailB && <small>{detailB}</small>}
          </span>
        </div>
      )}
      {voteRound && (
        <p className="screen-vote-round">{voteRound.label || voteRound.id || '投票'}</p>
      )}
    </section>
  );
}

function ThinkingEllipsis() {
  return (
    <span className="thinking-ellipsis" aria-label="正在思考">
      <i>.</i>
      <i>.</i>
      <i>.</i>
    </span>
  );
}

function TypewriterText({ text, isTyping, as: Tag = 'p' }) {
  const isThinking = isTyping && !text;

  return (
    <Tag data-thinking={isThinking ? 'true' : 'false'}>
      {isThinking ? (
        <ThinkingEllipsis />
      ) : (
        <>
          <span>{text}</span>
          <span className="type-cursor" data-active={isTyping ? 'true' : 'false'}>
            ▌
          </span>
        </>
      )}
    </Tag>
  );
}

function SpeechBubble({ turn, activeSeat, visibleText, isTyping, meetingRoleMeta = DEFAULT_ROLE_META }) {
  const scrollRef = useRef(null);
  const speaker = meetingRoleMeta[turn.speakerId] || { name: activeSeat?.label || '专家', title: '发言', lane: 'right' };
  const isHost = turn.speakerId === 'host';
  const lane = speaker.lane === 'center' ? 'right' : speaker.lane;
  const placement = activeSeat ? getSeatPlacement(activeSeat) : { y: 260 };
  const y = isHost ? 126 : Math.max(176, Math.min(676, placement.y - 16));
  const x = isHost ? 620 : lane === 'left' ? 56 : 798;

  useEffect(() => {
    const scrollBox = scrollRef.current;

    if (scrollBox) {
      scrollBox.scrollTop = scrollBox.scrollHeight;
    }
  }, [visibleText]);

  return (
    <aside
      key={turn.id}
      className={`speech-bubble speech-bubble-${lane}`}
      data-speaker={turn.speakerId}
      style={{
        left: `${x}px`,
        top: `${y}px`,
        '--bubble-width': isHost ? '238px' : '266px',
        '--bubble-height': isHost ? '108px' : '126px'
      }}
    >
      <div className="bubble-copy">
        <div className="bubble-meta">
          <span>{speaker.name}</span>
          <small>{speaker.title}</small>
        </div>
        <div ref={scrollRef} className="bubble-text-scroll">
          <TypewriterText text={visibleText} isTyping={isTyping} />
        </div>
      </div>
    </aside>
  );
}

function MeetingTranscript({ currentIndex, meetingTurns, meetingRoleMeta = DEFAULT_ROLE_META }) {
  const logRef = useRef(null);
  const visibleTurns = useMemo(
    () => meetingTurns.slice(0, Math.min(meetingTurns.length, Math.max(0, currentIndex + 1))),
    [currentIndex, meetingTurns]
  );

  useEffect(() => {
    const log = logRef.current;

    if (log) {
      log.scrollTop = log.scrollHeight;
    }
  }, [currentIndex, visibleTurns.length]);

  return (
    <section className="meeting-transcript" aria-label="文字版会议记录">
      <div className="transcript-heading">
        <span>会议记录</span>
        <small>{visibleTurns.length} / {meetingTurns.length} 条发言</small>
      </div>
      <div ref={logRef} className="transcript-log">
        {meetingTurns.length === 0 && (
          <article className="transcript-line transcript-line-empty">
            <div className="transcript-speaker">
              <strong>主持人</strong>
              <small>会议主持</small>
            </div>
            <p>正在等待主进程写入第一条实时发言。</p>
          </article>
        )}
        {visibleTurns.map((turn, index) => {
          const speaker = meetingRoleMeta[turn.speakerId] || { name: '专家', title: '发言' };
          const active = index === currentIndex;

          return (
            <article key={turn.id} className="transcript-line" data-active={active ? 'true' : 'false'}>
              <div className="transcript-speaker">
                <strong>{speaker.name}</strong>
                <small>{speaker.title}</small>
              </div>
              <p>{turn.text}</p>
            </article>
          );
        })}
      </div>
    </section>
  );
}

function MeetingSummaryFooter({ meetingSummary, meetingTurns, currentIndex }) {
  const summary = meetingSummary && typeof meetingSummary === 'object' ? meetingSummary : null;
  const isComplete = meetingTurns.length > 0 && currentIndex >= meetingTurns.length - 1;
  const consensus = Array.isArray(summary?.consensus) ? summary.consensus.filter(Boolean).slice(0, 2) : [];
  const implementationPlan = Array.isArray(summary?.implementationPlan) ? summary.implementationPlan.filter(Boolean).slice(0, 3) : [];
  const recommendedWorkers = Array.isArray(summary?.recommendedWorkers) ? summary.recommendedWorkers.filter(Boolean).slice(0, 3) : [];

  if (!summary || !isComplete || (consensus.length === 0 && implementationPlan.length === 0 && recommendedWorkers.length === 0)) {
    return null;
  }

  return (
    <section className="meeting-summary-footer" aria-label="会议结尾摘要">
      <div className="meeting-summary-heading">
        <span>结尾摘要</span>
        <small>仅保留精简结论</small>
      </div>
      {consensus.length > 0 && (
        <div className="meeting-summary-block">
          <strong>综合方案</strong>
          {consensus.map((item, index) => (
            <p key={`consensus-${index}`}>{item}</p>
          ))}
        </div>
      )}
      {implementationPlan.length > 0 && (
        <div className="meeting-summary-block">
          <strong>推荐任务</strong>
          {implementationPlan.map((item, index) => (
            <p key={`plan-${index}`}>
              {item.id ? `[${item.id}] ` : ''}{item.title || item.deliverable || '任务'}
            </p>
          ))}
        </div>
      )}
      {recommendedWorkers.length > 0 && (
        <div className="meeting-summary-block">
          <strong>推荐角色</strong>
          {recommendedWorkers.map((item, index) => (
            <p key={`worker-${index}`}>
              {item.name || item.title || '角色'}{item.task ? `：${item.task}` : ''}
            </p>
          ))}
        </div>
      )}
    </section>
  );
}

function TimelineStrip({ currentIndex, meetingTurns }) {
  return (
    <div className="timeline-strip" aria-label="meeting progress">
      {meetingTurns.map((turn, index) => (
        <span key={turn.id} data-active={index === currentIndex ? 'true' : 'false'} />
      ))}
    </div>
  );
}

function getStageProgressRoundLabel(turn, voteRound, isVoteMoment) {
  const phase = String(turn?.phase || '').trim();
  if (/^第.+轮$/.test(phase)) {
    return phase;
  }

  if (isVoteMoment) {
    const voteLabel = String(voteRound?.label || '').replace(/投票.*$/, '').replace(/后$/, '').trim();
    return voteLabel || phase || '当前轮';
  }

  if (phase) {
    return phase;
  }

  return '当前轮';
}

function getStageProgressState(turn, currentIndex, voteRound) {
  if (/结论|收束|结束/.test(String(turn?.phase || ''))) {
    return '收束中';
  }

  if (voteRound && voteRound.activationIndex === currentIndex) {
    return '投票中';
  }

  return '发言中';
}

function StageProgressHud({ turn, currentIndex, voteRound }) {
  const state = getStageProgressState(turn, currentIndex, voteRound);
  const roundLabel = getStageProgressRoundLabel(turn, voteRound, state === '投票中');

  return (
    <div className="stage-progress-hud" aria-label="会议阶段">
      <span>{roundLabel}</span>
      <strong>{state}</strong>
    </div>
  );
}

function getCalibrationTargetType(selectedTarget) {
  if (selectedTarget === 'screen') {
    return 'screen';
  }
  if (selectedTarget.startsWith('ambient-phone:')) {
    return 'ambient-phone';
  }
  if (selectedTarget.startsWith('ambient-zzz:')) {
    return 'ambient-zzz';
  }
  if (selectedTarget.startsWith('ambient-bubble:')) {
    return 'ambient-bubble';
  }
  if (selectedTarget.startsWith('seat:')) {
    return 'seat';
  }
  if (selectedTarget.startsWith('arm-shoulder:')) {
    return 'arm-shoulder';
  }
  if (selectedTarget.startsWith('arm-rest:')) {
    return 'arm-rest';
  }
  if (selectedTarget.startsWith('arm-target:')) {
    return 'arm-target';
  }
  if (selectedTarget.startsWith('arm-length:')) {
    return 'arm-length';
  }
  if (selectedTarget.startsWith('vote:')) {
    return 'vote';
  }
  return 'nameplate';
}

function parseVoteArmTarget(selectedTarget) {
  const match = String(selectedTarget || '').match(/^arm-(shoulder|rest|target|length):(.+)$/);
  if (!match) {
    return null;
  }

  return {
    pointType: match[1],
    roleId: match[2]
  };
}

function getDefaultAmbientDecorPlacement(seat, layoutPlacements, decorType) {
  const slotId = getSeatSlotId(seat);
  const seatPlacement = getSeatLayoutPlacement(seat, layoutPlacements);
  const seatWidth = seat.role === 'host' ? stageMetrics.hostWidth : stageMetrics.seatWidth;
  const sideSign = seat.role === 'right' ? 1 : -1;
  const voteArm = getVoteArmPlacement(seat, layoutPlacements);

  if (decorType === 'phone') {
    return {
      x: clampStageValue(voteArm.targetX + sideSign * 6, 0, stageMetrics.width),
      y: clampStageValue(voteArm.targetY - 10, 0, stageMetrics.height),
      rotate: seat.role === 'right' ? 16 : -16
    };
  }

  if (decorType === 'bubble') {
    return {
      x: clampStageValue(seatPlacement.x + sideSign * 14, 0, stageMetrics.width),
      y: clampStageValue(seatPlacement.y - seatWidth * 0.2, 0, stageMetrics.height),
      scale: 1,
      rotate: seat.role === 'right' ? 12 : -12
    };
  }

  return {
    x: clampStageValue(seatPlacement.x + sideSign * 6, 0, stageMetrics.width),
    y: clampStageValue(seatPlacement.y - seatWidth * 0.6, 0, stageMetrics.height),
    rotate: seat.role === 'right' ? 8 : -8
  };
}

function getMergedAmbientDecorPlacement(seat, layoutPlacements, overrides, decorType) {
  const slotId = getSeatSlotId(seat);
  const base = AMBIENT_DECOR_DEFAULTS?.[slotId]?.[decorType] || getDefaultAmbientDecorPlacement(seat, layoutPlacements, decorType);
  const slotOverrides = overrides?.[slotId]?.[decorType] || {};

  return {
    ...base,
    ...slotOverrides
  };
}

function getMergedAmbientDecorPlacements(seatPlan, layoutPlacements, overrides) {
  const seats = (seatPlan || [])
    .filter((seat) => !seat.empty && getSeatRoleId(seat) !== 'host' && isAmbientDebugSlot(getSeatSlotId(seat)));

  return Object.fromEntries(
    seats.map((seat) => {
      const slotId = getSeatSlotId(seat);
      return [slotId, {
        zzz: getMergedAmbientDecorPlacement(seat, layoutPlacements, overrides, 'zzz'),
        bubble: getMergedAmbientDecorPlacement(seat, layoutPlacements, overrides, 'bubble'),
        phone: getMergedAmbientDecorPlacement(seat, layoutPlacements, overrides, 'phone')
      }];
    })
  );
}

function getAmbientPhoneScreenMode(slotId) {
  return AMBIENT_PHONE_SCREEN_BY_SLOT[slotId] || 'chat';
}

function getAmbientPhoneTiming(slotId, mode) {
  const preset = PHONE_SCREEN_TIMING_BY_SLOT[slotId] || {};
  if (mode === 'chat') {
    return { delay: preset.delay || '-0.4s', duration: '3s' };
  }
  if (mode === 'video') {
    return { delay: preset.delay || '-1.1s', duration: '6s' };
  }
  return { delay: preset.delay || '-0.8s', duration: preset.duration || '4.8s' };
}

function formatCalibrationNumber(value, suffix = '') {
  if (typeof value !== 'number') {
    return `--${suffix}`;
  }

  return `${Number.isInteger(value) ? value : value.toFixed(2).replace(/0+$/, '').replace(/\.$/, '')}${suffix}`;
}

function CalibrationFineTune({ targetType, placement, onNudge }) {
  if (!placement) {
    return null;
  }

  const showCoordinates = targetType !== 'arm-length';
  const showY = showCoordinates && targetType !== 'seat';
  const showRotate = targetType === 'vote' || targetType === 'ambient-phone' || targetType === 'ambient-bubble' || targetType === 'ambient-zzz';
  const showScale = targetType === 'vote' || targetType === 'ambient-bubble';
  const showMirrorToggle = targetType === 'ambient-bubble';

  return (
    <div className="fine-tune-panel">
      <strong>精修</strong>
      {showCoordinates && (
        <div className="fine-tune-row">
          <span>{targetType === 'seat' ? '左右 X' : 'X'} {formatCalibrationNumber(placement.x)}</span>
          <button type="button" onClick={() => onNudge({ x: -10 })}>-10</button>
          <button type="button" onClick={() => onNudge({ x: -1 })}>-1</button>
          <button type="button" onClick={() => onNudge({ x: 1 })}>+1</button>
          <button type="button" onClick={() => onNudge({ x: 10 })}>+10</button>
        </div>
      )}
      {showY && (
        <div className="fine-tune-row">
          <span>Y {formatCalibrationNumber(placement.y)}</span>
          <button type="button" onClick={() => onNudge({ y: -10 })}>-10</button>
          <button type="button" onClick={() => onNudge({ y: -1 })}>-1</button>
          <button type="button" onClick={() => onNudge({ y: 1 })}>+1</button>
          <button type="button" onClick={() => onNudge({ y: 10 })}>+10</button>
        </div>
      )}
      {targetType === 'arm-length' && (
        <div className="fine-tune-row">
          <span>长度 {formatCalibrationNumber(placement.length)}</span>
          <button type="button" onClick={() => onNudge({ length: -10 })}>-10</button>
          <button type="button" onClick={() => onNudge({ length: -1 })}>-1</button>
          <button type="button" onClick={() => onNudge({ length: 1 })}>+1</button>
          <button type="button" onClick={() => onNudge({ length: 10 })}>+10</button>
        </div>
      )}
      {showRotate && (
        <div className="fine-tune-row">
          <span>旋转 {formatCalibrationNumber(placement.rotate || 0, '°')}</span>
          <button type="button" onClick={() => onNudge({ rotate: -5 })}>-5</button>
          <button type="button" onClick={() => onNudge({ rotate: -1 })}>-1</button>
          <button type="button" onClick={() => onNudge({ rotate: 1 })}>+1</button>
          <button type="button" onClick={() => onNudge({ rotate: 5 })}>+5</button>
        </div>
      )}
      {showScale && (
        <div className="fine-tune-row">
          <span>大小 {formatCalibrationNumber(placement.scale || 1)}</span>
          <button type="button" onClick={() => onNudge({ scale: -0.1 })}>-0.1</button>
          <button type="button" onClick={() => onNudge({ scale: -0.02 })}>-.02</button>
          <button type="button" onClick={() => onNudge({ scale: 0.02 })}>+.02</button>
          <button type="button" onClick={() => onNudge({ scale: 0.1 })}>+0.1</button>
        </div>
      )}
      {showMirrorToggle && (
        <div className="fine-tune-row">
          <span>左右翻转 {placement.mirrorX ? '开' : '关'}</span>
          <button type="button" onClick={() => onNudge({ mirrorX: !(placement.mirrorX || false) })}>
            切换
          </button>
        </div>
      )}
    </div>
  );
}

function MeetingStage({
  topic,
  meetingTurns = DEFAULT_MEETING_SCRIPT,
  meetingRoleMeta = DEFAULT_ROLE_META,
  meetingParticipants,
  thinkingRoleIds = [],
  turn,
  currentIndex,
  visibleText,
  isTyping,
  faceOverrides,
  layoutPlacements,
  layoutCalibration,
  deliberation,
  voteRound,
  voteCounts,
  voteSides = {},
  pendingVoteSides = {},
  voteAnimations = {},
  showVoteButtons = false,
  motionEnabled = true,
  ambientDebugEnabled = false
}) {
  const stageRef = useRef(null);
  useStageScale(stageRef);
  const meetingSeatPlan = useMemo(
    () => getMeetingSeatsForParticipants(meetingParticipants || getUniqueSpeakerIds(meetingTurns), meetingRoleMeta),
    [meetingParticipants, meetingRoleMeta, meetingTurns]
  );
  const displaySeatPlan = useMemo(
    () => (layoutCalibration.enabled ? getAllCalibrationSeatTargets(meetingSeatPlan) : meetingSeatPlan),
    [layoutCalibration.enabled, meetingSeatPlan]
  );
  const activeSeat = displaySeatPlan.find((seat) => getSeatRoleId(seat) === turn.speakerId);
  const thinkingRoleIdSet = useMemo(() => new Set(thinkingRoleIds), [thinkingRoleIds]);
  const calibrationTargetType = getCalibrationTargetType(layoutCalibration.selectedTarget || '');
  const shouldRenderVoteControls =
    showVoteButtons || (layoutCalibration.enabled && ['vote', 'arm'].includes(calibrationTargetType));

  return (
    <div ref={stageRef} className="meeting-stage">
      <div className="stage-background">
        <DotGrid
          dotSize={2}
          gap={28}
          baseColor="#d8dee8"
          activeColor="#ffffff"
          proximity={110}
          speedTrigger={1600}
          shockRadius={0}
          shockStrength={0}
          returnDuration={1.2}
          active={motionEnabled}
        />
      </div>
      <div className="stage-canvas">
        <StageProgressHud turn={turn} currentIndex={currentIndex} voteRound={voteRound} />
        <MeetingScreen
          topic={topic}
          placement={layoutPlacements.screen}
          layoutCalibration={layoutCalibration}
          deliberation={deliberation}
          voteRound={voteRound}
          voteCounts={voteCounts}
          motionEnabled={motionEnabled}
        />
        <SpeechBubble
          turn={turn}
          activeSeat={activeSeat}
          visibleText={visibleText}
          isTyping={isTyping}
          meetingRoleMeta={meetingRoleMeta}
        />
        <TimelineStrip currentIndex={currentIndex} meetingTurns={meetingTurns} />
        <StageImage
          className="stage-table"
          src={tableAsset}
          alt="白色竖向长会议桌"
          style={{
            left: '560px',
            top: '430px',
            width: `${stageMetrics.tableWidth}px`
          }}
        />
        {shouldRenderVoteControls && displaySeatPlan
          .filter((seat) => !seat.empty && getSeatRoleId(seat) !== 'host')
          .map((seat) => {
            const roleId = getSeatRoleId(seat);
            const pendingSide = pendingVoteSides[roleId];
            const animatedSide = (pendingSide === 'a' || pendingSide === 'b')
              ? pendingSide
              : ((voteAnimations[roleId] && (voteSides[roleId] === 'a' || voteSides[roleId] === 'b')) ? voteSides[roleId] : '');

            return (
              <VoteArmGesture
                key={`vote-arm-${seat.slotId}`}
                seat={seat}
                pendingSide={animatedSide}
                shouldAnimateVote={voteAnimations[roleId]}
                layoutPlacements={layoutPlacements}
                isCalibrating={layoutCalibration.enabled}
              />
            );
          })}
        {displaySeatPlan.map((seat) =>
          seat.empty ? (
            <EmptySeat key={seat.slotId} seat={seat} layoutPlacements={layoutPlacements} />
          ) : (
            <MeetingSeat
              key={seat.slotId}
              seat={seat}
              turn={turn}
              isSpeaking={isTyping}
              isThinking={thinkingRoleIdSet.has(getSeatRoleId(seat))}
              meetingRoleMeta={meetingRoleMeta}
              faceOverrides={faceOverrides}
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
              voteSide={voteSides[getSeatRoleId(seat)]}
              ambientDebugEnabled={ambientDebugEnabled}
            />
          )
        )}
        {shouldRenderVoteControls && displaySeatPlan
          .filter((seat) => !seat.empty && getSeatRoleId(seat) !== 'host')
          .map((seat) => (
            <SeatVoteButtons
              key={`vote-buttons-${seat.slotId}`}
              seat={seat}
              selectedSide={voteSides[getSeatRoleId(seat)]}
              pendingSide={pendingVoteSides[getSeatRoleId(seat)]}
              shouldAnimateVote={voteAnimations[getSeatRoleId(seat)]}
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
            />
          ))}
        {shouldRenderVoteControls && displaySeatPlan
          .filter((seat) => !seat.empty && getSeatRoleId(seat) !== 'host')
          .flatMap((seat) => [
            <VoteArmCalibrationPoint
              key={`vote-arm-shoulder-${seat.slotId}`}
              seat={seat}
              pointType="shoulder"
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
            />,
            <VoteArmCalibrationPoint
              key={`vote-arm-rest-${seat.slotId}`}
              seat={seat}
              pointType="rest"
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
            />,
            <VoteArmCalibrationPoint
              key={`vote-arm-target-${seat.slotId}`}
              seat={seat}
              pointType="target"
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
            />
          ])}
        {layoutCalibration.enabled && displaySeatPlan
          .filter((seat) => !seat.empty && getSeatRoleId(seat) !== 'host')
          .map((seat) => (
            <SeatCalibrationPoint
              key={`seat-point-${seat.slotId}`}
              seat={seat}
              layoutPlacements={layoutPlacements}
              layoutCalibration={layoutCalibration}
            />
          ))}
      </div>
    </div>
  );
}

function useMeetingTransition({ enabled, hasPreviousMeeting, transitionKey }) {
  const steps = hasPreviousMeeting ? TRANSITION_STEPS_WITH_PREVIOUS : TRANSITION_STEPS_FRESH;
  const [transitionState, setTransitionState] = useState({
    stepIndex: enabled ? 0 : steps.length,
    visible: enabled
  });
  const { stepIndex, visible } = transitionState;

  useEffect(() => {
    setTransitionState({
      stepIndex: enabled ? 0 : steps.length,
      visible: enabled
    });
  }, [enabled, steps.length, transitionKey]);

  useEffect(() => {
    if (!enabled || !visible) {
      return undefined;
    }

    if (stepIndex >= steps.length) {
      const timer = window.setTimeout(
        () => setTransitionState((current) => ({ ...current, visible: false })),
        TRANSITION_FADE_OUT_MS
      );
      return () => window.clearTimeout(timer);
    }

    const timer = window.setTimeout(
      () => setTransitionState((current) => ({ ...current, stepIndex: current.stepIndex + 1 })),
      TRANSITION_STEP_MS
    );
    return () => window.clearTimeout(timer);
  }, [enabled, stepIndex, steps.length, visible]);

  return {
    visible,
    done: !visible,
    fadingOut: stepIndex >= steps.length,
    label: stepIndex >= steps.length ? '会议开始' : steps[stepIndex]
  };
}

function useMeetingPlayback(meetingTurns, ready = true, playbackKey = 0, voteActivationIndexes = new Set(), pendingTurn = null) {
  const hasLiveTurns = meetingTurns.length > 0;
  const hasPendingTurn = Boolean(pendingTurn?.speakerId);
  const turns = hasLiveTurns ? meetingTurns : hasPendingTurn ? [pendingTurn] : [EMPTY_LIVE_TURN];
  const [currentIndex, setCurrentIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [elapsedMs, setElapsedMs] = useState(0);
  const [finished, setFinished] = useState(false);
  const safeCurrentIndex = Math.min(currentIndex, turns.length - 1);
  const hasCurrentVoteMoment = voteActivationIndexes.has(safeCurrentIndex);
  const shouldShowPendingTurn = hasPendingTurn && (!hasLiveTurns || finished);

  useEffect(() => {
    setCurrentIndex(0);
    setPaused(false);
    setElapsedMs(0);
    setFinished(false);
  }, [playbackKey]);

  useEffect(() => {
    if (finished && currentIndex < turns.length - 1) {
      setCurrentIndex(turns.length - 1);
      setFinished(false);
      setElapsedMs(0);
    }
  }, [currentIndex, finished, turns.length]);

  useEffect(() => {
    if (!ready || paused || finished || !hasLiveTurns || shouldShowPendingTurn) {
      return undefined;
    }

    const timer = window.setInterval(() => {
      setElapsedMs((value) => Math.min(value + TYPE_TICK_MS, getTurnDuration(turns[safeCurrentIndex], hasCurrentVoteMoment)));
    }, TYPE_TICK_MS);

    return () => window.clearInterval(timer);
  }, [paused, finished, ready, safeCurrentIndex, turns, hasCurrentVoteMoment, hasLiveTurns, shouldShowPendingTurn]);

  useEffect(() => {
    if (!ready || paused || finished || !hasLiveTurns || shouldShowPendingTurn) {
      return undefined;
    }

    const turn = turns[safeCurrentIndex];

    if (elapsedMs < getTurnDuration(turn, hasCurrentVoteMoment)) {
      return undefined;
    }

    if (currentIndex >= turns.length - 1) {
      setFinished(true);
      return undefined;
    }

    const timer = window.setTimeout(() => {
      setCurrentIndex((value) => Math.min(value + 1, turns.length - 1));
      setElapsedMs(0);
    }, 0);

    return () => window.clearTimeout(timer);
  }, [currentIndex, elapsedMs, paused, finished, ready, safeCurrentIndex, turns, hasCurrentVoteMoment, hasLiveTurns, shouldShowPendingTurn]);

  const turn = shouldShowPendingTurn ? pendingTurn : turns[safeCurrentIndex] || turns[0];
  const visibleText = shouldShowPendingTurn ? '' : hasLiveTurns ? getVisibleTurnText(turn, elapsedMs) : turn.text;
  const isTyping = shouldShowPendingTurn || (hasLiveTurns && !finished && visibleText.length < turn.text.length);
  const textCompleteMs = shouldShowPendingTurn ? Number.POSITIVE_INFINITY : getTurnTextCompleteMs(turn);
  const turnTextComplete = !shouldShowPendingTurn && !isTyping && elapsedMs >= textCompleteMs;
  const voteRevealReady = !shouldShowPendingTurn && turnTextComplete && elapsedMs >= Math.min(getTurnDuration(turn, hasCurrentVoteMoment), textCompleteMs + VOTE_REVEAL_DELAY_MS);

  const goToNextTurn = () => {
    if (currentIndex >= turns.length - 1) {
      setElapsedMs(getTurnDuration(turns[safeCurrentIndex], hasCurrentVoteMoment));
      setFinished(true);
      return;
    }

    setCurrentIndex((value) => Math.min(value + 1, turns.length - 1));
    setElapsedMs(0);
    setFinished(false);
  };

  const goToPreviousTurn = () => {
    if (currentIndex <= 0) {
      setCurrentIndex(0);
      setElapsedMs(0);
      setFinished(false);
      return;
    }

    setCurrentIndex((value) => Math.max(value - 1, 0));
    setElapsedMs(0);
    setFinished(false);
  };

  return {
    currentIndex,
    paused,
    finished: finished && !shouldShowPendingTurn,
    isPending: shouldShowPendingTurn,
    turn,
    visibleText,
    isTyping,
    elapsedMs,
    turnTextComplete,
    voteRevealReady,
    togglePaused: () => {
      if (!finished) {
        setPaused((value) => !value);
      }
    },
    previous: goToPreviousTurn,
    next: goToNextTurn
  };
}

function LayoutCalibrationPanel({
  enabled,
  calibrationEnabled,
  seatPlan,
  selectedTarget,
  selectedPlacement,
  votePreviewSide,
  copyState,
  onToggle,
  onToggleCalibration,
  onSelectTarget,
  onSetVotePreviewSide,
  onNudgeSelectedTarget,
  onCopy,
  onResetCurrent,
  onResetAll
}) {
  const activeNameplateTargets = (seatPlan || meetingSeats).filter((seat) => !seat.empty).map((seat) => getSeatSlotId(seat));
  const activeVoteTargets = (seatPlan || meetingSeats)
    .filter((seat) => getSeatRoleId(seat) !== 'host')
    .map((seat) => getSeatSlotId(seat));
  const activeSeatTargets = activeVoteTargets;
  const activeArmTargets = activeVoteTargets;
  const ambientTargets = (seatPlan || meetingSeats)
    .filter((seat) => !seat.empty && isAmbientDebugSlot(getSeatSlotId(seat)))
    .map((seat) => getSeatSlotId(seat));
  const seatLabelBySlot = Object.fromEntries(
    (seatPlan || meetingSeats).map((seat) => [getSeatSlotId(seat), seat.label || getRoleLabel(getSeatSlotId(seat))])
  );
  const armTarget = parseVoteArmTarget(selectedTarget);
  const ambientTarget = parseAmbientDecorTarget(selectedTarget);
  const selectedLabel = (() => {
    if (selectedTarget === 'screen') {
      return '大屏幕';
    }
    if (ambientTarget) {
      const seatLabel = seatLabelBySlot[ambientTarget.roleId] || ambientTarget.roleId;
      const labelByType = {
        phone: '手机',
        zzz: 'zzz',
        bubble: '睡觉鼻涕泡'
      };
      return `${seatLabel}${labelByType[ambientTarget.decorType] || '氛围元素'}`;
    }
    if (selectedTarget.startsWith('seat:')) {
      const roleId = selectedTarget.replace(/^seat:/, '');
      return `${seatLabelBySlot[roleId] || roleId}座位左右`;
    }
    if (armTarget) {
      const seatLabel = seatLabelBySlot[armTarget.roleId] || armTarget.roleId;
      const labelByType = {
        shoulder: '肩膀锚点',
        rest: '初始手位',
        target: '投票手位',
        length: '手臂长度'
      };
      return `${seatLabel}${labelByType[armTarget.pointType] || '投票手臂'}`;
    }
    if (selectedTarget.startsWith('vote:')) {
      const roleId = selectedTarget.replace(/^vote:/, '');
      return `${seatLabelBySlot[roleId] || roleId}投票按钮`;
    }

    return `${seatLabelBySlot[selectedTarget] || selectedTarget}铭牌`;
  })();
  const selectedTargetType = getCalibrationTargetType(selectedTarget);

  if (!enabled) {
    return null;
  }

  return (
    <aside className="calibration-panel" data-open="true">
      <div className="calibration-panel-heading">
        <strong>设置</strong>
        <button type="button" onClick={onToggle}>
          关闭
        </button>
      </div>
      <div className="settings-section">
        <strong>氛围组校准</strong>
        <p>打开设置后，后五席会同时显示 zzz、睡觉鼻涕泡、手机，手机屏幕固定混排 3 种内容，方便一次性定位 15 个元素。</p>
        <div className="layout-target-tabs" aria-label="选择氛围组校准目标">
          <span>手机</span>
          {ambientTargets.map((roleId) => (
            <button
              key={`ambient-phone-${roleId}`}
              type="button"
              data-active={selectedTarget === `ambient-phone:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`ambient-phone:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || roleId}
            </button>
          ))}
          <span>zzz</span>
          {ambientTargets.map((roleId) => (
            <button
              key={`ambient-zzz-${roleId}`}
              type="button"
              data-active={selectedTarget === `ambient-zzz:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`ambient-zzz:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || roleId}
            </button>
          ))}
          <span>鼻涕泡</span>
          {ambientTargets.map((roleId) => (
            <button
              key={`ambient-bubble-${roleId}`}
              type="button"
              data-active={selectedTarget === `ambient-bubble:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`ambient-bubble:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || roleId}
            </button>
          ))}
        </div>
      </div>
      <div className="settings-section">
        <strong>投票按钮测试</strong>
        <div className="calibration-actions">
          <button type="button" data-active={votePreviewSide === 'a' ? 'true' : 'false'} onClick={() => onSetVotePreviewSide('a')}>
            伸手测试 A
          </button>
          <button type="button" data-active={votePreviewSide === 'b' ? 'true' : 'false'} onClick={() => onSetVotePreviewSide('b')}>
            伸手测试 B
          </button>
          <button type="button" onClick={() => onSetVotePreviewSide('')}>
            关闭测试
          </button>
        </div>
        <p>测试时才临时切换投票按钮预览，不改会议数据。</p>
      </div>
      <div className="settings-section">
        <strong>布局校准</strong>
        <div className="calibration-actions">
          <button type="button" data-active={calibrationEnabled ? 'true' : 'false'} onClick={onToggleCalibration}>
            {calibrationEnabled ? '拖动开启' : '拖动关闭'}
          </button>
        </div>
      </div>
      <p>当前：{selectedLabel}。氛围组元素可直接拖动本体；手机支持位置与角度微调，鼻涕泡支持位置与缩放微调。</p>
      <CalibrationFineTune
        targetType={selectedTargetType}
        placement={selectedPlacement}
        onNudge={onNudgeSelectedTarget}
      />
      <details className="settings-advanced">
        <summary>高级设置</summary>
        <div className="layout-target-tabs" aria-label="选择布局校准目标">
          <button
            type="button"
            data-active={selectedTarget === 'screen' ? 'true' : 'false'}
            onClick={() => onSelectTarget('screen')}
          >
            大屏幕
          </button>
          <span>铭牌</span>
          {activeNameplateTargets.map((roleId) => (
            <button
              key={roleId}
              type="button"
              data-active={selectedTarget === roleId ? 'true' : 'false'}
              onClick={() => onSelectTarget(roleId)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>投票按钮</span>
          {activeVoteTargets.map((roleId) => (
            <button
              key={`vote-${roleId}`}
              type="button"
              data-active={selectedTarget === `vote:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`vote:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>座位左右</span>
          {activeSeatTargets.map((roleId) => (
            <button
              key={`seat-${roleId}`}
              type="button"
              data-active={selectedTarget === `seat:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`seat:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>肩膀锚点</span>
          {activeArmTargets.map((roleId) => (
            <button
              key={`arm-shoulder-${roleId}`}
              type="button"
              data-active={selectedTarget === `arm-shoulder:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`arm-shoulder:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>初始手位</span>
          {activeArmTargets.map((roleId) => (
            <button
              key={`arm-rest-${roleId}`}
              type="button"
              data-active={selectedTarget === `arm-rest:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`arm-rest:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>投票手位</span>
          {activeArmTargets.map((roleId) => (
            <button
              key={`arm-target-${roleId}`}
              type="button"
              data-active={selectedTarget === `arm-target:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`arm-target:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
          <span>手臂长度</span>
          {activeArmTargets.map((roleId) => (
            <button
              key={`arm-length-${roleId}`}
              type="button"
              data-active={selectedTarget === `arm-length:${roleId}` ? 'true' : 'false'}
              onClick={() => onSelectTarget(`arm-length:${roleId}`)}
            >
              {seatLabelBySlot[roleId] || getRoleLabel(roleId)}
            </button>
          ))}
        </div>
      </details>
      <div className="calibration-actions">
        <button type="button" onClick={onCopy}>复制 JSON</button>
        <button type="button" onClick={onResetCurrent}>重置当前</button>
        <button type="button" onClick={onResetAll}>清空全部</button>
      </div>
      <span className="copy-state">{copyState}</span>
    </aside>
  );
}

function MeetingHistoryDrawer({ open, meetings, activeMeetingId, onReplay, onClose }) {
  return (
    <div className="history-layer" data-open={open ? 'true' : 'false'} aria-hidden={open ? 'false' : 'true'}>
      <button className="history-scrim" type="button" aria-label="关闭历史会议" onClick={onClose} />
      <aside className="history-drawer" aria-label="历史会议列表">
        <div className="history-drawer-head">
          <div>
            <strong>历史会议</strong>
            <small>最近 {meetings.length} / {MEETING_HISTORY_LIMIT}</small>
          </div>
          <button type="button" onClick={onClose} aria-label="关闭历史会议">
            关闭
          </button>
        </div>
        <div className="history-list">
          {meetings.length === 0 ? (
            <p>暂无历史会议</p>
          ) : (
            meetings.map((meeting) => (
              <button
                key={meeting.id}
                className="history-row"
                type="button"
                data-active={meeting.id === activeMeetingId ? 'true' : 'false'}
                onClick={() => onReplay(meeting)}
              >
                <time>{formatMeetingTime(getMeetingHistoryTime(meeting))}</time>
                <span>{meeting.topic}</span>
              </button>
            ))
          )}
        </div>
      </aside>
    </div>
  );
}

function MeetingTransitionOverlay({ transition }) {
  if (!transition.visible) {
    return null;
  }

  return (
    <div className="meeting-transition" data-fading={transition.fadingOut ? 'true' : 'false'}>
      <div className="meeting-transition-copy">
        <span>会议室转场</span>
        <strong>{transition.label}</strong>
      </div>
    </div>
  );
}

export default function App() {
  const searchParams = useMemo(
    () => (typeof window === 'undefined' ? new URLSearchParams() : new URLSearchParams(window.location.search)),
    []
  );
  const stageOnly = searchParams.get('record') === 'stage';
  const layoutCalibrationRequested = searchParams.get('calibrate') === 'layout';
  const externalSessionUrl = useMemo(() => getRequestedSessionUrl(searchParams), [searchParams]);
  const currentMeetingRef = useRef(null);
  if (!currentMeetingRef.current) {
    currentMeetingRef.current = createMeetingHistoryEntry();
  }

  const [activeMeeting, setActiveMeeting] = useState(currentMeetingRef.current);
  const [playbackKey, setPlaybackKey] = useState(0);
  const [meetingHistory, setMeetingHistory] = useState(() =>
    normalizeMeetingHistory(readStoredJson(MEETING_HISTORY_STORAGE_KEY, []))
  );
  const activeMeetingTurns = useMemo(() => getMeetingTurns(activeMeeting), [activeMeeting]);
  const activeMeetingRoleMeta = useMemo(() => getMeetingRoleMeta(activeMeeting), [activeMeeting]);
  const activeMeetingParticipants = useMemo(() => getMeetingParticipants(activeMeeting), [activeMeeting]);
  const activeMeetingThinking = useMemo(() => getMeetingThinkingRoleIds(activeMeeting), [activeMeeting]);
  const activeMeetingPendingTurn = useMemo(() => getMeetingPendingTurn(activeMeeting), [activeMeeting]);
  const calibrationSeatPlan = useMemo(
    () => getAllCalibrationSeatTargets(getMeetingSeatsForParticipants(activeMeetingParticipants, activeMeetingRoleMeta)),
    [activeMeetingParticipants, activeMeetingRoleMeta]
  );
  const hasPreviousMeeting = meetingHistory.some((meeting) => meeting.id !== currentMeetingRef.current.id);
  const transition = useMeetingTransition({ enabled: true, hasPreviousMeeting, transitionKey: playbackKey });
  const voteActivationIndexes = useMemo(
    () => new Set(getVoteRoundsWithActivation(activeMeeting).map((round) => round.activationIndex)),
    [activeMeeting]
  );
  const playback = useMeetingPlayback(activeMeetingTurns, transition.done, playbackKey, voteActivationIndexes, activeMeetingPendingTurn);
  const pageVisible = usePageVisible();
  const motionEnabled = pageVisible && !playback.finished && !playback.paused;
  const sessionPollMs = pageVisible
    ? playback.finished
      ? SESSION_IDLE_POLL_MS
      : SESSION_ACTIVE_POLL_MS
    : SESSION_HIDDEN_POLL_MS;
  const activeMeetingDeliberation = useMemo(
    () => (isJuryDeliberationMeeting(activeMeeting) ? activeMeeting.deliberation || { enabled: true } : null),
    [activeMeeting]
  );
  const activeVotingRound = useMemo(
    () => (playback.turnTextComplete ? getVoteRoundForIndex(activeMeeting, playback.currentIndex) : null),
    [activeMeeting, playback.currentIndex, playback.turnTextComplete]
  );
  const pendingVoteRound = playback.voteRevealReady ? null : activeVotingRound;
  const settledVoteRound = useMemo(
    () => getVisibleVoteRound(activeMeeting, playback.currentIndex, playback.voteRevealReady),
    [activeMeeting, playback.currentIndex, playback.voteRevealReady]
  );
  const naturalVoteSides = useMemo(
    () => getJuryVotesForRound(activeMeeting, settledVoteRound),
    [activeMeeting, settledVoteRound]
  );
  const [votePreviewSide, setVotePreviewSide] = useState('');
  const pendingVoteSides = useMemo(
    () => (!votePreviewSide && pendingVoteRound ? getJuryVotesForRound(activeMeeting, pendingVoteRound) : {}),
    [activeMeeting, pendingVoteRound, votePreviewSide]
  );
  const activeVoteSides = useMemo(() => {
    if (!votePreviewSide) {
      return naturalVoteSides;
    }

    return Object.fromEntries(
      activeMeetingParticipants
        .filter((speakerId) => speakerId && speakerId !== 'host')
        .map((speakerId) => [speakerId, votePreviewSide])
    );
  }, [activeMeetingParticipants, naturalVoteSides, votePreviewSide]);
  const activeVoteAnimations = useMemo(
    () => {
      if (!votePreviewSide) {
        return pendingVoteRound ? getJuryVoteAnimationMapForRound(activeMeeting, pendingVoteRound) : {};
      }

      return Object.fromEntries(
        activeMeetingParticipants
          .filter((speakerId) => speakerId && speakerId !== 'host')
          .map((speakerId) => [speakerId, true])
      );
    },
    [activeMeeting, activeMeetingParticipants, pendingVoteRound, votePreviewSide]
  );
  const activeVoteRound = useMemo(
    () => activeVotingRound || settledVoteRound,
    [activeVotingRound, settledVoteRound]
  );
  const activeVoteCounts = useMemo(
    () => getJuryVoteCounts(activeVoteSides),
    [activeVoteSides]
  );
  const showVoteButtons = Boolean(votePreviewSide || activeVoteRound || (activeMeetingDeliberation && activeMeeting.mode === 'jury_deliberation'));
  const faceOverrides = useMemo(() => ({}), []);
  const [layoutOverrides, setLayoutOverrides] = useState(() =>
    normalizeStoredLayoutOverrides(readStoredJson(NAMEPLATE_CALIBRATION_STORAGE_KEY, {}))
  );
  const [calibrationEnabled, setCalibrationEnabled] = useState(() => {
    if (typeof window === 'undefined') {
      return false;
    }

    return layoutCalibrationRequested || window.localStorage.getItem(NAMEPLATE_CALIBRATION_OPEN_KEY) === 'true';
  });
  const [selectedTarget, setSelectedTarget] = useState('screen');
  const [copyState, setCopyState] = useState('拖动座位、手臂、铭牌、大屏或按钮后可复制 JSON');
  const [historyOpen, setHistoryOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(layoutCalibrationRequested);
  const progressText = useMemo(
    () => {
      if (playback.isPending) {
        return '思考中';
      }

      if (activeMeetingTurns.length === 0) {
        return '等待写入';
      }

      return `${playback.currentIndex + 1} / ${activeMeetingTurns.length}`;
    },
    [activeMeetingTurns.length, playback.currentIndex, playback.isPending]
  );
  const layoutPlacements = useMemo(() => {
    const voteButtons = getMergedVoteButtonPlacements(layoutOverrides.voteButtons);
    const seats = getMergedSeatPlacements(calibrationSeatPlan, layoutOverrides.seats);
    const basePlacements = {
      seats,
      nameplates: getMergedNameplatePlacements(layoutOverrides.nameplates),
      voteButtons,
      voteArms: getMergedVoteArmPlacements(calibrationSeatPlan, seats, voteButtons, layoutOverrides.voteArms),
      screen: mergeScreenPlacement(layoutOverrides.screen)
    };

    return {
      ...basePlacements,
      ambientDecor: getMergedAmbientDecorPlacements(calibrationSeatPlan, basePlacements, layoutOverrides.ambientDecor)
    };
  }, [calibrationSeatPlan, layoutOverrides]);
  const selectedPlacement = useMemo(() => {
    if (selectedTarget === 'screen') {
      return layoutPlacements.screen;
    }
    const ambientTarget = parseAmbientDecorTarget(selectedTarget);
    if (ambientTarget) {
      return layoutPlacements.ambientDecor?.[ambientTarget.roleId]?.[ambientTarget.decorType] || null;
    }
    if (selectedTarget.startsWith('seat:')) {
      return layoutPlacements.seats[selectedTarget.replace(/^seat:/, '')];
    }
    const armTarget = parseVoteArmTarget(selectedTarget);
    if (armTarget) {
      const placement = layoutPlacements.voteArms[armTarget.roleId];

      if (!placement) {
        return null;
      }

      if (armTarget.pointType === 'length') {
        return { length: placement.length };
      }

      const pointByType = {
        shoulder: { x: placement.shoulderX, y: placement.shoulderY },
        rest: { x: placement.restX, y: placement.restY },
        target: { x: placement.targetX, y: placement.targetY }
      };

      return pointByType[armTarget.pointType] || null;
    }
    if (selectedTarget.startsWith('vote:')) {
      return layoutPlacements.voteButtons[selectedTarget.replace(/^vote:/, '')];
    }

    return layoutPlacements.nameplates[selectedTarget];
  }, [layoutPlacements, selectedTarget]);

  useEffect(() => {
    window.localStorage.setItem(NAMEPLATE_CALIBRATION_STORAGE_KEY, JSON.stringify(layoutOverrides));
  }, [layoutOverrides]);

  useEffect(() => {
    window.localStorage.setItem(NAMEPLATE_CALIBRATION_OPEN_KEY, calibrationEnabled ? 'true' : 'false');
  }, [calibrationEnabled]);

  useEffect(() => {
    window.localStorage.setItem(MEETING_HISTORY_STORAGE_KEY, JSON.stringify(meetingHistory));
  }, [meetingHistory]);

  useEffect(() => {
    if (!externalSessionUrl) {
      return undefined;
    }

    let cancelled = false;
    let loading = false;

    const loadExternalSession = () => {
      if (loading) {
        return;
      }

      loading = true;

      fetch(getNoStoreSessionUrl(externalSessionUrl), { cache: 'no-store' })
        .then((response) => {
          if (!response.ok) {
            return null;
          }

          return response.json();
        })
        .then((session) => {
          if (cancelled || !session) {
            return;
          }

          const meeting = createMeetingHistoryEntryFromSession(session);
          if (!meeting) {
            return;
          }

          const previousMeeting = currentMeetingRef.current;
          const sameMeeting = meeting.id === previousMeeting?.id;
          const hasLiveChange = getMeetingLiveSignature(meeting) !== getMeetingLiveSignature(previousMeeting);
          if (sameMeeting && !hasLiveChange) {
            return;
          }

          currentMeetingRef.current = meeting;
          setActiveMeeting(meeting);
          setMeetingHistory((current) => normalizeMeetingHistory([meeting, ...current.filter((item) => item.id !== meeting.id)]));
          if (!sameMeeting) {
            setPlaybackKey((value) => value + 1);
          }
        })
        .catch(() => {})
        .finally(() => {
          loading = false;
        });
    };

    loadExternalSession();
    const timer = window.setInterval(loadExternalSession, sessionPollMs);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [externalSessionUrl, sessionPollMs]);

  useEffect(() => {
    if (!playback.finished || activeMeeting.id !== currentMeetingRef.current.id) {
      return;
    }

    setMeetingHistory((current) =>
      normalizeMeetingHistory(
        current.map((meeting) =>
          meeting.id === currentMeetingRef.current.id
            ? { ...meeting, endedAt: new Date().toISOString(), status: 'done' }
            : meeting
        )
      )
    );
  }, [activeMeeting.id, playback.finished]);

  const moveNameplate = (roleId, point) => {
    setLayoutOverrides((current) => ({
      ...current,
      nameplates: {
        ...(current.nameplates || {}),
        [roleId]: {
          ...(current.nameplates?.[roleId] || {}),
          x: clampStageValue(point.x, 0, stageMetrics.width),
          y: clampStageValue(point.y, 0, stageMetrics.height)
        }
      }
    }));
    setSelectedTarget(roleId);
    setCopyState('有未固化布局调整');
  };

  const moveScreen = (point) => {
    setLayoutOverrides((current) => ({
      ...current,
      screen: {
        ...(current.screen || {}),
        x: clampStageValue(point.x, 0, stageMetrics.width),
        y: clampStageValue(point.y, 0, stageMetrics.height)
      }
    }));
    setSelectedTarget('screen');
    setCopyState('有未固化布局调整');
  };

  const moveVoteButton = (roleId, point) => {
    setLayoutOverrides((current) => ({
      ...current,
      voteButtons: {
        ...(current.voteButtons || {}),
        [roleId]: {
          ...(current.voteButtons?.[roleId] || {}),
          x: clampStageValue(point.x, 0, stageMetrics.width),
          y: clampStageValue(point.y, 0, stageMetrics.height)
        }
      }
    }));
    setSelectedTarget(`vote:${roleId}`);
    setCopyState('有未固化投票按钮布局调整');
  };

  const moveSeat = (roleId, point) => {
    setLayoutOverrides((current) => ({
      ...current,
      seats: {
        ...(current.seats || {}),
        [roleId]: {
          ...(current.seats?.[roleId] || {}),
          x: clampStageValue(point.x, 0, stageMetrics.width)
        }
      }
    }));
    setSelectedTarget(`seat:${roleId}`);
    setCopyState('有未固化座位左右调整');
  };

  const moveVoteArmPoint = (roleId, pointType, point) => {
    const seatPlacement = layoutPlacements.seats[roleId];
    const armPlacement = layoutPlacements.voteArms[roleId];
    if (!seatPlacement || !armPlacement) {
      return;
    }

    const nextPatchByType = {
      shoulder: {
        shoulderOffsetX: clampStageValue(point.x - seatPlacement.x, -180, 180),
        shoulderOffsetY: clampStageValue(point.y - seatPlacement.y, -140, 140)
      },
      rest: {
        restOffsetX: clampStageValue(point.x - armPlacement.shoulderX, -220, 220),
        restOffsetY: clampStageValue(point.y - armPlacement.shoulderY, -220, 220)
      },
      target: {
        targetX: clampStageValue(point.x, 0, stageMetrics.width),
        targetY: clampStageValue(point.y, 0, stageMetrics.height)
      }
    };
    const patch = nextPatchByType[pointType];

    setLayoutOverrides((current) => ({
      ...current,
      voteArms: {
        ...(current.voteArms || {}),
        [roleId]: {
          ...(current.voteArms?.[roleId] || {}),
          ...(patch || {})
        }
      }
    }));
    setSelectedTarget(`arm-${pointType}:${roleId}`);
    setCopyState('有未固化投票手臂调整');
  };

  const moveAmbientDecor = (roleId, decorType, point) => {
    const base = layoutPlacements.ambientDecor?.[roleId]?.[decorType];
    if (!base) {
      return;
    }

    setLayoutOverrides((current) => ({
      ...current,
      ambientDecor: {
        ...(current.ambientDecor || {}),
        [roleId]: {
          ...(current.ambientDecor?.[roleId] || {}),
          [decorType]: {
            ...(current.ambientDecor?.[roleId]?.[decorType] || {}),
            x: clampStageValue(point.x, 0, stageMetrics.width),
            y: clampStageValue(point.y, 0, stageMetrics.height)
          }
        }
      }
    }));
    setSelectedTarget(`ambient-${decorType}:${roleId}`);
    setCopyState('有未固化氛围组元素调整');
  };

  const nudgeSelectedTarget = (delta) => {
    setLayoutOverrides((current) => {
      const next = { ...current };

      if (selectedTarget === 'screen') {
        const base = layoutPlacements.screen;
        next.screen = {
          ...(current.screen || {}),
          x: clampStageValue(base.x + (delta.x || 0), 0, stageMetrics.width),
          y: clampStageValue(base.y + (delta.y || 0), 0, stageMetrics.height)
        };
        return next;
      }

      if (selectedTarget.startsWith('seat:')) {
        const roleId = selectedTarget.replace(/^seat:/, '');
        const base = layoutPlacements.seats[roleId];
        if (!base) {
          return next;
        }

        next.seats = {
          ...(current.seats || {}),
          [roleId]: {
            ...(current.seats?.[roleId] || {}),
            x: clampStageValue(base.x + (delta.x || 0), 0, stageMetrics.width)
          }
        };
        return next;
      }

      const armTarget = parseVoteArmTarget(selectedTarget);
      if (armTarget) {
        const base = layoutPlacements.voteArms[armTarget.roleId];
        const seatBase = layoutPlacements.seats[armTarget.roleId];
        if (!base || !seatBase) {
          return next;
        }

        const currentArm = current.voteArms?.[armTarget.roleId] || {};
        const nextArm = { ...currentArm };

        if (armTarget.pointType === 'length') {
          nextArm.length = clampStageValue(base.length + (delta.length || 0), 24, 360);
        } else if (armTarget.pointType === 'shoulder') {
          nextArm.shoulderOffsetX = clampStageValue(base.shoulderX + (delta.x || 0) - seatBase.x, -180, 180);
          nextArm.shoulderOffsetY = clampStageValue(base.shoulderY + (delta.y || 0) - seatBase.y, -140, 140);
        } else if (armTarget.pointType === 'rest') {
          nextArm.restOffsetX = clampStageValue(base.restX + (delta.x || 0) - base.shoulderX, -220, 220);
          nextArm.restOffsetY = clampStageValue(base.restY + (delta.y || 0) - base.shoulderY, -220, 220);
        } else if (armTarget.pointType === 'target') {
          nextArm.targetX = clampStageValue(base.targetX + (delta.x || 0), 0, stageMetrics.width);
          nextArm.targetY = clampStageValue(base.targetY + (delta.y || 0), 0, stageMetrics.height);
        }

        next.voteArms = {
          ...(current.voteArms || {}),
          [armTarget.roleId]: nextArm
        };
        return next;
      }

      if (selectedTarget.startsWith('vote:')) {
        const roleId = selectedTarget.replace(/^vote:/, '');
        const base = layoutPlacements.voteButtons[roleId] || voteButtonPlacements[roleId] || voteButtonPlacements.host;
        next.voteButtons = {
          ...(current.voteButtons || {}),
          [roleId]: {
            ...(current.voteButtons?.[roleId] || {}),
            x: clampStageValue(base.x + (delta.x || 0), 0, stageMetrics.width),
            y: clampStageValue(base.y + (delta.y || 0), 0, stageMetrics.height),
            rotate: clampStageValue((base.rotate || 0) + (delta.rotate || 0), -180, 180),
            scale: clampDecimal((base.scale || 1) + (delta.scale || 0), 0.42, 1.6, 2)
          }
        };
        return next;
      }

      const ambientTarget = parseAmbientDecorTarget(selectedTarget);
      if (ambientTarget) {
        const base = layoutPlacements.ambientDecor?.[ambientTarget.roleId]?.[ambientTarget.decorType];
        if (!base) {
          return next;
        }

        const currentDecor = current.ambientDecor?.[ambientTarget.roleId]?.[ambientTarget.decorType] || {};
        next.ambientDecor = {
          ...(current.ambientDecor || {}),
          [ambientTarget.roleId]: {
            ...(current.ambientDecor?.[ambientTarget.roleId] || {}),
            [ambientTarget.decorType]: {
              ...currentDecor,
              x: clampStageValue(base.x + (delta.x || 0), 0, stageMetrics.width),
              y: clampStageValue(base.y + (delta.y || 0), 0, stageMetrics.height),
              ...(['phone', 'bubble', 'zzz'].includes(ambientTarget.decorType)
                ? { rotate: clampStageValue((base.rotate || 0) + (delta.rotate || 0), -90, 90) }
                : {}),
              ...(ambientTarget.decorType === 'bubble'
                ? {
                    scale: clampDecimal((base.scale || 1) + (delta.scale || 0), 0.5, 1.8, 2),
                    ...(typeof delta.mirrorX === 'boolean' ? { mirrorX: delta.mirrorX } : {})
                  }
                : {})
            }
          }
        };
        return next;
      }

      const base = layoutPlacements.nameplates[selectedTarget] || nameplatePlacements[selectedTarget] || nameplatePlacements.host;
      next.nameplates = {
        ...(current.nameplates || {}),
        [selectedTarget]: {
          ...(current.nameplates?.[selectedTarget] || {}),
          x: clampStageValue(base.x + (delta.x || 0), 0, stageMetrics.width),
          y: clampStageValue(base.y + (delta.y || 0), 0, stageMetrics.height),
          rotate: clampStageValue((base.rotate || 0) + (delta.rotate || 0), -45, 45)
        }
      };
      return next;
    });
    setCopyState('有未固化精修调整');
  };

  const layoutCalibration = useMemo(
    () => ({
      enabled: calibrationEnabled,
      selectedTarget,
      onSelectTarget: setSelectedTarget,
      onMoveNameplate: moveNameplate,
      onMoveVoteButton: moveVoteButton,
      onMoveVoteArmPoint: moveVoteArmPoint,
      onMoveSeat: moveSeat,
      onMoveScreen: moveScreen,
      onMoveAmbientDecor: moveAmbientDecor
    }),
    [calibrationEnabled, selectedTarget, layoutPlacements]
  );

  const resetCurrentTarget = () => {
    setLayoutOverrides((current) => {
      const next = {
        ...current,
        seats: { ...(current.seats || {}) },
        nameplates: { ...(current.nameplates || {}) },
        voteButtons: { ...(current.voteButtons || {}) },
        voteArms: { ...(current.voteArms || {}) },
        ambientDecor: { ...(current.ambientDecor || {}) }
      };
      const armTarget = parseVoteArmTarget(selectedTarget);
      const ambientTarget = parseAmbientDecorTarget(selectedTarget);

      if (selectedTarget === 'screen') {
        delete next.screen;
      } else if (selectedTarget.startsWith('seat:')) {
        delete next.seats[selectedTarget.replace(/^seat:/, '')];
      } else if (armTarget) {
        const currentArm = { ...(next.voteArms[armTarget.roleId] || {}) };
        if (armTarget.pointType === 'shoulder') {
          delete currentArm.shoulderOffsetX;
          delete currentArm.shoulderOffsetY;
        } else if (armTarget.pointType === 'rest') {
          delete currentArm.restOffsetX;
          delete currentArm.restOffsetY;
        } else if (armTarget.pointType === 'target') {
          delete currentArm.targetX;
          delete currentArm.targetY;
        } else if (armTarget.pointType === 'length') {
          delete currentArm.length;
        }

        if (Object.keys(currentArm).length === 0) {
          delete next.voteArms[armTarget.roleId];
        } else {
          next.voteArms[armTarget.roleId] = currentArm;
        }
      } else if (selectedTarget.startsWith('vote:')) {
        delete next.voteButtons[selectedTarget.replace(/^vote:/, '')];
      } else if (ambientTarget) {
        const currentDecorByRole = { ...(next.ambientDecor[ambientTarget.roleId] || {}) };
        delete currentDecorByRole[ambientTarget.decorType];
        if (Object.keys(currentDecorByRole).length === 0) {
          delete next.ambientDecor[ambientTarget.roleId];
        } else {
          next.ambientDecor[ambientTarget.roleId] = currentDecorByRole;
        }
      } else {
        delete next.nameplates[selectedTarget];
      }

      if (Object.keys(next.seats).length === 0) {
        delete next.seats;
      }
      if (Object.keys(next.nameplates).length === 0) {
        delete next.nameplates;
      }
      if (Object.keys(next.voteButtons).length === 0) {
        delete next.voteButtons;
      }
      if (Object.keys(next.voteArms).length === 0) {
        delete next.voteArms;
      }
      if (Object.keys(next.ambientDecor).length === 0) {
        delete next.ambientDecor;
      }

      return next;
    });
    setCopyState('已重置当前布局项');
  };

  const resetAllOverrides = () => {
    setLayoutOverrides({});
    setCopyState('已清空全部布局调整');
  };

  const copyOverrides = async () => {
    const payloadObject = {
      screen: layoutPlacements.screen,
      seats: layoutPlacements.seats,
      nameplates: layoutPlacements.nameplates,
      voteButtons: layoutPlacements.voteButtons,
      voteArms: layoutPlacements.voteArms,
      ambientDecor: layoutPlacements.ambientDecor
    };
    const payload = JSON.stringify(payloadObject, null, 2);
    window.__agencyLayoutPlacements = payloadObject;
    window.__agencySeatPlacements = payloadObject.seats;
    window.__agencyNameplatePlacements = payloadObject.nameplates;
    window.__agencyVoteButtonPlacements = payloadObject.voteButtons;
    window.__agencyVoteArmPlacements = payloadObject.voteArms;
    window.__agencyAmbientDecorPlacements = payloadObject.ambientDecor;
    window.__agencyMeetingScreenPlacement = payloadObject.screen;

    try {
      await navigator.clipboard.writeText(payload);
      setCopyState('JSON 已复制，也写入 window.__agencyLayoutPlacements');
    } catch {
      setCopyState('浏览器拒绝复制，已写入 window.__agencyLayoutPlacements');
    }
  };

  const replayMeeting = (meeting) => {
    setActiveMeeting({
      ...meeting,
      turns: getMeetingTurns(meeting),
      roleMeta: getMeetingRoleMeta(meeting)
    });
    setHistoryOpen(false);
    setPlaybackKey((value) => value + 1);
  };

  return (
    <main className="app-shell" data-stage-only={stageOnly ? 'true' : 'false'} data-motion={motionEnabled ? 'true' : 'false'}>
      {!stageOnly && (
        <header className="topbar">
          <div className="brand">
            <span className="brand-mark" aria-hidden="true">
              会
            </span>
            <div>
              <p className="eyebrow">Meeting Room</p>
              <h1>会议室</h1>
            </div>
          </div>
          <div className="status-strip" aria-label="meeting status">
            <span>{playback.finished ? '已结束' : playback.turn.phase}</span>
            <span>{progressText}</span>
            <button type="button" onClick={playback.togglePaused} disabled={playback.finished}>
              {playback.finished ? '结束' : playback.paused ? '继续' : '暂停'}
            </button>
            <div className="playback-nav" aria-label="会议播放导航">
              <button type="button" onClick={playback.previous} disabled={playback.currentIndex <= 0}>
                上一条
              </button>
              <button type="button" onClick={playback.next}>
                下一条
              </button>
            </div>
            <button type="button" data-active={settingsOpen ? 'true' : 'false'} onClick={() => setSettingsOpen((value) => !value)}>
              设置
            </button>
            <button type="button" data-active={historyOpen ? 'true' : 'false'} onClick={() => setHistoryOpen(true)}>
              历史会议
            </button>
          </div>
        </header>
      )}

      <section className="workspace">
        <section className="meeting-panel" aria-label="animated expert meeting scene">
          <MeetingStage
            topic={activeMeeting.topic}
            meetingTurns={activeMeetingTurns}
            meetingRoleMeta={activeMeetingRoleMeta}
            meetingParticipants={activeMeetingParticipants}
            thinkingRoleIds={activeMeetingThinking}
            turn={playback.turn}
            currentIndex={playback.currentIndex}
            visibleText={playback.visibleText}
            isTyping={playback.isTyping}
            faceOverrides={faceOverrides}
            layoutPlacements={layoutPlacements}
            layoutCalibration={layoutCalibration}
            deliberation={activeMeetingDeliberation}
            voteRound={activeVoteRound}
            voteCounts={activeVoteCounts}
            voteSides={activeVoteSides}
            pendingVoteSides={pendingVoteSides}
            voteAnimations={activeVoteAnimations}
            showVoteButtons={showVoteButtons}
            motionEnabled={motionEnabled}
            ambientDebugEnabled={settingsOpen}
          />
          <MeetingTransitionOverlay transition={transition} />
          {!stageOnly && (
            <>
              <MeetingTranscript
                currentIndex={playback.currentIndex}
                meetingTurns={activeMeetingTurns}
                meetingRoleMeta={activeMeetingRoleMeta}
              />
              <MeetingSummaryFooter
                meetingSummary={activeMeeting.summary}
                meetingTurns={activeMeetingTurns}
                currentIndex={playback.currentIndex}
              />
              <LayoutCalibrationPanel
                enabled={settingsOpen}
                calibrationEnabled={calibrationEnabled}
                seatPlan={calibrationSeatPlan}
                selectedTarget={selectedTarget}
                selectedPlacement={selectedPlacement}
                votePreviewSide={votePreviewSide}
                copyState={copyState}
                onToggle={() => setSettingsOpen(false)}
                onToggleCalibration={() => setCalibrationEnabled((value) => !value)}
                onSelectTarget={setSelectedTarget}
                onSetVotePreviewSide={setVotePreviewSide}
                onNudgeSelectedTarget={nudgeSelectedTarget}
                onCopy={copyOverrides}
                onResetCurrent={resetCurrentTarget}
                onResetAll={resetAllOverrides}
              />
              <MeetingHistoryDrawer
                open={historyOpen}
                meetings={meetingHistory}
                activeMeetingId={activeMeeting.id}
                onReplay={replayMeeting}
                onClose={() => setHistoryOpen(false)}
              />
            </>
          )}
        </section>
      </section>
    </main>
  );
}
