# CSS Styling & Visual Blueprint Specification (`site/style.css`)
**Milestone 3 — ZundaCLI.exe, Promos.app, Calculator.app, Updates.log**
*Working Directory*: `g:\Zundamons-kItchen-V2\.agents\explorer_m3_3`  
*Author*: Explorer 3 (Visual Design & CSS Architecture Specialist)

---

## Executive Summary
This document specifies the complete CSS styling blueprint for `site/style.css` covering **ZundaCLI.exe** (Pastel Console Prompt), **Promos.app** (Code Redeemer), **Calculator.app** (Dish Profit Crafter), and **Updates.log** (Patch & ECS Log). It establishes design system integration with the **Y2K Kawaii & CRT Phosphor Design Language** (`--term-bg: #231b2e`, `--term-pink: #f472b6`, `--term-cyan: #38bdf8`, `--term-yellow: #fef08a`, `--sakura-base`, `--zunda-base`).

---

## 1. Pastel Terminal Styling Specification (`ZundaCLI.exe`)

### 1.1 Container & Layout Architecture
The terminal uses a deep plum dark obsidian backdrop with high-contrast pastel neon accents and soft glow shadows.

- **Classes & Selectors**: `.terminal-window`, `#window-zundacli`, `.cli-body`
- **Background**: `var(--term-bg)` (`#231b2e`)
- **Typography**: `var(--font-mono)` (`'VT323', 'Cascadia Code', monospace`), `font-size: 14px`, `line-height: 1.5`
- **Border & Inset Shadow**:
  ```css
  .terminal-window, #window-zundacli .cli-body {
    background-color: var(--term-bg);
    color: var(--term-pink);
    font-family: var(--font-mono);
    font-size: 14px;
    line-height: 1.5;
    padding: 12px;
    box-shadow: inset 0 0 18px rgba(15, 10, 25, 0.95), inset 0 0 4px rgba(244, 114, 182, 0.3);
    border: 1px solid rgba(244, 114, 182, 0.3);
  }
  ```

### 1.2 Terminal Output Log & Scroll Area
- **Classes**: `.terminal-output`, `.cli-terminal-log`
- **Styling**:
  ```css
  .terminal-output, .cli-terminal-log {
    flex: 1;
    overflow-y: auto;
    padding: 8px;
    line-height: 1.5;
    word-break: break-word;
    text-shadow: 0 0 4px rgba(244, 114, 182, 0.4);
  }
  ```

### 1.3 Prompt & Input Line Formatting
- **Classes**: `.term-prompt`, `.cli-prompt-label`, `.term-input`, `.cli-input-field`, `.cli-prompt-line`
- **Styling**:
  ```css
  .cli-prompt-line {
    display: flex;
    align-items: center;
    gap: 6px;
    padding-top: 6px;
    border-top: 1px dashed rgba(244, 114, 182, 0.2);
  }

  .term-prompt, .cli-prompt-label {
    color: var(--term-cyan);
    font-weight: bold;
    font-family: var(--font-mono);
    font-size: 14px;
    text-shadow: 0 0 6px rgba(56, 189, 248, 0.6);
    user-select: none;
  }

  .term-input, .cli-input-field {
    flex: 1;
    background: transparent;
    border: none;
    outline: none;
    color: var(--term-cyan);
    font-family: var(--font-mono);
    font-size: 14px;
    caret-color: var(--term-pink);
    text-shadow: 0 0 4px rgba(56, 189, 248, 0.5);
  }

  .term-input::placeholder, .cli-input-field::placeholder {
    color: rgba(244, 114, 182, 0.4);
    font-style: italic;
  }
  ```

### 1.4 Glowing Cursor Animation (`@keyframes blink`)
- **Keyframe Animation**:
  ```css
  @keyframes blink {
    0%, 49% {
      opacity: 1;
      box-shadow: 0 0 8px var(--term-pink);
    }
    50%, 100% {
      opacity: 0;
      box-shadow: none;
    }
  }

  .term-cursor, .cli-cursor {
    display: inline-block;
    width: 8px;
    height: 16px;
    background-color: var(--term-pink);
    vertical-align: middle;
    margin-left: 2px;
    animation: blink 1s infinite;
  }
  ```

