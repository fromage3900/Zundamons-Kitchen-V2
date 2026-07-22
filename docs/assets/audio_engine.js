/**
 * ZundaAudio — Web Audio API Sound Synthesizer & Audio Engine
 * Zundamon's Kitchen V2 (Zunda-OS 95 CLI Launch Page & Creative Hub)
 * Zero external audio file dependencies. Procedural synthesis using native AudioContext.
 */

const ZundaAudio = {
  ctx: null,
  masterGain: null,
  bgmGain: null,
  sfxGain: null,
  isMuted: false,
  volume: 0.7,
  bgmPlaying: false,
  bgmInterval: null,
  bgmPadOscs: null,
  bgmPadGain: null,
  bgmStopTimeout: null,

  init() {
    if (this.ctx) return;
    const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtxClass) return;

    this.ctx = new AudioCtxClass();

    // Load persisted state
    const savedVol = localStorage.getItem('zunda_os_volume');
    if (savedVol !== null) {
      const parsed = parseFloat(savedVol);
      if (!isNaN(parsed)) {
        this.volume = Math.max(0, Math.min(1, parsed));
      }
    }

    const savedMute = localStorage.getItem('zunda_os_muted');
    if (savedMute !== null) {
      this.setMute(savedMute === 'true');
    }

    // Master Gain Node
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.volume, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    // SFX Bus Gain
    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.setValueAtTime(0.8, this.ctx.currentTime);
    this.sfxGain.connect(this.masterGain);

    // BGM Bus Gain
    this.bgmGain = this.ctx.createGain();
    this.bgmGain.gain.setValueAtTime(0.4, this.ctx.currentTime);
    this.bgmGain.connect(this.masterGain);
  },

  resumeOnUserGesture() {
    if (!this.ctx) this.init();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  },

  setMute(muteState) {
    this.isMuted = muteState;
    localStorage.setItem('zunda_os_muted', muteState ? 'true' : 'false');
    if (this.masterGain && this.ctx) {
      const now = this.ctx.currentTime;
      this.masterGain.gain.cancelScheduledValues(now);
      this.masterGain.gain.setTargetAtTime(this.isMuted ? 0 : this.volume, now, 0.02);
    }
  },

  toggleMute() {
    this.setMute(!this.isMuted);
    return this.isMuted;
  },

  setVolume(val) {
    this.volume = Math.max(0, Math.min(1, val));
    localStorage.setItem('zunda_os_volume', this.volume.toString());
    if (this.masterGain && this.ctx && !this.isMuted) {
      this.masterGain.gain.setValueAtTime(this.volume, this.ctx.currentTime);
    }
  }
};

/**
 * Synthesizes a mechanical UI click sound effect.
 * @param {'down' | 'up' | 'start'} variant - Click action type
 */
function playClickSFX(variant = 'down') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  osc.type = variant === 'start' ? 'triangle' : 'square';

  let duration = 0.03;
  if (variant === 'down') {
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(150, now + 0.025);
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);
    duration = 0.03;
  } else if (variant === 'up') {
    osc.frequency.setValueAtTime(300, now);
    osc.frequency.exponentialRampToValueAtTime(800, now + 0.020);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.020);
    duration = 0.03;
  } else if (variant === 'start') {
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.setValueAtTime(659.25, now + 0.03); // E5
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    duration = 0.085;
  } else {
    // Fallback gain ramp down (0.15 -> 0.001 over 0.03s) for invalid/unknown variants
    osc.frequency.setValueAtTime(440, now);
    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
    duration = 0.035;
  }

  osc.connect(gain);
  gain.connect(ZundaAudio.sfxGain);

  osc.start(now);
  osc.stop(now + duration);
}

/**
 * Synthesizes window manipulation sound effects.
 * @param {'focus' | 'drag' | 'minimize' | 'maximize' | 'close'} action 
 */
function playWindowSFX(action = 'focus') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  if (action === 'focus') {
    const notes = [659.25, 987.77];
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.04);
      gain.gain.setValueAtTime(0.18, now + idx * 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.04 + 0.09);
      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.04);
      osc.stop(now + idx * 0.04 + 0.1);
    });
  } else if (action === 'drag') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(440, now);
    osc.frequency.exponentialRampToValueAtTime(110, now + 0.015);
    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.015);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.02);
  } else if (action === 'minimize') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(987.77, now);
    osc.frequency.exponentialRampToValueAtTime(659.25, now + 0.07);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.085);
  } else if (action === 'maximize') {
    [659.25, 830.61, 987.77].forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.035);
      gain.gain.setValueAtTime(0.18, now + idx * 0.035);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.035 + 0.07);
      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.035);
      osc.stop(now + idx * 0.035 + 0.075);
    });
  } else if (action === 'close') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(350, now);
    osc.frequency.exponentialRampToValueAtTime(80, now + 0.04);
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.045);
  }
}

