/**
 * site/app.js — Creative Hub Applications Engine & Main Application Controller
 * Zundamon's Kitchen V2 (Zunda-OS 95 CLI Launch Page & Creative Hub)
 * Zero External Dependencies (100% Native Web Audio API & Vanilla ES6 DOM)
 */

// ============================================================================
// 1. Audio Bridge & Synthesizer Helpers
// ============================================================================

function playClick(type = 'down') {
  if (typeof window !== 'undefined' && typeof window.playClickSFX === 'function') {
    window.playClickSFX(type);
  }
}

function playWinSFX(action = 'focus') {
  if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
    window.playWindowSFX(action);
  }
}

function playKey(key = '') {
  if (typeof window !== 'undefined' && typeof window.playKeySFX === 'function') {
    window.playKeySFX(key);
  }
}

/**
 * Synthesizes procedural Zundamon vocal chirps and signature catchphrase arpeggios.
 * @param {'chirp' | 'nanoda_arpeggio' | 'hit_perfect' | 'hit_great' | 'hit_ok' | 'hit_miss'} type 
 */
function playZundaVoiceLine(type = 'chirp') {
  if (typeof window === 'undefined' || !window.ZundaAudio) return;
  const ZundaAudio = window.ZundaAudio;
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  if (type === 'nanoda_arpeggio') {
    // Signature 3-note ascending major triad catchphrase (F5 -> A5 -> C6)
    const notes = [698.46, 880.00, 1046.50];
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, now + idx * 0.07);
      gain.gain.setValueAtTime(0.25, now + idx * 0.07);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.07 + 0.12);
      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain || ctx.destination);
      osc.start(now + idx * 0.07);
      osc.stop(now + idx * 0.07 + 0.14);
    });
  } else if (type === 'chirp') {
    // High-pitched cute blip for typewriter voice lines
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const freq = 900 + Math.random() * 400;
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, now);
    osc.frequency.exponentialRampToValueAtTime(freq * 1.3, now + 0.03);
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain || ctx.destination);
    osc.start(now);
    osc.stop(now + 0.04);
  } else if (type === 'hit_perfect') {
    // Crisp high chime (880Hz -> 1760Hz)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(1760, now + 0.08);
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain || ctx.destination);
    osc.start(now);
    osc.stop(now + 0.11);
  } else if (type === 'hit_great') {
    // Bright pitch (660Hz)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(660, now);
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain || ctx.destination);
    osc.start(now);
    osc.stop(now + 0.09);
  } else if (type === 'hit_ok') {
    // Mid click (440Hz)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(440, now);
    gain.gain.setValueAtTime(0.18, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain || ctx.destination);
    osc.start(now);
    osc.stop(now + 0.06);
  } else if (type === 'hit_miss') {
    // Low thud (150Hz)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(150, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.1);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain || ctx.destination);
    osc.start(now);
    osc.stop(now + 0.11);
  }
}

// ============================================================================
// 2. Cookbook.app Specification & Data Model
// ============================================================================

const RECIPES = [
  {
    id: 'zunda-mochi',
    name: 'Zunda Mochi',
    japaneseName: 'ずんだ餅',
    category: 'mochi',
    badge: 'Signature Dish',
    iconSvg: 'mochi',
    description: 'Sweetened crushed edamame paste draped generously over warm, chewy glutinous rice cakes.',
    ingredients: [
      { name: 'Young Edamame Beans', amount: '200g' },
      { name: 'Mochi Rice Cake', amount: '4 pcs' },
      { name: 'Cane Sugar', amount: '2 tbsp' },
      { name: 'Sea Salt', amount: '1 pinch' }
    ],
    goldReward: 150,
    chefXP: 45,
    rhythmConfig: {
      bpm: 120,
      targetScore: 1200,
      tolerances: { perfect: 50, great: 120, ok: 200 },
      notePattern: ['🫛', '🍡', '🫛', '✨', '🫛', '🍡', '✨', '🎉']
    }
  },
  {
    id: 'zunda-matcha-tea',
    name: 'Zunda Matcha Latte',
    japaneseName: 'ずんだ抹茶ラテ',
    category: 'tea',
    badge: 'Cozy Brew',
    iconSvg: 'tea',
    description: 'Steamed oat milk poured over ceremonial Uji matcha and sweet edamame syrup.',
    ingredients: [
      { name: 'Uji Matcha Powder', amount: '2 tsp' },
      { name: 'Oat Milk', amount: '250ml' },
      { name: 'Zunda Edamame Syrup', amount: '30ml' }
    ],
    goldReward: 110,
    chefXP: 30,
    rhythmConfig: {
      bpm: 100,
      targetScore: 1000,
      tolerances: { perfect: 50, great: 120, ok: 200 },
      notePattern: ['🍵', '🫛', '🍵', '✨', '🍵', '🫛']
    }
  },
  {
    id: 'zunda-parfait',
    name: 'Zunda Parfait Deluxe',
    japaneseName: 'ずんだパフェ',
    category: 'desserts',
    badge: 'Deluxe Sweets',
    iconSvg: 'dessert',
    description: 'Layered dessert with green tea gelato, crushed zunda paste, vanilla cream, and dango.',
    ingredients: [
      { name: 'Matcha Gelato', amount: '2 scoops' },
      { name: 'Crushed Zunda Paste', amount: '80g' },
      { name: 'Whipped Cream', amount: '50g' },
      { name: 'Mini Dango Skewer', amount: '1 pc' }
    ],
    goldReward: 220,
    chefXP: 70,
    rhythmConfig: {
      bpm: 135,
      targetScore: 1800,
      tolerances: { perfect: 45, great: 100, ok: 180 },
      notePattern: ['🍨', '🫛', '🍡', '✨', '🍨', '🫛', '🍡', '✨', '🎉']
    }
  },
  {
    id: 'zunda-tempura-udon',
    name: 'Zunda Tempura Udon',
    japaneseName: 'ずんだ天ぷらうどん',
    category: 'entrees',
    badge: 'Hot Special',
    iconSvg: 'entree',
    description: 'Thick sanuki udon noodles in dashi broth topped with crispy edamame & vegetable tempura.',
    ingredients: [
      { name: 'Udon Noodles', amount: '200g' },
      { name: 'Dashi Broth', amount: '350ml' },
      { name: 'Edamame Tempura Kakiage', amount: '2 pcs' },
      { name: 'Scallions', amount: '1 tbsp' }
    ],
    goldReward: 280,
    chefXP: 95,
    rhythmConfig: {
      bpm: 140,
      targetScore: 2200,
      tolerances: { perfect: 40, great: 90, ok: 160 },
      notePattern: ['🍜', '🫛', '🍤', '🍜', '✨', '🫛', '🍤', '🎉']
    }
  }
];

