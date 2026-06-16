const assetRoot = `${import.meta.env.BASE_URL}imagegen/extracted`;

const cowSeatRoot = `${assetRoot}/occupied-seats-silhouette`;
const cowHeadRoot = `${assetRoot}/occupied-seat-heads-silhouette`;

const SEAT_TABLE_APPROACH_X = 22;

export const occupiedSeats = {
  standard: {
    left: `${cowSeatRoot}/cow-seat-standard-left-v1.0.0.png`,
    front: `${cowSeatRoot}/cow-seat-standard-front-v1.0.0.png`,
    right: `${cowSeatRoot}/cow-seat-standard-right-v1.0.0.png`
  },
  round: {
    left: `${cowSeatRoot}/cow-seat-round-left-v1.0.0.png`,
    front: `${cowSeatRoot}/cow-seat-round-front-v1.0.0.png`,
    right: `${cowSeatRoot}/cow-seat-round-right-v1.0.0.png`
  },
  tall: {
    left: `${cowSeatRoot}/cow-seat-tall-left-v1.0.0.png`,
    front: `${cowSeatRoot}/cow-seat-tall-front-v1.0.0.png`,
    right: `${cowSeatRoot}/cow-seat-tall-right-v1.0.0.png`
  },
  small: {
    left: `${cowSeatRoot}/cow-seat-small-left-v1.0.0.png`,
    front: `${cowSeatRoot}/cow-seat-small-front-v1.0.0.png`,
    right: `${cowSeatRoot}/cow-seat-small-right-v1.0.0.png`
  },
  sturdy: {
    left: `${cowSeatRoot}/cow-seat-sturdy-left-v1.0.0.png`,
    front: `${cowSeatRoot}/cow-seat-sturdy-front-v1.0.0.png`,
    right: `${cowSeatRoot}/cow-seat-sturdy-right-v1.0.0.png`
  }
};

export const emptySeats = {
  front: `${assetRoot}/empty-seats/chair-front-v1.0.0.png`,
  left: `${assetRoot}/empty-seats/chair-left-v1.0.0.png`,
  right: `${assetRoot}/empty-seats/chair-right-v1.0.0.png`
};

export const tableAsset = `${assetRoot}/tables/table-long-vertical-v1.0.0.png`;

export const bodyLayoutProfiles = {
  standard: { sideOutset: 3 },
  round: { sideOutset: 7 },
  tall: { sideOutset: 4 },
  small: { sideOutset: 1 },
  sturdy: { sideOutset: 6 }
};

export const stageMetrics = {
  width: 1120,
  height: 820,
  seatWidth: 126,
  hostWidth: 118,
  tableWidth: 255
};

export const meetingSeats = [
  { slotId: 'host', roleId: 'host', body: 'standard', direction: 'front', label: '\u4e3b\u6301\u4eba', role: 'host', x: 560, y: 92, scale: 0.66, z: 24 },
  { slotId: 'left1', roleId: 'product-manager', body: 'round', direction: 'left', label: '\u4ea7\u54c1\u7ecf\u7406', role: 'left', x: 402, y: 190, scale: 0.66, z: 14 },
  { slotId: 'right1', roleId: 'engineering-ai-engineer', body: 'tall', direction: 'right', label: 'AI\u5de5\u7a0b\u5e08', role: 'right', x: 718, y: 190, scale: 0.66, z: 14 },
  { slotId: 'left2', roleId: 'engineering-backend-architect', body: 'small', direction: 'left', label: '\u540e\u7aef\u67b6\u6784\u5e08', role: 'left', x: 396, y: 305, scale: 0.71, z: 16 },
  { slotId: 'right2', roleId: 'specialized-workflow-architect', body: 'sturdy', direction: 'right', label: '\u5de5\u4f5c\u6d41\u67b6\u6784\u5e08', role: 'right', x: 724, y: 305, scale: 0.71, z: 16 },
  { slotId: 'left3', roleId: 'engineering-security-engineer', body: 'standard', direction: 'left', label: '\u5b89\u5168\u5de5\u7a0b\u5e08', role: 'left', x: 391, y: 420, scale: 0.76, z: 18 },
  { slotId: 'right3', roleId: 'testing-api-tester', body: 'round', direction: 'right', label: 'API\u6d4b\u8bd5\u5de5\u7a0b\u5e08', role: 'right', x: 729, y: 420, scale: 0.76, z: 18 },
  { slotId: 'left4', roleId: 'engineering-technical-writer', body: 'tall', direction: 'left', label: '\u6280\u672f\u6587\u6863\u5de5\u7a0b\u5e08', role: 'left', x: 386, y: 535, scale: 0.81, z: 20 },
  { slotId: 'right4', empty: true, body: 'small', direction: 'right', label: '', role: 'right', x: 734, y: 535, scale: 0.81, z: 20 },
  { slotId: 'left5', empty: true, body: 'sturdy', direction: 'left', label: '', role: 'left', x: 381, y: 650, scale: 0.86, z: 22 },
  { slotId: 'right5', empty: true, body: 'standard', direction: 'right', label: '', role: 'right', x: 739, y: 650, scale: 0.86, z: 22 }
];

export function getSeatHeadAsset(body, direction) {
  return `${cowHeadRoot}/cow-seat-${body}-${direction}-head-v1.0.0.png`;
}

export function getSeatPlacement(seat) {
  const profile = bodyLayoutProfiles[seat.body] || { sideOutset: 0 };
  const directionSign = seat.role === 'left' ? -1 : seat.role === 'right' ? 1 : 0;

  return {
    ...seat,
    x: seat.x + directionSign * profile.sideOutset - directionSign * SEAT_TABLE_APPROACH_X
  };
}

export function getAssetCards() {
  const cards = [
    { title: '\u957f\u684c', type: 'table', src: tableAsset },
    { title: '\u7a7a\u5ea7\u4f4d front', type: 'empty seat', src: emptySeats.front },
    { title: '\u7a7a\u5ea7\u4f4d left', type: 'empty seat', src: emptySeats.left },
    { title: '\u7a7a\u5ea7\u4f4d right', type: 'empty seat', src: emptySeats.right }
  ];

  Object.entries(occupiedSeats).forEach(([body, directions]) => {
    Object.entries(directions).forEach(([direction, src]) => {
      cards.push({ title: `${body} ${direction}`, type: 'occupied seat', src });
    });
  });

  return cards;
}

