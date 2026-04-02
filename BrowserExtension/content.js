const BRIDGE = {
  messageType: "playback_update",
  pollIntervalMs: 1000
};

const SELECTORS = {
  title: [
    "ytmusic-player-bar .title",
    "ytmusic-player-bar .title.ytmusic-player-bar",
    "ytmusic-player-bar yt-formatted-string.title"
  ],
  artist: [
    "ytmusic-player-bar .byline",
    "ytmusic-player-bar .byline.ytmusic-player-bar",
    "ytmusic-player-bar yt-formatted-string.byline"
  ],
  currentTime: [
    "ytmusic-player-bar .time-info .current-time",
    "ytmusic-player-bar .time-info"
  ],
  duration: [
    "ytmusic-player-bar .time-info .duration",
    "ytmusic-player-bar .time-info"
  ],
  playPauseButton: [
    "ytmusic-player-bar tp-yt-paper-icon-button.play-pause-button",
    "ytmusic-player-bar #play-pause-button"
  ],
  playerBarRoot: [
    "ytmusic-player-bar",
    "ytmusic-app-layout",
    "body"
  ]
};

let lastPayloadSignature = null;

function firstMatch(selectors) {
  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      return element;
    }
  }

  return null;
}

function textContent(selectors) {
  const element = firstMatch(selectors);
  return element?.textContent?.trim() ?? "";
}

function parseClockValue(text) {
  const normalized = text.trim();
  if (!normalized) {
    return null;
  }

  const parts = normalized.split(":").map((part) => Number.parseInt(part, 10));
  if (parts.some((part) => Number.isNaN(part))) {
    return null;
  }

  if (parts.length === 2) {
    return parts[0] * 60 + parts[1];
  }

  if (parts.length === 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }

  return null;
}

function parseTimeInfoFallback() {
  const timeInfo = textContent(["ytmusic-player-bar .time-info"]);
  if (!timeInfo.includes("/")) {
    return { currentTime: null, duration: null };
  }

  const [current, duration] = timeInfo.split("/").map((part) => parseClockValue(part));
  return { currentTime: current, duration };
}

function extractCurrentTime() {
  const directValue = parseClockValue(textContent(["ytmusic-player-bar .time-info .current-time"]));
  if (directValue !== null) {
    return directValue;
  }

  const fallback = parseTimeInfoFallback();
  if (fallback.currentTime !== null) {
    return fallback.currentTime;
  }

  const video = document.querySelector("video");
  return Number.isFinite(video?.currentTime) ? video.currentTime : null;
}

function extractDuration() {
  const directValue = parseClockValue(textContent(["ytmusic-player-bar .time-info .duration"]));
  if (directValue !== null) {
    return directValue;
  }

  const fallback = parseTimeInfoFallback();
  if (fallback.duration !== null) {
    return fallback.duration;
  }

  const video = document.querySelector("video");
  return Number.isFinite(video?.duration) ? video.duration : null;
}

function extractArtist() {
  const rawArtist = textContent(SELECTORS.artist);
  if (!rawArtist) {
    return "";
  }

  return rawArtist
    .split("•")[0]
    .split("·")[0]
    .trim();
}

function extractIsPlaying() {
  const button = firstMatch(SELECTORS.playPauseButton);
  const label = (
    button?.getAttribute("aria-label") ||
    button?.getAttribute("title") ||
    ""
  ).toLowerCase();

  if (label.includes("pause")) {
    return true;
  }

  if (label.includes("play")) {
    return false;
  }

  const video = document.querySelector("video");
  if (video) {
    return !video.paused;
  }

  return false;
}

function buildPayload() {
  const title = textContent(SELECTORS.title);
  const artist = extractArtist();
  const currentTime = extractCurrentTime();
  const duration = extractDuration();

  if (!title || !artist) {
    return null;
  }

  if (!Number.isFinite(currentTime) || !Number.isFinite(duration)) {
    return null;
  }

  return {
    type: BRIDGE.messageType,
    title,
    artist,
    currentTime: Math.max(0, currentTime),
    duration: Math.max(0, duration),
    isPlaying: extractIsPlaying()
  };
}

function signatureForPayload(payload) {
  const roundedCurrentTime = Math.round(payload.currentTime * 10) / 10;
  return JSON.stringify({
    type: payload.type,
    title: payload.title,
    artist: payload.artist,
    currentTime: roundedCurrentTime,
    duration: payload.duration,
    isPlaying: payload.isPlaying
  });
}

function emitPlaybackUpdate() {
  const payload = buildPayload();
  if (!payload) {
    return;
  }

  const signature = signatureForPayload(payload);
  if (signature === lastPayloadSignature) {
    return;
  }

  lastPayloadSignature = signature;
  chrome.runtime.sendMessage(payload).catch((error) => {
    console.warn("[LyricsOverlay] Failed to send playback update.", error);
  });
}

function attachObserver() {
  const root = firstMatch(SELECTORS.playerBarRoot);
  if (!root) {
    return;
  }

  const observer = new MutationObserver(() => {
    emitPlaybackUpdate();
  });

  observer.observe(root, {
    childList: true,
    subtree: true,
    attributes: true,
    characterData: true
  });
}

attachObserver();
setInterval(emitPlaybackUpdate, BRIDGE.pollIntervalMs);
emitPlaybackUpdate();