function renderSvgIcon(type = 'pea') {
  if (type === 'mochi') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="36" height="36">
      <ellipse cx="32" cy="46" rx="26" ry="12" fill="#c8e6c9" stroke="#1b5e20" stroke-width="2"/>
      <circle cx="22" cy="34" r="12" fill="#ffffff" stroke="#2e7d32" stroke-width="2"/>
      <circle cx="42" cy="34" r="12" fill="#ffffff" stroke="#2e7d32" stroke-width="2"/>
      <path d="M 12 30 Q 32 16 52 30 Q 42 42 22 42 Z" fill="#8bc34a" opacity="0.9"/>
      <circle cx="28" cy="24" r="2" fill="#4caf50"/>
      <circle cx="36" cy="22" r="2" fill="#4caf50"/>
    </svg>`;
  } else if (type === 'tea') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="36" height="36">
      <rect x="14" y="24" width="36" height="28" rx="6" fill="#ffffff" stroke="#1b5e20" stroke-width="2"/>
      <path d="M 50 30 C 58 30 58 44 50 44" fill="none" stroke="#1b5e20" stroke-width="3"/>
      <rect x="16" y="26" width="32" height="12" rx="3" fill="#8bc34a"/>
      <path d="M 24 16 Q 28 10 24 6 M 34 16 Q 38 10 34 6" fill="none" stroke="#4caf50" stroke-width="2" stroke-linecap="round"/>
    </svg>`;
  } else if (type === 'dessert') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="36" height="36">
      <path d="M 22 52 L 42 52 M 32 38 L 32 52 M 16 16 L 48 16 L 40 38 L 24 38 Z" fill="none" stroke="#1b5e20" stroke-width="2"/>
      <path d="M 18 18 L 46 18 L 40 36 L 24 36 Z" fill="#e8f5e9"/>
      <circle cx="32" cy="14" r="8" fill="#8bc34a"/>
      <circle cx="26" cy="18" r="6" fill="#4caf50"/>
      <circle cx="38" cy="18" r="6" fill="#ffffff"/>
    </svg>`;
  } else if (type === 'entree') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="36" height="36">
      <path d="M 10 24 C 10 48 54 48 54 24 Z" fill="#ffd54f" stroke="#1b5e20" stroke-width="2"/>
      <ellipse cx="32" cy="24" rx="22" ry="7" fill="#4caf50" opacity="0.8"/>
      <line x1="8" y1="12" x2="48" y2="28" stroke="#1b5e20" stroke-width="2"/>
      <line x1="16" y1="8" x2="56" y2="24" stroke="#1b5e20" stroke-width="2"/>
    </svg>`;
  } else {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="36" height="36">
      <path d="M 10 32 Q 32 10 54 32 Q 32 54 10 32 Z" fill="#8bc34a" stroke="#1b5e20" stroke-width="2"/>
      <circle cx="22" cy="32" r="5" fill="#4caf50"/>
      <circle cx="32" cy="32" r="5" fill="#4caf50"/>
      <circle cx="42" cy="32" r="5" fill="#4caf50"/>
    </svg>`;
  }
}

class CookbookApp {
  constructor() {
    this.recipes = RECIPES;
    this.activeCategory = 'all';
    this.searchQuery = '';
    this.selectedRecipe = RECIPES[0];
    this.rhythmSimulator = null;
  }

  init() {
    if (typeof document === 'undefined') return;

    this.searchInput = document.getElementById('recipe-search');
    this.gridContainer = document.getElementById('recipe-grid');
    this.detailPanel = document.getElementById('cookbook-detail-view') || document.getElementById('recipe-detail-panel');
    this.filterButtons = document.querySelectorAll('.recipe-filter-tags .win95-btn');

    this.bindEvents();
    this.renderGrid();
    if (this.selectedRecipe) {
      this.selectRecipe(this.selectedRecipe.id);
    }
  }

  bindEvents() {
    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => {
        this.searchQuery = e.target.value.toLowerCase().trim();
        this.renderGrid();
      });
    }

    if (this.filterButtons) {
      this.filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
          playClick('down');
          this.filterButtons.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          this.activeCategory = btn.dataset.filter || 'all';
          this.renderGrid();
        });
      });
    }
  }

  getFilteredRecipes() {
    return this.recipes.filter(recipe => {
      const matchCat = (this.activeCategory === 'all' || recipe.category === this.activeCategory);
      if (!matchCat) return false;
      if (!this.searchQuery) return true;

      const q = this.searchQuery;
      const inName = recipe.name.toLowerCase().includes(q);
      const inJap = recipe.japaneseName.toLowerCase().includes(q);
      const inCat = recipe.category.toLowerCase().includes(q);
      const inBadge = recipe.badge.toLowerCase().includes(q);
      const inIng = recipe.ingredients.some(i => i.name.toLowerCase().includes(q));

      return inName || inJap || inCat || inBadge || inIng;
    });
  }

  renderGrid() {
    if (!this.gridContainer) return;

    const filtered = this.getFilteredRecipes();
    this.gridContainer.innerHTML = '';

    if (filtered.length === 0) {
      const emptyDiv = document.createElement('div');
      emptyDiv.className = 'recipe-empty-state';
      emptyDiv.innerHTML = `
        <span class="empty-icon" style="font-size:32px;">🫛🔍</span>
        <p style="margin:8px 0; font-size:12px; color:#1b5e20;">No recipes found matching "<strong>${this.escapeHtml(this.searchQuery)}</strong>" nanoda!</p>
        <button class="win95-btn" id="btn-reset-recipe-filters">Reset Filters</button>
      `;
      this.gridContainer.appendChild(emptyDiv);

      const resetBtn = emptyDiv.querySelector('#btn-reset-recipe-filters');
      if (resetBtn) {
        resetBtn.addEventListener('click', () => {
          playClick('down');
          this.searchQuery = '';
          this.activeCategory = 'all';
          if (this.searchInput) this.searchInput.value = '';
          if (this.filterButtons) {
            this.filterButtons.forEach(b => {
              if (b.dataset.filter === 'all') b.classList.add('active');
              else b.classList.remove('active');
            });
          }
          this.renderGrid();
        });
      }
      return;
    }

    filtered.forEach(recipe => {
      const card = document.createElement('article');
      card.className = `recipe-card ${this.selectedRecipe && this.selectedRecipe.id === recipe.id ? 'selected' : ''}`;
      card.dataset.recipeId = recipe.id;
      card.dataset.category = recipe.category;

      card.innerHTML = `
        <div class="recipe-thumbnail">${renderSvgIcon(recipe.iconSvg)}</div>
        <div class="recipe-info">
          <h3 class="recipe-title">${recipe.name}</h3>
          <span class="recipe-jap-title" style="font-size:11px; color:#424242;">${recipe.japaneseName}</span>
          <p class="recipe-desc">${recipe.description}</p>
          <span class="recipe-badge">${recipe.badge}</span>
        </div>
      `;

      card.addEventListener('click', () => {
        playClick('down');
        this.selectRecipe(recipe.id);
      });

      this.gridContainer.appendChild(card);
    });
  }

  selectRecipe(id) {
    const found = this.recipes.find(r => r.id === id);
    if (!found) return;
    this.selectedRecipe = found;

    // Update active visual state in sidebar grid
    if (this.gridContainer) {
      this.gridContainer.querySelectorAll('.recipe-card').forEach(card => {
        if (card.dataset.recipeId === id) {
          card.classList.add('selected');
        } else {
          card.classList.remove('selected');
        }
      });
    }

    this.renderDetailView(found);
  }

  renderDetailView(recipe) {
    if (!this.detailPanel) return;

    const highscore = typeof localStorage !== 'undefined'
      ? (localStorage.getItem(`zunda_rhythm_highscore_${recipe.id}`) || '0')
      : '0';

    this.detailPanel.innerHTML = `
      <div class="detail-header" style="display:flex; justify-content:space-between; align-items:flex-start; border-bottom:2px solid var(--win-border-shadow); padding-bottom:8px; margin-bottom:10px;">
        <div>
          <h2 style="font-size:16px; color:#1b5e20; margin:0;">${renderSvgIcon(recipe.iconSvg)} ${recipe.name} <span style="font-size:13px; font-weight:normal;">(${recipe.japaneseName})</span></h2>
          <span class="recipe-badge" style="margin-top:4px; display:inline-block;">${recipe.badge}</span>
        </div>
        <div style="text-align:right; font-size:12px;">
          <div>🪙 Gold: <strong>${recipe.goldReward}</strong></div>
          <div>⭐ Chef XP: <strong>${recipe.chefXP}</strong></div>
          <div style="margin-top:2px; font-size:11px; color:#2e7d32;">🏆 High Score: <strong id="recipe-highscore">${highscore}</strong></div>
        </div>
      </div>

      <p style="font-size:12px; color:#2e7d32; margin-bottom:10px;">${recipe.description}</p>

      <div class="ingredients-section" style="margin-bottom:12px;">
        <h4 style="font-size:12px; color:#1b5e20; margin-bottom:6px;">🫛 Required Ingredients</h4>
        <div class="bevel-inset" style="padding:6px; background:#fafafa;">
          <table style="width:100%; border-collapse:collapse; font-size:11px;">
            <thead>
              <tr style="border-bottom:1px solid #ccc; text-align:left; color:#1b5e20;">
                <th style="padding:2px 4px;">Ingredient</th>
                <th style="padding:2px 4px; text-align:right;">Amount</th>
              </tr>
            </thead>
            <tbody>
              ${recipe.ingredients.map(ing => `
                <tr style="border-bottom:1px dashed #eee;">
                  <td style="padding:3px 4px;">${ing.name}</td>
                  <td style="padding:3px 4px; text-align:right; font-weight:bold;">${ing.amount}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>

      <!-- Rhythm Minigame Simulator Widget -->
      <div id="rhythm-widget-root"></div>
    `;

    // Mount Rhythm Simulator Widget
    const rootEl = this.detailPanel.querySelector('#rhythm-widget-root');
    if (rootEl) {
      if (this.rhythmSimulator) {
        this.rhythmSimulator.destroy();
      }
      this.rhythmSimulator = new RhythmSimulator(rootEl, recipe);
      this.rhythmSimulator.init();
    }
  }

  escapeHtml(str) {
    return (str || '').replace(/[&<>"']/g, m => {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[m];
    });
  }
}

// ============================================================================
// 3. Rhythm Minigame Simulator Engine
// ============================================================================

class RhythmSimulator {
  constructor(container, recipe) {
    this.container = container;
    this.recipe = recipe;
    this.config = recipe.rhythmConfig || {
      bpm: 120,
      targetScore: 1200,
      tolerances: { perfect: 50, great: 120, ok: 200 },
      notePattern: ['🫛', '🍡', '✨', '🫛']
    };

    this.isPlaying = false;
    this.score = 0;
    this.combo = 0;
    this.maxCombo = 0;
    this.totalNotes = 0;
    this.hits = { perfect: 0, great: 0, ok: 0, miss: 0 };
    this.activeNotes = []; // Array of active note objects
    this.animFrame = null;
    this.startTime = 0;
    this.noteSequence = [];
    this.boundKeyDown = this.handleKeyDown.bind(this);
  }

  init() {
    this.render();
    this.bindEvents();
  }

  render() {
    this.container.innerHTML = `
      <div class="rhythm-widget-container">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <h4 style="margin:0; font-size:12px; color:#aed581;">🎵 Cooking Rhythm Practice (BPM: ${this.config.bpm})</h4>
          <span style="font-size:11px; color:#c8e6c9;">Target: <strong>${this.config.targetScore}</strong> pts</span>
        </div>

        <div class="rhythm-track-area" id="rhythm-track">
          <div class="rhythm-target-zone" id="hit-target-zone">TARGET</div>
          <div id="rhythm-notes-container"></div>
        </div>

        <div style="display:flex; gap:8px; align-items:center; justify-content:space-between;">
          <button id="btn-start-rhythm" class="win95-btn">▶ Start Practice</button>
          <button id="btn-hit-beat" class="win95-btn rhythm-hit-btn" disabled>🫛 HIT BEAT (Spacebar)</button>
        </div>

        <div class="rhythm-dashboard" style="display:flex; justify-content:space-between; align-items:center; background:#0d190f; padding:6px 10px; border-radius:3px; border:1px solid #2e7d32; font-family:monospace; font-size:12px;">
          <div>Score: <span id="rhythm-score" style="color:#ffffff; font-weight:bold;">0</span></div>
          <div>Combo: <span id="rhythm-combo" style="color:#ffeb3b; font-weight:bold;">x0</span></div>
          <div>Grade: <span id="rhythm-grade" style="color:#00e676; font-weight:bold;">-</span></div>
        </div>

        <div id="rhythm-feedback" class="rhythm-feedback-banner">READY!</div>
      </div>
    `;

    this.trackEl = this.container.querySelector('#rhythm-track');
    this.notesContainer = this.container.querySelector('#rhythm-notes-container');
    this.btnStart = this.container.querySelector('#btn-start-rhythm');
    this.btnHit = this.container.querySelector('#btn-hit-beat');
    this.scoreEl = this.container.querySelector('#rhythm-score');
    this.comboEl = this.container.querySelector('#rhythm-combo');
    this.gradeEl = this.container.querySelector('#rhythm-grade');
    this.feedbackEl = this.container.querySelector('#rhythm-feedback');
  }

  bindEvents() {
    if (this.btnStart) {
      this.btnStart.addEventListener('click', () => {
        playClick('start');
        if (this.isPlaying) {
          this.stop();
        } else {
          this.start();
        }
      });
    }

    if (this.btnHit) {
      this.btnHit.addEventListener('click', () => {
        this.evaluateHit();
      });
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('keydown', this.boundKeyDown);
    }
  }

  handleKeyDown(e) {
    if (!this.isPlaying) return;
    if (e.code === 'Space' || e.key === ' ') {
      // Prevent page scroll when practicing rhythm
      const activeEl = document.activeElement;
      if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) return;
      e.preventDefault();
      this.evaluateHit();
    }
  }

  start() {
    this.stop();
    this.isPlaying = true;
    this.score = 0;
    this.combo = 0;
    this.maxCombo = 0;
    this.hits = { perfect: 0, great: 0, ok: 0, miss: 0 };
    this.updateDashboard();

    if (this.btnStart) this.btnStart.textContent = '⏹ Stop Practice';
    if (this.btnHit) this.btnHit.disabled = false;
    if (this.feedbackEl) {
      this.feedbackEl.textContent = 'COOKING START!';
      this.feedbackEl.className = 'rhythm-feedback-banner feedback-perfect';
    }

    // Generate note schedule from pattern
    const pattern = this.config.notePattern || ['🫛', '🍡', '✨'];
    const intervalMs = (60 / this.config.bpm) * 1000;
    const scrollDuration = 2000; // 2.0s to cross track

    this.startTime = Date.now();
    this.noteSequence = [];

    // Schedule 16 beats loop
    for (let i = 0; i < 16; i++) {
      const icon = pattern[i % pattern.length];
      const targetHitTime = this.startTime + scrollDuration + (i * intervalMs);
      this.noteSequence.push({
        id: i,
        icon,
        targetHitTime,
        spawnTime: targetHitTime - scrollDuration,
        spawned: false,
        hit: false,
        element: null
      });
    }

    this.totalNotes = this.noteSequence.length;
    this.loop();
  }

  stop() {
    this.isPlaying = false;
    if (this.animFrame) {
      cancelAnimationFrame(this.animFrame);
      this.animFrame = null;
    }
    if (this.btnStart) this.btnStart.textContent = '▶ Start Practice';
    if (this.btnHit) this.btnHit.disabled = true;
    if (this.notesContainer) this.notesContainer.innerHTML = '';
  }

  destroy() {
    this.stop();
    if (typeof window !== 'undefined') {
      window.removeEventListener('keydown', this.boundKeyDown);
    }
  }

  loop() {
    if (!this.isPlaying) return;

    const now = Date.now();

    // Spawn due notes
    this.noteSequence.forEach(note => {
      if (!note.spawned && now >= note.spawnTime) {
        note.spawned = true;
        const el = document.createElement('div');
        el.className = 'rhythm-note-node';
        el.textContent = note.icon;
        el.style.left = '100%';
        if (this.notesContainer) this.notesContainer.appendChild(el);
        note.element = el;
      }
    });

    // Update note positions
    const scrollDuration = 2000;
    const targetPercent = 15; // Target zone is at 15% left position

    this.noteSequence.forEach(note => {
      if (note.spawned && !note.hit && note.element) {
        const elapsed = now - note.spawnTime;
        const progress = elapsed / scrollDuration; // 0.0 -> 1.0 (reaches 15% at 1.0)
        const leftPercent = 100 - (progress * (100 - targetPercent));

        note.element.style.left = `${leftPercent}%`;

        // Check if missed (passed target zone by more than tolerance ok 200ms)
        if (now > note.targetHitTime + this.config.tolerances.ok) {
          note.hit = true;
          note.element.style.opacity = '0.3';
          this.processResult('MISS', 0);
        }
      }
    });

    // Check if session completed
    const allProcessed = this.noteSequence.every(n => n.hit);
    if (allProcessed) {
      this.endSession();
      return;
    }

    this.animFrame = requestAnimationFrame(() => this.loop());
  }

  evaluateHit() {
    if (!this.isPlaying) return;
    const now = Date.now();

    // Find nearest un-hit spawned note
    let candidate = null;
    let minDiff = Infinity;

    this.noteSequence.forEach(note => {
      if (note.spawned && !note.hit) {
        const diff = Math.abs(now - note.targetHitTime);
        if (diff < minDiff) {
          minDiff = diff;
          candidate = note;
        }
      }
    });

    if (!candidate || minDiff > 350) {
      // Empty press
      return;
    }

    candidate.hit = true;
    if (candidate.element) {
      candidate.element.remove();
      candidate.element = null;
    }

    const { perfect, great, ok } = this.config.tolerances;

    if (minDiff <= perfect) {
      this.processResult('PERFECT', 100);
      playZundaVoiceLine('hit_perfect');
    } else if (minDiff <= great) {
      this.processResult('GREAT', 75);
      playZundaVoiceLine('hit_great');
    } else if (minDiff <= ok) {
      this.processResult('OK', 40);
      playZundaVoiceLine('hit_ok');
    } else {
      this.processResult('MISS', 0);
      playZundaVoiceLine('hit_miss');
    }
  }

  processResult(rating, baseScore) {
    if (rating === 'PERFECT') {
      this.combo++;
      this.hits.perfect++;
      const mult = 1 + Math.floor(this.combo / 5) * 0.2;
      this.score += Math.round(baseScore * mult);
    } else if (rating === 'GREAT') {
      this.combo++;
      this.hits.great++;
      const mult = 1 + Math.floor(this.combo / 5) * 0.1;
      this.score += Math.round(baseScore * mult);
    } else if (rating === 'OK') {
      this.combo++;
      this.hits.ok++;
      this.score += baseScore;
    } else {
      this.combo = 0;
      this.hits.miss++;
      playZundaVoiceLine('hit_miss');
    }

    if (this.combo > this.maxCombo) {
      this.maxCombo = this.combo;
    }

    this.updateDashboard();

    if (this.feedbackEl) {
      this.feedbackEl.textContent = rating === 'PERFECT' ? '🌟 PERFECT!!' : (rating === 'GREAT' ? '✨ GREAT!' : (rating === 'OK' ? '👍 OK' : '❌ MISS'));
      this.feedbackEl.className = `rhythm-feedback-banner feedback-${rating.toLowerCase()}`;
    }
  }

  calculateGrade() {
    const totalProcessed = this.hits.perfect + this.hits.great + this.hits.ok + this.hits.miss;
    if (totalProcessed === 0) return '-';

    const accuracy = (this.hits.perfect * 1.0 + this.hits.great * 0.75 + this.hits.ok * 0.4) / totalProcessed;

    if (accuracy >= 0.90 || this.score >= this.config.targetScore) return 'S';
    if (accuracy >= 0.75) return 'A';
    if (accuracy >= 0.60) return 'B';
    return 'C';
  }

  updateDashboard() {
    if (this.scoreEl) this.scoreEl.textContent = this.score;
    if (this.comboEl) this.comboEl.textContent = `x${this.combo}`;
    if (this.gradeEl) this.gradeEl.textContent = this.calculateGrade();
  }

  endSession() {
    this.stop();
    const finalGrade = this.calculateGrade();
    if (this.feedbackEl) {
      this.feedbackEl.textContent = `PRACTICE COMPLETE! Final Grade: ${finalGrade} (${this.score} pts)`;
      this.feedbackEl.className = 'rhythm-feedback-banner feedback-perfect';
    }

    // Persist local high score
    if (typeof localStorage !== 'undefined') {
      const key = `zunda_rhythm_highscore_${this.recipe.id}`;
      const currentHigh = parseInt(localStorage.getItem(key) || '0', 10);
      if (this.score > currentHigh) {
        localStorage.setItem(key, this.score.toString());
        const highscoreEl = document.getElementById('recipe-highscore');
        if (highscoreEl) highscoreEl.textContent = this.score;
      }
    }
  }
}