### 1.5 Pastel Color Highlights Palette
The terminal output formatter supports 4 signature pastel accent utility classes:

| Class Selector | Hex Color | Role / Purpose | Text Shadow Glow |
|---|---|---|---|
| `.term-pink`, `.cli-pink` | `#f472b6` | Zunda Sakura Pink primary, echo labels, borders | `0 0 6px rgba(244,114,182,0.5)` |
| `.term-green`, `.cli-green` | `#8bc34a` | Fresh Edamame Green success tag, recipe status | `0 0 6px rgba(139,195,74,0.5)` |
| `.term-cyan`, `.cli-cyan` | `#38bdf8` | User commands, prompts, audio system notes | `0 0 6px rgba(56,189,248,0.5)` |
| `.term-yellow`, `.cli-yellow` | `#fef08a` | Highlight keywords, warnings, code parameters | `0 0 6px rgba(254,240,138,0.5)` |

```css
.term-pink, .cli-pink { color: var(--term-pink); text-shadow: 0 0 6px rgba(244, 114, 182, 0.5); }
.term-green, .cli-green { color: #8bc34a; text-shadow: 0 0 6px rgba(139, 195, 74, 0.5); }
.term-cyan, .cli-cyan { color: var(--term-cyan); text-shadow: 0 0 6px rgba(56, 189, 248, 0.5); }
.term-yellow, .cli-yellow { color: var(--term-yellow); text-shadow: 0 0 6px rgba(254, 240, 138, 0.5); }
```

### 1.6 Custom Pastel Terminal Webkit Scrollbar
```css
.cli-terminal-log::-webkit-scrollbar,
.terminal-output::-webkit-scrollbar {
  width: 8px;
}
.cli-terminal-log::-webkit-scrollbar-track,
.terminal-output::-webkit-scrollbar-track {
  background: #191222;
  border-left: 1px solid rgba(244, 114, 182, 0.2);
}
.cli-terminal-log::-webkit-scrollbar-thumb,
.terminal-output::-webkit-scrollbar-thumb {
  background: var(--term-pink);
  border-radius: 4px;
  box-shadow: 0 0 6px var(--term-pink);
}
.cli-terminal-log::-webkit-scrollbar-thumb:hover,
.terminal-output::-webkit-scrollbar-thumb:hover {
  background: var(--term-cyan);
  box-shadow: 0 0 8px var(--term-cyan);
}
```

---

## 2. Promos App Layout Specification (`Promos.app`)

### 2.1 Promo Redeemer Box Container
- **Classes**: `.promo-redeemer-box`, `#window-promos .promos-body`
- **Styling**:
  ```css
  .promo-redeemer-box, .promos-body {
    background: rgba(255, 255, 255, 0.95);
    border: 2px solid var(--sakura-base);
    border-radius: 20px;
    padding: 20px;
    box-shadow: var(--shadow-soft-pink);
    display: flex;
    flex-direction: column;
    gap: 14px;
  }
  ```

### 2.2 Promo Code Row Item Layout
- **Classes**: `.promo-code-item`, `.code-box`
- **Styling**:
  ```css
  .promo-code-item, .code-box {
    background: #ffffff;
    border: 2px dashed var(--zunda-soft);
    border-radius: 16px;
    padding: 14px 18px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    box-shadow: var(--shadow-soft-mint);
    transition: var(--transition-bounce);
  }

  .promo-code-item:hover, .code-box:hover {
    border-color: var(--zunda-base);
    transform: translateY(-2px);
    box-shadow: 0 8px 20px rgba(76, 175, 80, 0.25);
  }

  .promo-code-text {
    font-family: var(--font-mono);
    font-size: 18px;
    font-weight: 800;
    color: var(--zunda-deep);
    letter-spacing: 1px;
  }
  ```

### 2.3 Input Field Styling
- **Classes**: `.promo-input`, `.win95-input`
- **Styling**:
  ```css
  .promo-input, .win95-input {
    width: 100%;
    padding: 10px 16px;
    border: 2px solid var(--sakura-base);
    border-radius: 9999px;
    font-family: var(--font-mono);
    font-size: 14px;
    font-weight: 700;
    color: var(--zunda-deep);
    background: #ffffff;
    outline: none;
    transition: var(--transition-fast);
    box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.04);
  }

  .promo-input:focus, .win95-input:focus {
    border-color: var(--sakura-hot);
    box-shadow: 0 0 0 3px rgba(255, 71, 126, 0.25);
  }
  ```

