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
  rainGain: null,
  isMuted: false,
  volume: 0.7,

  // BGM Jukebox State
  bgmPlaying: false,
  bgmInterval: null,
  bgmPadOscs: null,
  bgmPadGain: null,
  bgmSubOsc: null,
  bgmStopTimeout: null,
  currentTrackIdx: 0,
  bgmTracks: [
    { name: "Zunda Cozy Kitchen", scale: [329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99], padFreqs: [164.81, 246.94], subFreq: 82.41 },
    { name: "Starlight Lullaby", scale: [220.00, 246.94, 277.18, 329.63, 369.99, 440.00], padFreqs: [110.00, 164.81], subFreq: 55.00 },
    { name: "Edamame Afternoon Waltz", scale: [261.63, 293.66, 329.63, 392.00, 440.00, 523.25], padFreqs: [130.81, 196.00], subFreq: 65.41 }
  ],

  // Rain Ambient Noise Synthesizer State
  rainPlaying: false,
  rainNode: null,
  rainVolume: 0.4,

  init() {
    if (this.ctx) return;
    const AudioCtxClass = typeof window !== 'undefined' ? (window.AudioContext || window.webkitAudioContext) : null;
    if (!AudioCtxClass) return;

    this.ctx = new AudioCtxClass();

    // Load persisted state
    if (typeof localStorage !== 'undefined') {
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

    // Rain SFX Bus Gain
    this.rainGain = this.ctx.createGain();
    this.rainGain.gain.setValueAtTime(this.rainVolume * 0.15, this.ctx.currentTime);
    this.rainGain.connect(this.masterGain);

    this.initAutoUnlock();
  },

  initAutoUnlock() {
    if (typeof window === 'undefined') return;
    const events = ['click', 'keydown', 'pointerdown', 'touchstart'];
    
    const unlockHandler = () => {
      if (!this.ctx) {
        this.init();
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume().then(() => {
          events.forEach(evt => window.removeEventListener(evt, unlockHandler, { capture: true }));
        }).catch(() => {});
      } else if (this.ctx && this.ctx.state === 'running') {
        events.forEach(evt => window.removeEventListener(evt, unlockHandler, { capture: true }));
      }
    };

    events.forEach(evt => {
      window.addEventListener(evt, unlockHandler, { capture: true, once: false });
    });
  },

  resumeOnUserGesture() {
    if (!this.ctx) this.init();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  },

  setMute(muteState) {
    this.isMuted = muteState;
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('zunda_os_muted', muteState ? 'true' : 'false');
    }
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
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('zunda_os_volume', this.volume.toString());
    }
    if (this.masterGain && this.ctx && !this.isMuted) {
      this.masterGain.gain.setValueAtTime(this.volume, this.ctx.currentTime);
    }
  },

  // --- Rain SFX Synthesizer Subsystem ---
  createRainNoiseBuffer(durationSec = 2.0) {
    if (!this.ctx) return null;
    const sampleRate = this.ctx.sampleRate;
    const bufferSize = sampleRate * durationSec;
    const buffer = this.ctx.createBuffer(2, bufferSize, sampleRate);

    for (let channel = 0; channel < 2; channel++) {
      const output = buffer.getChannelData(channel);
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        const pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
        b6 = white * 0.115926;
        output[i] = pink * 0.08;
      }
    }
    return buffer;
  },

  startRainSFX() {
    this.resumeOnUserGesture();
    if (!this.ctx) return;
    if (this.rainPlaying) return;

    const noiseBuffer = this.createRainNoiseBuffer(2.0);
    if (!noiseBuffer) return;

    const whiteNoise = this.ctx.createBufferSource();
    whiteNoise.buffer = noiseBuffer;
    whiteNoise.loop = true;

    // Dual lowpass/highpass filter graph
    const highpass = this.ctx.createBiquadFilter();
    highpass.type = 'highpass';
    highpass.frequency.setValueAtTime(150, this.ctx.currentTime);

    const lowpass = this.ctx.createBiquadFilter();
    lowpass.type = 'lowpass';
    lowpass.frequency.setValueAtTime(1100, this.ctx.currentTime);

    whiteNoise.connect(highpass);
    highpass.connect(lowpass);
    lowpass.connect(this.rainGain);

    whiteNoise.start();
    this.rainNode = whiteNoise;
    this.rainPlaying = true;
  },

  stopRainSFX() {
    if (!this.rainPlaying || !this.rainNode) return;
    try {
      this.rainNode.stop();
      this.rainNode.disconnect();
    } catch (e) {}
    this.rainNode = null;
    this.rainPlaying = false;
  },

  toggleRainSFX() {
    if (this.rainPlaying) {
      this.stopRainSFX();
      return false;
    } else {
      this.startRainSFX();
      return true;
    }
  },

  setRainVolume(val) {
    const norm = Math.max(0, Math.min(1, val / 100));
    this.rainVolume = norm;
    if (this.rainGain && this.ctx) {
      this.rainGain.gain.setValueAtTime(norm * 0.15, this.ctx.currentTime);
    }
    if (norm > 0 && !this.rainPlaying) {
      this.startRainSFX();
    } else if (norm === 0 && this.rainPlaying) {
      this.stopRainSFX();
    }
  },

  // --- Next BGM Track Selector ---
  nextBGMTrack() {
    this.currentTrackIdx = (this.currentTrackIdx + 1) % this.bgmTracks.length;
    if (this.bgmPlaying) {
      stopCozyBGM();
      startCozyBGM();
    }
    return this.bgmTracks[this.currentTrackIdx].name;
  },

  // --- Voice Line Synthesizer Delegate ---
  playVoiceLine(type = 'chirp') {
    return playZundaVoiceLine(type);
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
 * Synthesizes Zundamon vocal chirps for interactions, speech bubbles, and minigames.
 * @param {'chirp' | 'nanoda_arpeggio' | 'speech_talk' | 'companion_click' | 'hit_perfect' | 'hit_great' | 'hit_ok' | 'hit_miss'} type
 */
function playZundaVoiceLine(type = 'chirp') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  if (type === 'chirp') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(1200, now + 0.035);

    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.038);
  } else if (type === 'nanoda_arpeggio') {
    const notes = [698.46, 880.00, 1046.50];
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, now + idx * 0.07);

      gain.gain.setValueAtTime(0.18, now + idx * 0.07);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.07 + 0.12);

      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.07);
      osc.stop(now + idx * 0.07 + 0.125);
    });
  } else if (type === 'speech_talk') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const freq = 750 + Math.random() * 400;
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, now);

    gain.gain.setValueAtTime(0.1, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.028);
  } else if (type === 'companion_click') {
    [1046.50, 1567.98].forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = idx === 0 ? 'sine' : 'triangle';
      osc.frequency.setValueAtTime(freq, now + idx * 0.04);

      gain.gain.setValueAtTime(0.16, now + idx * 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.04 + 0.05);

      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.04);
      osc.stop(now + idx * 0.04 + 0.055);
    });
  } else if (type === 'hit_perfect') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(1760, now + 0.1);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.105);
  } else if (type === 'hit_great') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(660, now);

    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.085);
  } else if (type === 'hit_ok') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(440, now);

    gain.gain.setValueAtTime(0.18, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.055);
  } else if (type === 'hit_miss') {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(150, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.1);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);

    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.105);
  }
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

  const track = ZundaAudio.bgmTracks[ZundaAudio.currentTrackIdx] || ZundaAudio.bgmTracks[0];
  const scale = track.scale;

  // Track 1: Warm Low Drone Pad (sine + triangle)
  const padOsc1 = ctx.createOscillator();
  const padOsc2 = ctx.createOscillator();
  const padGain = ctx.createGain();
  const filter = ctx.createBiquadFilter();

  padOsc1.type = 'sine';
  padOsc1.frequency.setValueAtTime(track.padFreqs[0], ctx.currentTime);

  padOsc2.type = 'triangle';
  padOsc2.frequency.setValueAtTime(track.padFreqs[1], ctx.currentTime);

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

  // Track 3: Sub-Bass Foundation Node
  const subOsc = ctx.createOscillator();
  const subGain = ctx.createGain();
  subOsc.type = 'sine';
  subOsc.frequency.setValueAtTime(track.subFreq, ctx.currentTime);
  subGain.gain.setValueAtTime(0.01, ctx.currentTime);
  subGain.gain.linearRampToValueAtTime(0.1, ctx.currentTime + 1.5);
  subOsc.connect(subGain);
  subGain.connect(ZundaAudio.bgmGain);
  subOsc.start();

  ZundaAudio.bgmPadOscs = [padOsc1, padOsc2, subOsc];
  ZundaAudio.bgmPadGain = padGain;
  ZundaAudio.bgmSubOsc = subOsc;

  // Track 2: Arpeggiated Melody Sequence Generator
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

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ZundaAudio;
}
if (typeof window !== 'undefined') {
  window.ZundaAudio = ZundaAudio;
  window.ZundaAudio.playVoiceLine = playZundaVoiceLine;
  window.playClickSFX = playClickSFX;
  window.playWindowSFX = playWindowSFX;
  window.playKeySFX = playKeySFX;
  window.playZundaVoiceLine = playZundaVoiceLine;
  window.toggleCozyBGM = toggleCozyBGM;
  window.startCozyBGM = startCozyBGM;
  window.stopCozyBGM = stopCozyBGM;
}
