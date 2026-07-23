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
 * Delegates procedural Zundamon vocal chirps to audio_engine.js synthesizer.
 * @param {string} type 
 */
function playZundaVoiceLine(type = 'chirp') {
  if (typeof window !== 'undefined') {
    if (window.ZundaAudio && typeof window.ZundaAudio.playVoiceLine === 'function') {
      window.ZundaAudio.playVoiceLine(type);
    } else if (typeof window.playZundaVoiceLine === 'function' && window.playZundaVoiceLine !== playZundaVoiceLine) {
      window.playZundaVoiceLine(type);
    }
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
      window.windowManager.openWindow('window-updates');
    } else if (action === 'launch_roblox' && typeof window !== 'undefined') {
      window.open('https://www.roblox.com/games/102953611950557/Zundamons-Kitchen-V2-Electric-Boogaloo', '_blank');
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
        window.open('https://www.roblox.com/games/102953611950557/Zundamons-Kitchen-V2-Electric-Boogaloo', '_blank');
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
    document.querySelectorAll('.desktop-shortcut, .os-app-tile, [data-open-window]').forEach(shortcut => {
      const handleOpen = (e) => {
        // Avoid intercepting anchor links unless they target windows
        const targetId = shortcut.dataset.openWindow;
        if (!targetId) return;
        if (shortcut.tagName === 'A' && shortcut.getAttribute('href') && shortcut.getAttribute('href').startsWith('#') && !targetId) return;
        
        playClick('down');
        if (targetId && window.windowManager) {
          window.windowManager.openWindow(targetId);
        }
      };

      shortcut.addEventListener('click', handleOpen);
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
    const showToast = (message) => {
      const container = document.getElementById('toast-container');
      if (!container) return;
      const toast = document.createElement('div');
      toast.className = 'toast-message';
      toast.innerHTML = `<span class="toast-icon">📋</span><span>${message}</span>`;
      container.appendChild(toast);
      setTimeout(() => {
        toast.classList.add('fade-out');
        setTimeout(() => toast.remove(), 300);
      }, 3000);
    };

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
            showToast(`Code ${code} copied to clipboard! ✨`);
            setTimeout(() => {
              btn.textContent = originalText;
              btn.style.backgroundColor = '';
              btn.style.color = '';
            }, 2000);
          }).catch(() => {
            showToast(`Code: ${code}`);
          });
        } else if (code) {
          showToast(`Code: ${code}`);
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
    // 1. Digital Clock & Weather Widget
    const timeEl = document.getElementById('widget-digital-time') || document.getElementById('widget-clock');
    if (timeEl) {
      const updateClock = () => {
        const now = new Date();
        timeEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      };
      setInterval(updateClock, 1000);
      updateClock();
    }

    const weatherPill = document.getElementById('widget-weather-pill');
    const weatherIcon = document.getElementById('widget-weather-icon');
    const weatherText = document.getElementById('widget-weather-text');
    const weatherStates = [
      { icon: '🌤️', text: 'Zunda Village: 22°C Clear' },
      { icon: '🌸', text: 'Sakura Forest: 20°C Blossom Breeze' },
      { icon: '🌧️', text: 'Edamame Fields: 18°C Cozy Rain' },
      { icon: '🌙', text: 'Starry Heights: 16°C Clear Night' }
    ];
    let weatherIdx = 0;

    if (weatherPill) {
      weatherPill.addEventListener('click', () => {
        if (typeof playClick === 'function') playClick('down');
        weatherIdx = (weatherIdx + 1) % weatherStates.length;
        const state = weatherStates[weatherIdx];
        if (weatherIcon) weatherIcon.textContent = state.icon;
        if (weatherText) weatherText.textContent = state.text;
      });
    }

    // 2. Lo-Fi Jukebox & Rain FX Widget
    const widgetPlayBgm = document.getElementById('widget-play-bgm');
    const widgetNextTrack = document.getElementById('widget-next-track');
    const trackTitleEl = document.getElementById('jukebox-track-title');
    const discIconEl = document.getElementById('jukebox-disc-icon');
    const rainSlider = document.getElementById('rain-sfx-slider');

    if (widgetPlayBgm) {
      widgetPlayBgm.addEventListener('click', () => {
        if (typeof playClick === 'function') playClick('down');
        const audioEl = document.getElementById('zunda-mp3-player');
        if (audioEl) {
          if (audioEl.paused) {
            audioEl.play().then(() => {
              widgetPlayBgm.textContent = '⏸ Pause zunda.mp3';
              if (discIconEl) discIconEl.classList.add('spinning');
            }).catch(() => {
              // Fallback to Web Audio synthesis engine if MP3 file fails to play
              if (typeof window.toggleCozyBGM === 'function') {
                const isPlaying = window.toggleCozyBGM();
                widgetPlayBgm.textContent = isPlaying ? '⏸ Pause Synth BGM' : '▶ zunda.mp3';
                if (discIconEl) discIconEl.classList.toggle('spinning', isPlaying);
              }
            });
          } else {
            audioEl.pause();
            widgetPlayBgm.textContent = '▶ zunda.mp3';
            if (discIconEl) discIconEl.classList.remove('spinning');
          }
        } else if (typeof window.toggleCozyBGM === 'function') {
          const isPlaying = window.toggleCozyBGM();
          widgetPlayBgm.textContent = isPlaying ? '⏸ Pause BGM' : '▶ zunda.mp3';
          if (discIconEl) discIconEl.classList.toggle('spinning', isPlaying);
        }
      });
    }

    if (widgetNextTrack) {
      widgetNextTrack.addEventListener('click', () => {
        if (typeof playClick === 'function') playClick('down');
        if (window.ZundaAudio && typeof window.ZundaAudio.nextBGMTrack === 'function') {
          const trackName = window.ZundaAudio.nextBGMTrack();
          if (trackTitleEl) trackTitleEl.textContent = trackName;
        }
      });
    }

    if (rainSlider) {
      rainSlider.addEventListener('input', (e) => {
        const val = parseFloat(e.target.value);
        if (window.ZundaAudio && typeof window.ZundaAudio.setRainVolume === 'function') {
          window.ZundaAudio.setRainVolume(val);
        }
      });
    }

    // 3. Interactive Zundamon Desktop Sticker Widget
    const stickerWidget = document.getElementById('widget-zunda-sticker') || document.getElementById('zunda-sticker-widget');
    const bubbleTalk = document.getElementById('widget-speech-bubble');
    if (stickerWidget) {
      const quotes = [
        '"Welcome to Zunda-OS 95, nanoda! 🫛✨"',
        '"Have you cooked fresh Zunda Mochi today, nanoda? 🍡"',
        '"Tap ZundaCLI.exe to type commands, nanoda! 💻"',
        '"Sakura petals drift through the kitchen! 🌸"',
        '"Zundamon loves warm mochi draped in edamame paste! 💚"',
        '"Master rhythm targets for S-Rank rewards, nanoda! 🍳"'
      ];
      let quoteIdx = -1;
      let autoHideTimer = null;

      stickerWidget.addEventListener('click', () => {
        if (typeof playClick === 'function') playClick('down');
        if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('companion_click');

        quoteIdx = (quoteIdx + 1) % quotes.length;
        if (bubbleTalk) {
          bubbleTalk.textContent = quotes[quoteIdx];
          bubbleTalk.style.opacity = '1';
          bubbleTalk.style.transform = 'translateX(-50%) translateY(0)';

          if (autoHideTimer) clearTimeout(autoHideTimer);
          autoHideTimer = setTimeout(() => {
            bubbleTalk.style.opacity = '0.9';
          }, 5000);
        }
      });
    }
  }

  initSystemTray() {
    const jukeboxBtn = document.getElementById('taskbar-jukebox-btn') || document.getElementById('bgm-toggle');
    if (jukeboxBtn) {
      jukeboxBtn.addEventListener('click', () => {
        playClick('down');
        const audioEl = document.getElementById('zunda-mp3-player');
        if (audioEl) {
          if (audioEl.paused) {
            audioEl.play().catch(() => {
              if (typeof window.toggleCozyBGM === 'function') window.toggleCozyBGM();
            });
          } else {
            audioEl.pause();
          }
        } else if (typeof window.toggleCozyBGM === 'function') {
          window.toggleCozyBGM();
        }
      });
    }

    const clockWeatherPill = document.getElementById('taskbar-clock-weather');
    if (clockWeatherPill) {
      const weatherText = document.getElementById('taskbar-weather');
      const weatherStates = [
        '🌤️ 22°C',
        '🌸 20°C',
        '🌧️ 18°C',
        '🌙 16°C'
      ];
      let idx = 0;
      clockWeatherPill.addEventListener('click', () => {
        playClick('down');
        idx = (idx + 1) % weatherStates.length;
        if (weatherText) weatherText.textContent = weatherStates[idx];
      });
    }
  }

  initParticleCanvas() {
    const canvas = document.getElementById('star-canvas') || document.getElementById('star-sparkle-canvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let particles = [];

    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    const starColors = ['#ff85a1', '#ffb7c5', '#a5d6a7', '#ffffe0', '#e8dff5'];

    class SparkleStar {
      constructor() {
        this.reset();
      }

      reset() {
        this.x = Math.random() * (canvas.width || 1200);
        this.y = Math.random() * (canvas.height || 800);
        this.size = Math.random() * 5 + 2;
        this.speedY = -(Math.random() * 0.4 + 0.1);
        this.opacity = Math.random() * 0.6 + 0.2;
        this.color = starColors[Math.floor(Math.random() * starColors.length)];
        this.pulse = Math.random() * Math.PI;
      }

      update() {
        this.y += this.speedY;
        this.pulse += 0.03;
        this.currentOpacity = this.opacity * (0.6 + Math.sin(this.pulse) * 0.4);
        if (this.y < -10) this.reset();
      }

      draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.globalAlpha = Math.max(0, this.currentOpacity);

        // Draw cute 4-point sparkle star
        ctx.fillStyle = this.color;
        ctx.beginPath();
        for (let i = 0; i < 4; i++) {
          ctx.lineTo(Math.cos(i * Math.PI / 2) * this.size, Math.sin(i * Math.PI / 2) * this.size);
          ctx.lineTo(Math.cos((i + 0.5) * Math.PI / 2) * (this.size * 0.3), Math.sin((i + 0.5) * Math.PI / 2) * (this.size * 0.3));
        }
        ctx.closePath();
        ctx.fill();

        ctx.restore();
      }
    }

    for (let i = 0; i < 40; i++) {
      particles.push(new SparkleStar());
    }

    // Y2K Interactive Mouse & Scroll Parallax Controller
    const heroCard = document.querySelector('.hero-card-preview');
    const heroTitle = document.querySelector('.hero-title');
    const heroAvatar = document.querySelector('.hero-zunda-svg');

    window.addEventListener('mousemove', (e) => {
      const mouseX = (e.clientX / window.innerWidth - 0.5) * 30;
      const mouseY = (e.clientY / window.innerHeight - 0.5) * 30;

      if (heroCard) heroCard.style.transform = `translate3d(${mouseX * 0.8}px, ${mouseY * 0.8}px, 0) rotate3d(1, 1, 0, ${(mouseX - mouseY) * 0.15}deg)`;
      if (heroTitle) heroTitle.style.transform = `translate3d(${mouseX * 0.3}px, ${mouseY * 0.3}px, 0)`;
      if (heroAvatar) heroAvatar.style.transform = `translate3d(${-mouseX * 0.5}px, ${-mouseY * 0.5}px, 0) scale(1.05)`;
    });

    window.addEventListener('scroll', () => {
      const scrollY = window.scrollY;
      if (heroCard) heroCard.style.transform = `translate3d(0, ${scrollY * 0.15}px, 0)`;
    });

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