// ============================================================================
// 4. VNTalkApp Specification & Dialogue Engine
// ============================================================================

const VN_DIALOGUE_TREE = {
  start: {
    speaker: "Zundamon (ずんだもん)",
    expression: "happy",
    text: "Welcome to Zundamon's Kitchen V2 nanoda! What delicious edamame treats or dev secrets shall we explore today?",
    choices: [
      { text: "🫛 Tell me about Zunda recipes!", target: "topic_recipes" },
      { text: "🎮 How do I play Zundamon's Kitchen on Roblox?", target: "topic_roblox" },
      { text: "💡 Share a fun Zunda fact nanoda!", target: "topic_facts" },
      { text: "🔊 Hear Zundamon's Voice Lines!", target: "topic_voice" },
      { text: "📝 Open QuickStart Developer Guide", action: "open_quickstart" }
    ]
  },
  topic_recipes: {
    speaker: "Zundamon (ずんだもん)",
    expression: "cooking",
    text: "Zunda Mochi is made by crushing fresh green edamame beans with sugar and salt! We also serve Zunda Shakes, Parfaits, and Dango nanoda!",
    choices: [
      { text: "📖 Open Cookbook.app Recipe Book", action: "open_cookbook" },
      { text: "↩️ Back to main menu", target: "start" }
    ]
  },
  topic_roblox: {
    speaker: "Zundamon (ずんだもん)",
    expression: "excited",
    text: "Our Roblox game features modular Luau cooking systems, rhythm targets, and Rojo 7.7.0 live sync! Try it out nanoda!",
    choices: [
      { text: "🚀 Launch Roblox Game Page", action: "launch_roblox" },
      { text: "↩️ Back to main menu", target: "start" }
    ]
  },
  topic_facts: {
    speaker: "Zundamon (ずんだもん)",
    expression: "cozy",
    text: "Fact: Zunda-OS 95 runs 100% on green bean power and procedural Web Audio synthesis! No heavy external libraries required nanoda!",
    choices: [
      { text: "💡 Tell me another fact!", target: "topic_facts_2" },
      { text: "↩️ Back to main menu", target: "start" }
    ]
  },
  topic_facts_2: {
    speaker: "Zundamon (ずんだもん)",
    expression: "happy",
    text: "In Sendai, edamame paste has been enjoyed over mochi since the Sengoku era! It's both healthy and super sweet, nanoda!",
    choices: [
      { text: "↩️ Back to main menu", target: "start" }
    ]
  },
  topic_voice: {
    speaker: "Zundamon (ずんだもん)",
    expression: "excited",
    text: "Nanoda! Nanoda! (ずんだもんの声) Can you hear my Web Audio voice synthesizer previewing nanoda?",
    voiceTrigger: "nanoda_arpeggio",
    choices: [
      { text: "🔊 Play 'Nanoda!' Catchphrase", target: "topic_voice" },
      { text: "↩️ Back to main menu", target: "start" }
    ]
  }
};