### 2.4 Candy Redeem Button
- **Classes**: `.btn-candy`, `.promo-redeem-btn`
- **Styling**:
  ```css
  .promo-redeem-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 8px 18px;
    border-radius: 9999px;
    font-weight: 800;
    font-size: 13px;
    color: #ffffff !important;
    background: linear-gradient(180deg, var(--sakura-vibrant) 0%, var(--sakura-hot) 100%);
    border: 1px solid rgba(255, 255, 255, 0.8);
    box-shadow: var(--inset-gloss-top), var(--shadow-candy-button);
    cursor: pointer;
    transition: var(--transition-bounce);
    user-select: none;
  }

  .promo-redeem-btn:hover {
    transform: translateY(-2px) scale(1.04);
    box-shadow: var(--inset-gloss-top), 0 8px 24px rgba(255, 71, 126, 0.45);
  }
  ```

### 2.5 Success Badge
- **Classes**: `.promo-success-badge`, `.badge-success`
- **Styling**:
  ```css
  .promo-success-badge, .badge-success {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: var(--zunda-light);
    color: var(--zunda-deep);
    border: 1px solid var(--zunda-base);
    padding: 4px 12px;
    border-radius: 9999px;
    font-size: 12px;
    font-weight: 800;
    box-shadow: 0 2px 8px rgba(76, 175, 80, 0.2);
  }
  ```

---

## 3. Calculator Form Styling Specification (`Calculator.app`)

### 3.1 Form Container & Layout
- **Classes**: `.calc-form`, `.calc-body`, `.calc-form-group`
- **Styling**:
  ```css
  .calc-form, .calc-body {
    display: flex;
    flex-direction: column;
    gap: 14px;
    padding: 16px;
    background: linear-gradient(180deg, rgba(255, 245, 248, 0.95) 0%, rgba(255, 255, 255, 0.98) 100%);
  }

  .calc-form-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .calc-form-group label {
    font-size: 13px;
    font-weight: 800;
    color: var(--zunda-deep);
  }
  ```

### 3.2 Select Dropdown Styling
- **Classes**: `.calc-select`, `#calc-dish-select`
- **Styling**:
  ```css
  .calc-select, #calc-dish-select {
    appearance: none;
    -webkit-appearance: none;
    width: 100%;
    padding: 10px 36px 10px 14px;
    border: 2px solid var(--sakura-base);
    border-radius: 12px;
    background: #ffffff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%3E4caf50' d='M2 4l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 14px center;
    font-size: 13px;
    font-weight: 700;
    color: #1e293b;
    outline: none;
    cursor: pointer;
    transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  }

  .calc-select:focus, #calc-dish-select:focus {
    border-color: var(--sakura-hot);
    box-shadow: 0 0 0 3px rgba(255, 71, 126, 0.2);
  }
  ```

### 3.3 Numeric Input Styling
- **Classes**: `.calc-input`, `#calc-qty`
- **Styling**:
  ```css
  .calc-input, #calc-qty {
    width: 100%;
    padding: 10px 14px;
    border: 2px solid var(--sakura-base);
    border-radius: 12px;
    font-size: 14px;
    font-weight: 800;
    color: var(--zunda-deep);
    background: #ffffff;
    outline: none;
    transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  }

  .calc-input:focus, #calc-qty:focus {
    border-color: var(--sakura-hot);
    box-shadow: 0 0 0 3px rgba(255, 71, 126, 0.2);
  }
  ```

### 3.4 Profit Display Card Container
- **Classes**: `.profit-display-card`, `.calc-results`
- **Styling**:
  ```css
  .profit-display-card, .calc-results {
    background: #ffffff;
    border: 2px solid var(--zunda-soft);
    border-radius: 16px;
    padding: 16px;
    box-shadow: var(--shadow-soft-mint);
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-top: 6px;
  }

  .calc-result-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 13px;
    color: #475569;
    padding: 4px 0;
    border-bottom: 1px dashed rgba(165, 214, 167, 0.5);
  }

  .calc-result-row:last-child {
    border-bottom: none;
  }
  ```

