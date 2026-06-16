const assetRoot = "./art/imagegen/extracted";

const occupiedSeats = {
  standard: {
    left: `${assetRoot}/occupied-seats/cow-seat-standard-left-v1.0.0.png`,
    front: `${assetRoot}/occupied-seats/cow-seat-standard-front-v1.0.0.png`,
    right: `${assetRoot}/occupied-seats/cow-seat-standard-right-v1.0.0.png`
  },
  round: {
    left: `${assetRoot}/occupied-seats/cow-seat-round-left-v1.0.0.png`,
    front: `${assetRoot}/occupied-seats/cow-seat-round-front-v1.0.0.png`,
    right: `${assetRoot}/occupied-seats/cow-seat-round-right-v1.0.0.png`
  },
  tall: {
    left: `${assetRoot}/occupied-seats/cow-seat-tall-left-v1.0.0.png`,
    front: `${assetRoot}/occupied-seats/cow-seat-tall-front-v1.0.0.png`,
    right: `${assetRoot}/occupied-seats/cow-seat-tall-right-v1.0.0.png`
  },
  small: {
    left: `${assetRoot}/occupied-seats/cow-seat-small-left-v1.0.0.png`,
    front: `${assetRoot}/occupied-seats/cow-seat-small-front-v1.0.0.png`,
    right: `${assetRoot}/occupied-seats/cow-seat-small-right-v1.0.0.png`
  },
  sturdy: {
    left: `${assetRoot}/occupied-seats/cow-seat-sturdy-left-v1.0.0.png`,
    front: `${assetRoot}/occupied-seats/cow-seat-sturdy-front-v1.0.0.png`,
    right: `${assetRoot}/occupied-seats/cow-seat-sturdy-right-v1.0.0.png`
  }
};

const emptySeats = {
  front: `${assetRoot}/empty-seats/chair-front-v1.0.0.png`,
  left: `${assetRoot}/empty-seats/chair-left-v1.0.0.png`,
  right: `${assetRoot}/empty-seats/chair-right-v1.0.0.png`
};

const tableAsset = `${assetRoot}/tables/table-long-vertical-v1.0.0.png`;

const bodyLayoutProfiles = {
  standard: { sideOutset: 3 },
  round: { sideOutset: 7 },
  tall: { sideOutset: 4 },
  small: { sideOutset: 1 },
  sturdy: { sideOutset: 6 }
};

const stageMetrics = {
  width: 1120,
  height: 820,
  seatWidth: 126,
  hostWidth: 118,
  tableWidth: 255
};

const meetingSeats = [
  { body: "standard", direction: "front", label: "\u4e3b\u6301\u4eba", role: "host", x: 560, y: 92, scale: 0.66, z: 24 },
  { body: "round", direction: "left", label: "\u4ea7\u54c1", role: "left", x: 402, y: 190, scale: 0.66, z: 14 },
  { body: "small", direction: "left", label: "\u52a8\u6548", role: "left", x: 396, y: 305, scale: 0.71, z: 16 },
  { body: "standard", direction: "left", label: "\u67b6\u6784", role: "left", x: 391, y: 420, scale: 0.76, z: 18 },
  { body: "tall", direction: "left", label: "\u6027\u80fd", role: "left", x: 386, y: 535, scale: 0.81, z: 20 },
  { body: "sturdy", direction: "left", label: "\u5b89\u5168", role: "left", x: 381, y: 650, scale: 0.86, z: 22 },
  { body: "tall", direction: "right", label: "\u7f8e\u672f", role: "right", x: 718, y: 190, scale: 0.66, z: 14 },
  { body: "sturdy", direction: "right", label: "\u524d\u7aef", role: "right", x: 724, y: 305, scale: 0.71, z: 16 },
  { body: "round", direction: "right", label: "UX", role: "right", x: 729, y: 420, scale: 0.76, z: 18 },
  { body: "small", direction: "right", label: "QA", role: "right", x: 734, y: 535, scale: 0.81, z: 20 },
  { body: "standard", direction: "right", label: "\u4ea4\u4ed8", role: "right", x: 739, y: 650, scale: 0.86, z: 22 }
];

function createImage(className, src, alt) {
  const image = document.createElement("img");
  image.className = className;
  image.src = src;
  image.alt = alt;
  image.loading = "eager";
  return image;
}

function getSeatHeadAsset(body, direction) {
  return `${assetRoot}/occupied-seat-heads/cow-seat-${body}-${direction}-head-v1.0.0.png`;
}