class VNTalkApp {
  constructor(tree = VN_DIALOGUE_TREE) {
    this.tree = tree;
    this.currentNodeId = 'start';
    this.isTyping = false;
    this.typeTimer = null;
    this.fullText = '';
  }

  init() {
    if (typeof document === 'undefined') return;

    this.speakerEl = document.getElementById('vn-speaker');
    this.textEl = document.getElementById('vn-text');
    this.choicesContainer = document.getElementById('vn-choices');
    this.portraitEl = document.getElementById('vn-portrait');
    this.stageEl = document.getElementById('vn-stage');
    this.dialogueBox = document.getElementById('vn-dialogue-box');

    this.bindEvents();
    this.renderNode(this.currentNodeId);
  }

  bindEvents() {
    if (this.dialogueBox) {
      this.dialogueBox.addEventListener('click', (e) => {
        if (e.target.closest('.vn-choice-btn')) return;
        if (this.isTyping) {
          this.skipTypewriter();
        }
      });
    }
  }

  renderNode(nodeId) {
    const node = this.tree[nodeId];
    if (!node) return;
    this.currentNodeId = nodeId;

    if (this.speakerEl) this.speakerEl.textContent = node.speaker || 'Zundamon (ずんだもん)';
    this.setExpression(node.expression || 'happy');

    if (node.voiceTrigger) {
      playZundaVoiceLine(node.voiceTrigger);
    }

    this.startTypewriter(node.text, () => {
      this.renderChoices(node.choices || []);
    });
  }