### 3.5 Profit / Loss Color Highlights
- **Classes**: `.profit-positive`, `.profit-negative`, `#res-profit`
- **Styling**:
  ```css
  .profit-positive, #res-profit {
    color: var(--zunda-deep);
    background: var(--zunda-light);
    border: 1px solid var(--zunda-soft);
    padding: 3px 12px;
    border-radius: 9999px;
    font-weight: 800;
    font-size: 14px;
    text-shadow: 0 0 6px rgba(76, 175, 80, 0.3);
  }

  .profit-negative {
    color: #e11d48;
    background: #fff1f2;
    border: 1px solid #fecdd3;
    padding: 3px 12px;
    border-radius: 9999px;
    font-weight: 800;
    font-size: 14px;
  }
  ```

---

## 4. Updates Log Styling Specification (`Updates.log`)

### 4.1 Container & Body Layout
- **Classes**: `.updates-log-body`, `.updates-body`
- **Styling**:
  ```css
  .updates-log-body, .updates-body {
    padding: 20px;
    font-size: 14px;
    color: #334155;
    line-height: 1.7;
    background: linear-gradient(180deg, rgba(255, 245, 248, 0.95) 0%, rgba(255, 255, 255, 0.98) 100%);
  }
  ```

### 4.2 Patch Version Tag
- **Classes**: `.patch-version-tag`, `h3 .v-badge`
- **Styling**:
  ```css
  .patch-version-tag {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: linear-gradient(135deg, var(--sakura-hot) 0%, var(--lavender-deep) 100%);
    color: #ffffff;
    padding: 4px 14px;
    border-radius: 9999px;
    font-weight: 800;
    font-size: 12px;
    letter-spacing: 0.5px;
    box-shadow: 0 2px 8px rgba(255, 71, 126, 0.3);
  }
  ```

### 4.3 Patch Notes List
- **Classes**: `.patch-notes-list`, `.update-log-list`
- **Styling**:
  ```css
  .patch-notes-list, .update-log-list {
    list-style: none;
    padding-left: 0;
    margin: 16px 0;
  }

  .patch-notes-list li, .update-log-list li {
    position: relative;
    padding-left: 28px;
    margin-bottom: 12px;
    line-height: 1.6;
    font-size: 13.5px;
    transition: transform var(--transition-fast);
  }

  .patch-notes-list li::before, .update-log-list li::before {
    content: '🫛';
    position: absolute;
    left: 0;
    top: 1px;
    font-size: 14px;
  }

  .patch-notes-list li:hover, .update-log-list li:hover {
    transform: translateX(4px);
    color: var(--zunda-deep);
  }
  ```

### 4.4 Technical ECS Badge
- **Classes**: `.ecs-badge`
- **Styling**:
  ```css
  .ecs-badge {
    display: inline-block;
    background: rgba(56, 189, 248, 0.15);
    color: #0284c7;
    border: 1px solid #38bdf8;
    padding: 2px 8px;
    border-radius: 6px;
    font-family: var(--font-mono);
    font-weight: 700;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-right: 6px;
  }
  ```

---

## 5. Verification & Testing Matrix

| Component | Target Selectors | Expected Visual Result | Verification Method |
|---|---|---|---|
| ZundaCLI.exe | `.terminal-window`, `.cli-body`, `.term-input`, `.term-prompt` | Dark plum obsidian CRT prompt with cyan prompt, glowing cursor animation, webkit scrollbar | Inspect element styles in browser dev tools |
| Promos.app | `.promo-redeemer-box`, `.promo-code-item`, `.promo-input`, `.promo-redeem-btn` | Glassmorphic card, dashed code rows, pink candy redeem button, green success badge | Hover & click promo copy button |
| Calculator.app | `.calc-form`, `.calc-select`, `.calc-input`, `.profit-display-card`, `.profit-positive` | Clean rounded dropdown & quantity input, soft mint profit card, glowing green `+Gold` badge | Select dish & alter quantity |
| Updates.log | `.updates-log-body`, `.patch-version-tag`, `.patch-notes-list`, `.ecs-badge` | Gradient version tag, edamame bullet points, blue ECS technical badge | Open window-updates & view log list |