/**
 * Synthesizes CRT terminal keyboard typing clicks & blips.
 * @param {string} key - Character key pressed
 */
function playKeySFX(key = '') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  if (key === 'Enter') {
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.exponentialRampToValueAtTime(261.63, now + 0.04);
    gain.gain.setValueAtTime(0.22, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.045);
    return;
  }

  const baseFreq = 1200 + (Math.random() * 200 - 100);
  osc.type = 'square';
  osc.frequency.setValueAtTime(baseFreq, now);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.3, now + 0.012);

  gain.gain.setValueAtTime(0.08, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.012);

  osc.connect(gain);
  gain.connect(ZundaAudio.sfxGain);

  osc.start(now);
  osc.stop(now + 0.015);
}

/**
 * Starts or toggles the ambient cozy background music synthesizer.
 */
function toggleCozyBGM() {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx) ZundaAudio.init();
  if (!ZundaAudio.ctx) return false;

  if (ZundaAudio.bgmPlaying) {
    stopCozyBGM();
    return false;
  } else {
    startCozyBGM();
    return true;
  }
}

function startCozyBGM() {
  if (ZundaAudio.bgmPlaying || !ZundaAudio.ctx) return;

  if (ZundaAudio.bgmStopTimeout) {
    clearTimeout(ZundaAudio.bgmStopTimeout);
    ZundaAudio.bgmStopTimeout = null;
  }

  if (ZundaAudio.bgmPadOscs) {
    ZundaAudio.bgmPadOscs.forEach(osc => {
      try { osc.stop(); } catch (e) {}
      try { osc.disconnect(); } catch (e) {}
    });
    ZundaAudio.bgmPadOscs = null;
  }

  ZundaAudio.bgmPlaying = true;

  const ctx = ZundaAudio.ctx;

  // E Major Pentatonic Scale frequencies (Hz)
  const scale = [329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99];

  // Soft Low Drone Pad (E3 + B3)
  const padOsc1 = ctx.createOscillator();
  const padOsc2 = ctx.createOscillator();
  const padGain = ctx.createGain();
  const filter = ctx.createBiquadFilter();

  padOsc1.type = 'sine';
  padOsc1.frequency.setValueAtTime(164.81, ctx.currentTime); // E3

  padOsc2.type = 'triangle';
  padOsc2.frequency.setValueAtTime(246.94, ctx.currentTime); // B3

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(450, ctx.currentTime);

  padGain.gain.setValueAtTime(0.01, ctx.currentTime);
  padGain.gain.linearRampToValueAtTime(0.12, ctx.currentTime + 2.0);

  padOsc1.connect(filter);
  padOsc2.connect(filter);
  filter.connect(padGain);
  padGain.connect(ZundaAudio.bgmGain);

  padOsc1.start();
  padOsc2.start();

  ZundaAudio.bgmPadOscs = [padOsc1, padOsc2];
  ZundaAudio.bgmPadGain = padGain;

  // Arpeggiated Melody Sequence Generator
  let step = 0;
  ZundaAudio.bgmInterval = setInterval(() => {
    if (!ZundaAudio.bgmPlaying || ZundaAudio.isMuted) return;

    const now = ctx.currentTime;
    const freq = scale[Math.floor(Math.random() * scale.length)];

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, now);

    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.0005, now + 0.6);

    osc.connect(gain);
    gain.connect(ZundaAudio.bgmGain);

    osc.start(now);
    osc.stop(now + 0.65);

    step++;
  }, 650);
}

function stopCozyBGM() {
  if (!ZundaAudio.bgmPlaying) return;
  ZundaAudio.bgmPlaying = false;

  if (ZundaAudio.bgmStopTimeout) {
    clearTimeout(ZundaAudio.bgmStopTimeout);
    ZundaAudio.bgmStopTimeout = null;
  }

  if (ZundaAudio.bgmInterval) {
    clearInterval(ZundaAudio.bgmInterval);
    ZundaAudio.bgmInterval = null;
  }

  if (ZundaAudio.bgmPadGain && ZundaAudio.ctx) {
    const now = ZundaAudio.ctx.currentTime;
    ZundaAudio.bgmPadGain.gain.linearRampToValueAtTime(0.001, now + 1.0);
    ZundaAudio.bgmStopTimeout = setTimeout(() => {
      if (ZundaAudio.bgmPadOscs) {
        ZundaAudio.bgmPadOscs.forEach(osc => {
          try { osc.stop(); } catch(e){}
        });
        ZundaAudio.bgmPadOscs = null;
      }
      ZundaAudio.bgmStopTimeout = null;
    }, 1050);
  }
}

// Global window attachment for convenience
window.ZundaAudio = ZundaAudio;
window.playClickSFX = playClickSFX;
window.playWindowSFX = playWindowSFX;
window.playKeySFX = playKeySFX;
window.toggleCozyBGM = toggleCozyBGM;