  setExpression(expression) {
    if (this.portraitEl) {
      this.portraitEl.dataset.expression = expression;
    }
    if (this.stageEl) {
      this.stageEl.dataset.expression = expression;
    }
  }

  startTypewriter(text, onComplete) {
    if (this.typeTimer) clearInterval(this.typeTimer);
    this.isTyping = true;
    this.fullText = text;
    if (this.textEl) this.textEl.textContent = '';
    if (this.choicesContainer) this.choicesContainer.innerHTML = '';

    let index = 0;
    this.typeTimer = setInterval(() => {
      if (index < text.length) {
        if (this.textEl) this.textEl.textContent += text.charAt(index);
        if (index % 3 === 0) {
          playZundaVoiceLine('chirp');
        }
        index++;
      } else {
        clearInterval(this.typeTimer);
        this.typeTimer = null;
        this.isTyping = false;

        // Append pulsing prompt indicator ▼
        if (this.textEl) {
          const indicator = document.createElement('span');
          indicator.className = 'vn-prompt-indicator';
          indicator.textContent = ' ▼';
          indicator.style.cssText = 'color:#4caf50; display:inline-block; animation:floatPea 1.2s infinite; font-weight:bold; margin-left:4px;';
          this.textEl.appendChild(indicator);
        }

        if (onComplete) onComplete();
      }
    }, 28);
  }