function getSeatPlacement(seat) {
  const profile = bodyLayoutProfiles[seat.body] || { sideOutset: 0 };
  const directionSign = seat.role === "left" ? -1 : seat.role === "right" ? 1 : 0;

  return {
    ...seat,
    x: seat.x + directionSign * profile.sideOutset
  };
}

function updateStageScale(stage) {
  const rect = stage.getBoundingClientRect();
  const scale = Math.min(rect.width / stageMetrics.width, rect.height / stageMetrics.height);
  stage.style.setProperty("--stage-scale", String(scale));
}

function renderMeetingStage() {
  const stage = document.getElementById("meetingStage");
  if (!stage) {
    return;
  }

  stage.replaceChildren();

  const canvas = document.createElement("div");
  canvas.className = "stage-canvas";
  stage.appendChild(canvas);
  updateStageScale(stage);

  if ("ResizeObserver" in window) {
    const resizeObserver = new ResizeObserver(() => updateStageScale(stage));
    resizeObserver.observe(stage);
  } else {
    window.addEventListener("resize", () => updateStageScale(stage));
  }

  const table = createImage("stage-table", tableAsset, "\u767d\u8272\u7ad6\u5411\u957f\u4f1a\u8bae\u684c");
  table.style.left = "560px";
  table.style.top = "430px";
  table.style.width = `${stageMetrics.tableWidth}px`;
  canvas.appendChild(table);

  meetingSeats.forEach((seat) => {
    const placement = getSeatPlacement(seat);
    const image = createImage("stage-seat", occupiedSeats[seat.body][seat.direction], `${seat.label} \u6709\u4eba\u5ea7\u4f4d`);
    image.dataset.role = seat.role;
    image.style.left = `${placement.x}px`;
    image.style.top = `${placement.y}px`;
    image.style.width = `${seat.role === "host" ? stageMetrics.hostWidth : stageMetrics.seatWidth}px`;
    image.style.setProperty("--scale", String(seat.scale));
    image.style.setProperty("--z", String(seat.z));
    canvas.appendChild(image);

    const upperLayerSrc = seat.role === "host" ? occupiedSeats[seat.body][seat.direction] : getSeatHeadAsset(seat.body, seat.direction);
    const upperLayerClass = seat.role === "host" ? "stage-seat stage-seat-host-upper" : "stage-seat stage-seat-head";
    const headLayer = createImage(upperLayerClass, upperLayerSrc, `${seat.label} \u725b\u5934\u906e\u6321\u5c42`);
    headLayer.dataset.role = seat.role;
    headLayer.style.left = `${placement.x}px`;
    headLayer.style.top = `${placement.y}px`;
    headLayer.style.width = `${seat.role === "host" ? stageMetrics.hostWidth : stageMetrics.seatWidth}px`;
    headLayer.style.setProperty("--scale", String(seat.scale));
    headLayer.style.setProperty("--z", "52");
    canvas.appendChild(headLayer);

    const label = document.createElement("span");
    label.className = "seat-label";
    label.dataset.role = seat.role;
    label.textContent = seat.label;
    label.style.setProperty("--x", `${placement.x}px`);
    label.style.setProperty("--y", `${placement.y}px`);
    label.style.setProperty("--z", String(seat.z));
    canvas.appendChild(label);
  });
}

function renderAssetTray() {
  const tray = document.getElementById("assetTray");
  if (!tray) {
    return;
  }

  const cards = [
    { title: "\u957f\u684c", type: "table", src: tableAsset },
    { title: "\u7a7a\u5ea7\u4f4d front", type: "empty seat", src: emptySeats.front },
    { title: "\u7a7a\u5ea7\u4f4d left", type: "empty seat", src: emptySeats.left },
    { title: "\u7a7a\u5ea7\u4f4d right", type: "empty seat", src: emptySeats.right }
  ];

  Object.entries(occupiedSeats).forEach(([body, directions]) => {
    Object.entries(directions).forEach(([direction, src]) => {
      cards.push({ title: `${body} ${direction}`, type: "occupied seat", src });
    });
  });

  tray.replaceChildren();
  cards.forEach((card) => {
    const item = document.createElement("article");
    const preview = createImage("", card.src, card.title);
    const copy = document.createElement("div");
    const title = document.createElement("strong");
    const meta = document.createElement("span");

    item.className = "asset-card";
    title.textContent = card.title;
    meta.textContent = card.type;
    copy.append(title, meta);
    item.append(preview, copy);
    tray.appendChild(item);
  });
}

renderMeetingStage();
renderAssetTray();
