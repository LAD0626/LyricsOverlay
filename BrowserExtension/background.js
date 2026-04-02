const BRIDGE = {
  nativeHostName: "com.lad0626.lyricsoverlay.bridge",
  reconnectDelayMs: 2000,
  messageType: "playback_update"
};

let nativePort = null;
let reconnectTimer = null;

function connectNativeHost() {
  if (nativePort) {
    return nativePort;
  }

  try {
    nativePort = chrome.runtime.connectNative(BRIDGE.nativeHostName);
    nativePort.onDisconnect.addListener(handleDisconnect);
  } catch (error) {
    console.warn("[LyricsOverlay] Failed to connect native host.", error);
    scheduleReconnect();
  }

  return nativePort;
}

function handleDisconnect() {
  const runtimeError = chrome.runtime.lastError;
  if (runtimeError) {
    console.warn("[LyricsOverlay] Native host disconnected.", runtimeError.message);
  }

  nativePort = null;
  scheduleReconnect();
}

function scheduleReconnect() {
  if (reconnectTimer) {
    return;
  }

  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectNativeHost();
  }, BRIDGE.reconnectDelayMs);
}

function forwardPlaybackUpdate(payload) {
  if (!payload || payload.type !== BRIDGE.messageType) {
    return;
  }

  const port = connectNativeHost();
  if (!port) {
    return;
  }

  try {
    port.postMessage(payload);
  } catch (error) {
    console.warn("[LyricsOverlay] Failed to send payload to native host.", error);
    nativePort = null;
    scheduleReconnect();
  }
}

chrome.runtime.onInstalled.addListener(() => {
  connectNativeHost();
});

chrome.runtime.onStartup?.addListener(() => {
  connectNativeHost();
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === BRIDGE.messageType) {
    forwardPlaybackUpdate(message);
    sendResponse({ ok: true });
    return true;
  }

  sendResponse({ ok: false });
  return false;
});