  skipTypewriter() {
    if (this.typeTimer) clearInterval(this.typeTimer);
    this.typeTimer = null;
    this.isTyping = false;
    if (this.textEl) {
      this.textEl.textContent = this.fullText;
      const indicator = document.createElement('span');
      indicator.className = 'vn-prompt-indicator';
      indicator.textContent = ' ▼';
      indicator.style.cssText = 'color:#4caf50; display:inline-block; animation:floatPea 1.2s infinite; font-weight:bold; margin-left:4px;';
      this.textEl.appendChild(indicator);
    }
    const node = this.tree[this.currentNodeId];
    if (node) this.renderChoices(node.choices || []);
  }

  renderChoices(choices) {
    if (!this.choicesContainer) return;
    this.choicesContainer.innerHTML = '';

    choices.forEach(c => {
      const btn = document.createElement('button');
      btn.className = 'vn-choice-btn';
      btn.textContent = c.text;
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        playClick('down');
        if (c.target) {
          this.renderNode(c.target);
        } else if (c.action) {
          this.executeAction(c.action);
        }
      });
      this.choicesContainer.appendChild(btn);
    });
  }

  executeAction(action) {
    if (action === 'open_cookbook' && typeof window !== 'undefined' && window.windowManager) {
      window.windowManager.openWindow('window-cookbook');
    } else if (action === 'open_quickstart' && typeof window !== 'undefined' && window.windowManager) {
      window.windowManager.openWindow('window-quickstart');
    } else if (action === 'launch_roblox' && typeof window !== 'undefined') {
      window.open('https://www.roblox.com/', '_blank');
    }
  }
}

// ============================================================================
// 5. QuickStartApp Specification (Win95 Notepad & Copy Cards)
// ============================================================================

class QuickStartApp {
  init() {
    if (typeof document === 'undefined') return;

    this.bindCopyButtons();
    this.bindActionButtons();
    this.initNotepadStatusBar();
  }

  bindCopyButtons() {
    document.querySelectorAll('.copy-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const textToCopy = btn.dataset.copy;
        if (!textToCopy) return;

        playClick('start');

        if (typeof navigator !== 'undefined' && navigator.clipboard) {
          navigator.clipboard.writeText(textToCopy).then(() => {
            this.showToast('✓ Code copied to clipboard!');
            const orig = btn.textContent;
            btn.textContent = '✓ Copied!';
            btn.classList.add('active');
            setTimeout(() => {
              btn.textContent = orig;
              btn.classList.remove('active');
            }, 2000);
          }).catch(err => {
            console.error('Clipboard copy failed:', err);
            this.fallbackCopy(textToCopy, btn);
          });
        } else {
          this.fallbackCopy(textToCopy, btn);
        }
      });
    });
  }

  fallbackCopy(text, btn) {
    const input = document.createElement('textarea');
    input.value = text;
    document.body.appendChild(input);
    input.select();
    try {
      document.execCommand('copy');
      this.showToast('✓ Code copied to clipboard!');
      const orig = btn.textContent;
      btn.textContent = '✓ Copied!';
      setTimeout(() => { btn.textContent = orig; }, 2000);
    } catch (e) {
      alert(`Code snippet: ${text}`);
    }
    document.body.removeChild(input);
  }

  bindActionButtons() {
    const launchRobloxBtn = document.getElementById('btn-launch-roblox');
    if (launchRobloxBtn) {
      launchRobloxBtn.addEventListener('click', () => {
        playClick('down');
        window.open('https://www.roblox.com/', '_blank');
      });
    }

    const launchRepoBtn = document.getElementById('btn-launch-repo');
    if (launchRepoBtn) {
      launchRepoBtn.addEventListener('click', () => {
        playClick('down');
        window.open('https://github.com/fromage3900/Zundamons-Kitchen-V2', '_blank');
      });
    }
  }

  initNotepadStatusBar() {
    const editor = document.querySelector('.notepad-editor');
    const statusEl = document.getElementById('notepad-status');

    if (editor && statusEl) {
      const updateStatus = () => {
        const val = editor.value.substring(0, editor.selectionStart);
        const lines = val.split('\n');
        const lineNum = lines.length;
        const colNum = lines[lines.length - 1].length + 1;
        statusEl.textContent = `Ln ${lineNum}, Col ${colNum} | 100% | UTF-8 | Windows (CRLF) | Zunda-OS 95`;
      };

      editor.addEventListener('keyup', updateStatus);
      editor.addEventListener('click', updateStatus);
      updateStatus();
    }
  }

  showToast(message) {
    let toastContainer = document.getElementById('zunda-toast-container');
    if (!toastContainer) {
      toastContainer = document.createElement('div');
      toastContainer.id = 'zunda-toast-container';
      toastContainer.style.cssText = 'position:fixed; bottom:50px; right:20px; z-index:10001; display:flex; flex-direction:column; gap:6px; pointer-events:none;';
      document.body.appendChild(toastContainer);
    }

    const toast = document.createElement('div');
    toast.className = 'zunda-toast bevel-outset';
    toast.textContent = message;
    toast.style.cssText = 'background:#c8e6c9; color:#1b5e20; padding:6px 12px; font-weight:bold; font-size:12px; box-shadow:2px 2px 8px rgba(0,0,0,0.3); transition:all 0.3s ease;';

    toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      setTimeout(() => toast.remove(), 300);
    }, 2000);
  }
}

// ============================================================================
// 6. MainApp — Desktop Integration, Start Menu, System Tray & Particles
// ============================================================================

class MainApp {
  init() {
    if (typeof document === 'undefined') return;

    this.initClock();
    this.initWindowManager();
    this.initDesktopShortcuts();
    this.initStartMenu();
    this.initSystemTray();
    this.initParticleCanvas();

    // Initialize Application Submodules
    this.cookbook = new CookbookApp();
    this.cookbook.init();

    this.vntalk = new VNTalkApp();
    this.vntalk.init();

    this.quickstart = new QuickStartApp();
    this.quickstart.init();

    this.initPromosApp();
    this.initCalculatorApp();
    this.initZundamonApp();
    this.initDesktopWidgets();
  }

  initClock() {
    const updateClock = () => {
      const clockEl = document.getElementById('taskbar-clock');
      if (clockEl) {
        const now = new Date();
        clockEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      }
    };
    setInterval(updateClock, 1000);
    updateClock();
  }

  initWindowManager() {
    if (typeof window.WindowManager === 'function') {
      const windowManager = new WindowManager();
      windowManager.init();
      window.windowManager = windowManager;
    }
  }

  initDesktopShortcuts() {
    document.querySelectorAll('.desktop-shortcut').forEach(shortcut => {
      const handleOpen = () => {
        playClick('down');
        const targetId = shortcut.dataset.openWindow;
        if (targetId && window.windowManager) {
          window.windowManager.openWindow(targetId);
        }
      };

      shortcut.addEventListener('click', handleOpen);
      shortcut.addEventListener('dblclick', handleOpen);
    });
  }

  initStartMenu() {
    const startBtn = document.getElementById('start-btn');
    const startMenu = document.getElementById('start-menu');

    if (startBtn && startMenu) {
      startBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        playClick('start');
        const isHidden = startMenu.classList.contains('hidden');
        if (isHidden) {
          startMenu.classList.remove('hidden');
          startBtn.classList.add('start-btn-active');
        } else {
          startMenu.classList.add('hidden');
          startBtn.classList.remove('start-btn-active');
        }
      });

      document.addEventListener('click', (e) => {
        if (!startMenu.contains(e.target) && e.target !== startBtn) {
          startMenu.classList.add('hidden');
          startBtn.classList.remove('start-btn-active');
        }
      });

      startMenu.querySelectorAll('.start-item[data-open-window]').forEach(item => {
        item.addEventListener('click', () => {
          playClick('down');
          const targetId = item.dataset.openWindow;
          if (targetId && window.windowManager) {
            window.windowManager.openWindow(targetId);
          }
          startMenu.classList.add('hidden');
          startBtn.classList.remove('start-btn-active');
        });
      });

      const menuCrtBtn = document.getElementById('menu-toggle-crt');
      if (menuCrtBtn) {
        menuCrtBtn.addEventListener('click', () => {
          playClick('down');
          const crtOverlay = document.getElementById('crt-overlay');
          if (crtOverlay) {
            crtOverlay.classList.toggle('crt-off');
          }
        });
      }

      const menuThemeBtn = document.getElementById('menu-toggle-theme');
      if (menuThemeBtn) {
        menuThemeBtn.addEventListener('click', () => {
          playClick('down');
          const currentTheme = document.documentElement.getAttribute('data-theme');
          const nextTheme = currentTheme === 'zunda-classic' ? 'zunda-dark' : 'zunda-classic';
          document.documentElement.setAttribute('data-theme', nextTheme);
        });
      }

      const shutdownBtn = document.getElementById('menu-shutdown');
      if (shutdownBtn) {
        shutdownBtn.addEventListener('click', () => {
          playClick('down');
          alert("Shutting down Zunda-OS 95... See you soon, nanoda! 🫛");
          location.reload();
        });
      }
    }
  }

  initPromosApp() {
    document.querySelectorAll('.copy-code-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        playClick('down');
        const code = btn.dataset.code || '';
        if (navigator.clipboard && code) {
          navigator.clipboard.writeText(code).then(() => {
            const originalText = btn.textContent;
            btn.textContent = '✓ COPIED!';
            btn.style.backgroundColor = '#2e7d32';
            btn.style.color = '#fff';
            if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('hit_perfect');
            setTimeout(() => {
              btn.textContent = originalText;
              btn.style.backgroundColor = '';
              btn.style.color = '';
            }, 2000);
          }).catch(() => {
            alert(`Promo Code: ${code}`);
          });
        } else if (code) {
          alert(`Promo Code: ${code}`);
        }
      });
    });
  }

  initCalculatorApp() {
    const dishSelect = document.getElementById('calc-dish-select');
    const qtyInput = document.getElementById('calc-qty');
    const resCost = document.getElementById('res-cost');
    const resSell = document.getElementById('res-sell');
    const resProfit = document.getElementById('res-profit');

    const updateCalc = () => {
      if (!dishSelect || !qtyInput || !resCost || !resSell || !resProfit) return;
      const opt = dishSelect.options[dishSelect.selectedIndex];
      if (!opt) return;

      const costPerUnit = parseInt(opt.dataset.cost || '10', 10);
      const sellPerUnit = parseInt(opt.dataset.sell || '50', 10);
      const qty = Math.max(1, parseInt(qtyInput.value || '1', 10));

      const totalCost = costPerUnit * qty;
      const totalSell = sellPerUnit * qty;
      const netProfit = totalSell - totalCost;

      resCost.textContent = totalCost.toLocaleString();
      resSell.textContent = totalSell.toLocaleString();
      resProfit.textContent = `+${netProfit.toLocaleString()} Gold`;
    };

    if (dishSelect) dishSelect.addEventListener('change', () => { playClick('down'); updateCalc(); });
    if (qtyInput) qtyInput.addEventListener('input', updateCalc);
    updateCalc();
  }

  initZundamonApp() {
    const moodBtns = document.querySelectorAll('.mood-btn');
    const dialogueText = document.getElementById('zunda-dialogue-text');
    const voiceBtn = document.getElementById('zunda-voice-btn');
    const compChips = document.querySelectorAll('.comp-chip');

    const moodQuotes = {
      happy: '"Morning, {player}! The garden is sparkling nanoda! Let us make one dish we are proud of today!"',
      cooking: '"Rhythm cooking time! Tap along to the beat to score S-Rank PERFECT dishes nanoda! 🍳"',
      sleeping: '"Zzz... fresh edamame mochi... so delicious nanoda... 💤"'
    };

    moodBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        playClick('down');
        moodBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const mood = btn.dataset.mood || 'happy';
        if (dialogueText && moodQuotes[mood]) {
          dialogueText.textContent = moodQuotes[mood];
        }
        if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('chirp');
      });
    });

    if (voiceBtn) {
      voiceBtn.addEventListener('click', () => {
        if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('nanoda_arpeggio');
      });
    }

    const compQuotes = {
      zundamon: '"I will stay close while you gather and cook nanoda! 🫛"',
      sakuradamon: '"Blossom petals drift on the breeze... Carries +25% bonus XP lessons for you! 🌸"',
      ankomon: '"Sweet red beans sweeten every payday! Serving guests grants +15% Gold! 🫘"',
      cardamon: '"A steady hand makes the finest dishes. +30% wider cooking windows! 🍋"',
      antimon: '"The forest whispers where rare ingredients slumber. +20% extra gather drops! 🌿"'
    };

    compChips.forEach(chip => {
      chip.addEventListener('click', () => {
        playClick('down');
        compChips.forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        const comp = chip.dataset.comp || 'zundamon';
        if (dialogueText && compQuotes[comp]) {
          dialogueText.textContent = compQuotes[comp];
        }
        if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('chirp');
      });
    });
  }

  initDesktopWidgets() {
    // 1. Clock Widget
    const widgetClock = document.getElementById('widget-clock');
    if (widgetClock) {
      const updateWidgetClock = () => {
        const now = new Date();
        widgetClock.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      };
      setInterval(updateWidgetClock, 1000);
      updateWidgetClock();
    }

    // 2. Interactive Zundamon Desktop Sticker Widget
    const stickerWidget = document.getElementById('zunda-sticker-widget');
    const bubbleTalk = document.getElementById('widget-speech-bubble');
    if (stickerWidget) {
      const quotes = [
        '"Welcome to Zunda-OS 95, nanoda! 🫛✨"',
        '"Have you cooked fresh Zunda Mochi today, nanoda? 🍡"',
        '"Tap ZundaCLI.exe to type commands, nanoda! 💻"',
        '"Sakura petals are drifting through the kitchen! 🌸"',
        '"Zundamon loves warm mochi draped in edamame paste! 💚"'
      ];
      let quoteIdx = 0;
      stickerWidget.addEventListener('click', () => {
        playClick('down');
        quoteIdx = (quoteIdx + 1) % quotes.length;
        if (bubbleTalk) bubbleTalk.textContent = quotes[quoteIdx];
        if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('chirp');
      });
    }

    // 3. Jukebox BGM Widget
    const widgetPlayBgm = document.getElementById('widget-play-bgm');
    if (widgetPlayBgm) {
      widgetPlayBgm.addEventListener('click', () => {
        playClick('down');
        if (typeof window.toggleCozyBGM === 'function') {
          const isPlaying = window.toggleCozyBGM();
          widgetPlayBgm.textContent = isPlaying ? '⏸ Pause BGM' : '▶ Play BGM';
          widgetPlayBgm.style.backgroundColor = isPlaying ? '#ff477e' : '';
          widgetPlayBgm.style.color = isPlaying ? '#ffffff' : '';
        }
      });
    }
  }

  initSystemTray() {
    const bgmToggle = document.getElementById('bgm-toggle');
    if (bgmToggle) {
      bgmToggle.addEventListener('click', () => {
        if (typeof window.toggleCozyBGM === 'function') {
          const isPlaying = window.toggleCozyBGM();
          bgmToggle.style.opacity = isPlaying ? '1.0' : '0.5';
        }
      });
    }

    const sfxToggle = document.getElementById('sfx-toggle');
    if (sfxToggle) {
      sfxToggle.addEventListener('click', () => {
        if (window.ZundaAudio) {
          const muted = window.ZundaAudio.toggleMute();
          sfxToggle.style.opacity = muted ? '0.4' : '1.0';
          const iconSpan = sfxToggle.querySelector('.tray-icon');
          if (iconSpan) iconSpan.textContent = muted ? '🔇' : '🔊';
        }
      });
    }
  }

  initParticleCanvas() {
    const canvas = document.getElementById('particle-canvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let particles = [];

    const resizeCanvas = () => {
      if (canvas.parentElement) {
        canvas.width = canvas.parentElement.clientWidth;
        canvas.height = canvas.parentElement.clientHeight;
      }
    };
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    class Particle {
      constructor() {
        this.reset();
      }

      reset() {
        this.x = Math.random() * (canvas.width || 800);
        this.y = (canvas.height || 600) + Math.random() * 50;
        this.size = Math.random() * 8 + 4;
        this.speedY = Math.random() * 1.2 + 0.4;
        this.speedX = Math.random() * 0.6 - 0.3;
        this.opacity = Math.random() * 0.5 + 0.2;
        this.rotation = Math.random() * Math.PI * 2;
        this.rotSpeed = (Math.random() - 0.5) * 0.02;
      }

      update() {
        this.y -= this.speedY;
        this.x += this.speedX;
        this.rotation += this.rotSpeed;
        if (this.y < -20) this.reset();
      }

      draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.rotation);
        ctx.globalAlpha = this.opacity;

        ctx.fillStyle = '#8bc34a';
        ctx.strokeStyle = '#2e7d32';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.ellipse(0, 0, this.size, this.size * 0.6, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();

        ctx.restore();
      }
    }

    for (let i = 0; i < 35; i++) {
      particles.push(new Particle());
    }

    const animateParticles = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach(p => {
        p.update();
        p.draw();
      });
      requestAnimationFrame(animateParticles);
    };
    animateParticles();
  }
}

// Global DOM Content Loaded Listener
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', () => {
    const app = new MainApp();
    app.init();
    window.mainApp = app;
  });
}

// Node.js module export & Browser attachment
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    RECIPES,
    CookbookApp,
    RhythmSimulator,
    VN_DIALOGUE_TREE,
    VNTalkApp,
    QuickStartApp,
    MainApp,
    playZundaVoiceLine
  };
}
if (typeof window !== 'undefined') {
  window.RECIPES = RECIPES;
  window.CookbookApp = CookbookApp;
  window.RhythmSimulator = RhythmSimulator;
  window.VN_DIALOGUE_TREE = VN_DIALOGUE_TREE;
  window.VNTalkApp = VNTalkApp;
  window.QuickStartApp = QuickStartApp;
  window.MainApp = MainApp;
  window.playZundaVoiceLine = playZundaVoiceLine;
}
