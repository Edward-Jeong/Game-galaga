const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

const scoreEl = document.getElementById("score");
const waveEl = document.getElementById("wave");
const livesEl = document.getElementById("lives");
const bestEl = document.getElementById("best");
const overlay = document.getElementById("overlay");
const overlayText = document.getElementById("overlayText");
const startButton = document.getElementById("startButton");

const W = canvas.width;
const H = canvas.height;
const keys = new Set();
const touchKeys = new Set();
let touchTarget = null;
const stars = Array.from({ length: 130 }, () => ({
  x: Math.random() * W,
  y: Math.random() * H,
  r: Math.random() * 1.8 + 0.4,
  s: Math.random() * 0.9 + 0.25
}));

let state = "ready";
let score = 0;
let best = Number(localStorage.getItem("galagaBest") || 0);
let lives = 3;
let wave = 1;
let player = null;
let bullets = [];
let enemyBullets = [];
let powerups = [];
let enemies = [];
let particles = [];
let lastShot = 0;
let lastTime = 0;
let diveTimer = 0;
let shotLevel = 1;
let audioCtx = null;
let masterGain = null;

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const pad = (value) => String(value).padStart(6, "0");

function initAudio() {
  if (audioCtx) {
    if (audioCtx.state === "suspended") audioCtx.resume();
    return;
  }
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return;
  audioCtx = new AudioContext();
  masterGain = audioCtx.createGain();
  masterGain.gain.value = 0.16;
  masterGain.connect(audioCtx.destination);
}

function tone({ type = "square", frequency = 440, endFrequency = frequency, duration = 0.12, gain = 0.5 }) {
  if (!audioCtx || !masterGain) return;
  const now = audioCtx.currentTime;
  const osc = audioCtx.createOscillator();
  const amp = audioCtx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(frequency, now);
  osc.frequency.exponentialRampToValueAtTime(Math.max(20, endFrequency), now + duration);
  amp.gain.setValueAtTime(gain, now);
  amp.gain.exponentialRampToValueAtTime(0.001, now + duration);
  osc.connect(amp);
  amp.connect(masterGain);
  osc.start(now);
  osc.stop(now + duration + 0.02);
}

function noise(duration = 0.18, gain = 0.42) {
  if (!audioCtx || !masterGain) return;
  const length = Math.max(1, Math.floor(audioCtx.sampleRate * duration));
  const buffer = audioCtx.createBuffer(1, length, audioCtx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) data[i] = Math.random() * 2 - 1;

  const source = audioCtx.createBufferSource();
  const filter = audioCtx.createBiquadFilter();
  const amp = audioCtx.createGain();
  source.buffer = buffer;
  filter.type = "lowpass";
  filter.frequency.value = 900;
  amp.gain.setValueAtTime(gain, audioCtx.currentTime);
  amp.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);
  source.connect(filter);
  filter.connect(amp);
  amp.connect(masterGain);
  source.start();
}

const sounds = {
  shoot() {
    tone({ frequency: 880, endFrequency: 1320, duration: 0.07, gain: 0.35 });
  },
  enemyHit() {
    tone({ type: "triangle", frequency: 420, endFrequency: 160, duration: 0.09, gain: 0.32 });
  },
  explode() {
    noise(0.18, 0.5);
    tone({ type: "sawtooth", frequency: 180, endFrequency: 55, duration: 0.18, gain: 0.22 });
  },
  playerHit() {
    noise(0.28, 0.62);
    tone({ type: "sawtooth", frequency: 150, endFrequency: 38, duration: 0.34, gain: 0.34 });
  },
  powerup() {
    tone({ type: "triangle", frequency: 660, endFrequency: 1320, duration: 0.12, gain: 0.34 });
    window.setTimeout(() => tone({ type: "triangle", frequency: 880, endFrequency: 1760, duration: 0.12, gain: 0.28 }), 90);
  },
  wave() {
    tone({ type: "triangle", frequency: 330, endFrequency: 660, duration: 0.16, gain: 0.22 });
    window.setTimeout(() => tone({ type: "triangle", frequency: 494, endFrequency: 988, duration: 0.16, gain: 0.2 }), 110);
  }
};

function resetGame() {
  score = 0;
  lives = 3;
  wave = 1;
  player = { x: W / 2, y: H - 72, w: 42, h: 44, invincible: 0 };
  bullets = [];
  enemyBullets = [];
  powerups = [];
  particles = [];
  shotLevel = 1;
  spawnWave();
  setState("playing");
  updateHud();
}

function spawnWave() {
  enemies = [];
  const rows = 4 + Math.min(2, Math.floor((wave - 1) / 2));
  const cols = 10;
  const startX = W / 2 - ((cols - 1) * 62) / 2;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      enemies.push({
        x: startX + col * 62,
        y: 86 + row * 48,
        baseX: startX + col * 62,
        baseY: 86 + row * 48,
        row,
        phase: Math.random() * Math.PI * 2,
        hp: row === 0 ? 2 : 1,
        diving: false,
        diveT: 0,
        dead: false
      });
    }
  }
  sounds.wave();
}

function setState(next) {
  state = next;
  overlay.classList.toggle("hidden", next === "playing");
  if (next === "ready") overlayText.textContent = "Start를 터치하거나 Enter로 시작";
  if (next === "paused") overlayText.textContent = "일시정지";
  if (next === "over") overlayText.textContent = "Game Over";
}

function updateHud() {
  scoreEl.textContent = pad(score);
  bestEl.textContent = pad(best);
  waveEl.textContent = wave;
  livesEl.textContent = "♥".repeat(Math.max(0, lives));
}

function drawStars(dt) {
  ctx.fillStyle = "#04050a";
  ctx.fillRect(0, 0, W, H);
  for (const star of stars) {
    star.y += star.s * dt * 0.06;
    if (star.y > H) {
      star.x = Math.random() * W;
      star.y = -4;
    }
    ctx.globalAlpha = 0.35 + star.s * 0.35;
    ctx.fillStyle = "#dbe9ff";
    ctx.fillRect(star.x, star.y, star.r, star.r);
  }
  ctx.globalAlpha = 1;
}

function drawPlayer() {
  if (player.invincible > 0 && Math.floor(player.invincible / 90) % 2 === 0) return;
  ctx.save();
  ctx.translate(player.x, player.y);
  ctx.fillStyle = "#57d4ff";
  ctx.beginPath();
  ctx.moveTo(0, -28);
  ctx.lineTo(22, 22);
  ctx.lineTo(6, 14);
  ctx.lineTo(0, 28);
  ctx.lineTo(-6, 14);
  ctx.lineTo(-22, 22);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = "#f2f6ff";
  ctx.fillRect(-5, -8, 10, 18);
  ctx.fillStyle = "#ff4f75";
  ctx.fillRect(-17, 18, 10, 7);
  ctx.fillRect(7, 18, 10, 7);
  ctx.restore();
}

function drawEnemy(enemy) {
  ctx.save();
  ctx.translate(enemy.x, enemy.y);
  const body = enemy.row === 0 ? "#ff4f75" : enemy.row === 1 ? "#ffd35a" : "#7af0a6";
  ctx.fillStyle = body;
  ctx.fillRect(-17, -11, 34, 22);
  ctx.fillRect(-25, -2, 9, 16);
  ctx.fillRect(16, -2, 9, 16);
  ctx.fillStyle = "#04050a";
  ctx.fillRect(-8, -4, 5, 5);
  ctx.fillRect(3, -4, 5, 5);
  ctx.fillStyle = "#f2f6ff";
  ctx.fillRect(-11, 12, 22, 5);
  ctx.restore();
}

function shoot(now) {
  if (now - lastShot < 180) return;
  const spreads = shotLevel === 1 ? [0] : shotLevel === 2 ? [-9, 9] : [-16, 0, 16];
  for (const offset of spreads) {
    bullets.push({ x: player.x + offset, y: player.y - 32, vy: -720, vx: offset * 3.6 });
  }
  lastShot = now;
  sounds.shoot();
}

function fireEnemy(enemy) {
  enemyBullets.push({ x: enemy.x, y: enemy.y + 16, vy: 230 + wave * 18 });
}

function explode(x, y, color, count = 16) {
  for (let i = 0; i < count; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = Math.random() * 210 + 70;
    particles.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: Math.random() * 420 + 220,
      color
    });
  }
}

function maybeDropPowerup(enemy) {
  const chance = enemy.row === 0 ? 0.34 : 0.18;
  if (Math.random() > chance) return;
  powerups.push({
    x: enemy.x,
    y: enemy.y,
    vy: 92,
    phase: Math.random() * Math.PI * 2
  });
}

function rectHit(a, b, aw, ah, bw, bh) {
  return Math.abs(a.x - b.x) < (aw + bw) / 2 && Math.abs(a.y - b.y) < (ah + bh) / 2;
}

function pressed(key) {
  return keys.has(key) || touchKeys.has(key);
}

function updatePlaying(dt, now) {
  const moveX = (pressed("arrowright") || pressed("d") ? 1 : 0) - (pressed("arrowleft") || pressed("a") ? 1 : 0);
  const moveY = (pressed("arrowdown") || pressed("s") ? 1 : 0) - (pressed("arrowup") || pressed("w") ? 1 : 0);
  if (touchTarget) {
    player.x += (touchTarget.x - player.x) * Math.min(1, dt * 9);
    player.y += (touchTarget.y - player.y) * Math.min(1, dt * 9);
  }
  player.x = clamp(player.x + moveX * 430 * dt, 34, W - 34);
  player.y = clamp(player.y + moveY * 360 * dt, H * 0.42, H - 38);
  player.invincible = Math.max(0, player.invincible - dt * 1000);
  if (pressed(" ")) shoot(now);

  for (const bullet of bullets) {
    bullet.x += (bullet.vx || 0) * dt;
    bullet.y += bullet.vy * dt;
  }
  bullets = bullets.filter((bullet) => bullet.y > -20);

  for (const bullet of enemyBullets) bullet.y += bullet.vy * dt;
  enemyBullets = enemyBullets.filter((bullet) => bullet.y < H + 30);

  for (const powerup of powerups) {
    powerup.y += powerup.vy * dt;
    powerup.x += Math.sin(now * 0.006 + powerup.phase) * 30 * dt;
  }
  powerups = powerups.filter((powerup) => powerup.y < H + 24);

  diveTimer -= dt;
  if (diveTimer <= 0 && enemies.length) {
    const candidate = enemies[Math.floor(Math.random() * enemies.length)];
    candidate.diving = true;
    candidate.diveT = 0;
    diveTimer = Math.max(0.75, 2.15 - wave * 0.12);
  }

  const fleetShift = Math.sin(now * 0.0012) * (34 + wave * 4);
  for (const enemy of enemies) {
    if (enemy.diving) {
      enemy.diveT += dt;
      enemy.x += Math.sin(enemy.diveT * 8 + enemy.phase) * 150 * dt;
      enemy.y += (160 + wave * 28) * dt;
      if (Math.random() < 0.005 + wave * 0.0015) fireEnemy(enemy);
      if (enemy.y > H + 40) {
        enemy.diving = false;
        enemy.y = enemy.baseY;
      }
    } else {
      enemy.x = enemy.baseX + fleetShift + Math.sin(now * 0.003 + enemy.phase) * 8;
      enemy.y = enemy.baseY + Math.sin(now * 0.002 + enemy.phase) * 6;
      if (Math.random() < 0.0009 + wave * 0.00025) fireEnemy(enemy);
    }
  }

  for (const bullet of bullets) {
    for (const enemy of enemies) {
      if (!enemy.dead && rectHit(bullet, enemy, 6, 18, 38, 28)) {
        bullet.y = -100;
        enemy.hp -= 1;
        sounds.enemyHit();
        explode(enemy.x, enemy.y, enemy.row === 0 ? "#ff4f75" : "#ffd35a", 8);
        if (enemy.hp <= 0) {
          enemy.dead = true;
          score += enemy.row === 0 ? 240 : 100;
          maybeDropPowerup(enemy);
          sounds.explode();
          explode(enemy.x, enemy.y, "#57d4ff", 18);
        }
        break;
      }
    }
  }
  enemies = enemies.filter((enemy) => !enemy.dead);

  for (const powerup of powerups) {
    if (!powerup.collected && rectHit(powerup, player, 28, 28, player.w, player.h)) {
      powerup.collected = true;
      shotLevel = Math.min(3, shotLevel + 1);
      score += 150;
      sounds.powerup();
      explode(powerup.x, powerup.y, "#ffd35a", 14);
    }
  }
  powerups = powerups.filter((powerup) => !powerup.collected);

  if (player.invincible <= 0) {
    const hitByBullet = enemyBullets.some((bullet) => rectHit(bullet, player, 7, 16, player.w, player.h));
    const hitByEnemy = enemies.some((enemy) => rectHit(enemy, player, 38, 28, player.w, player.h));
    if (hitByBullet || hitByEnemy) {
      lives -= 1;
      shotLevel = Math.max(1, shotLevel - 1);
      player.invincible = 1600;
      enemyBullets = [];
      sounds.playerHit();
      explode(player.x, player.y, "#ff4f75", 28);
      if (lives <= 0) {
        best = Math.max(best, score);
        localStorage.setItem("galagaBest", best);
        setState("over");
      }
    }
  }

  if (!enemies.length) {
    wave += 1;
    enemyBullets = [];
    spawnWave();
  }

  updateHud();
}

function updateParticles(dt) {
  for (const particle of particles) {
    particle.x += particle.vx * dt;
    particle.y += particle.vy * dt;
    particle.vy += 180 * dt;
    particle.life -= dt * 1000;
  }
  particles = particles.filter((particle) => particle.life > 0);
}

function drawBullets() {
  ctx.fillStyle = "#f2f6ff";
  for (const bullet of bullets) ctx.fillRect(bullet.x - 2, bullet.y - 11, 4, 18);
  ctx.fillStyle = "#ff4f75";
  for (const bullet of enemyBullets) ctx.fillRect(bullet.x - 3, bullet.y - 4, 6, 14);
}

function drawPowerups(now) {
  for (const powerup of powerups) {
    const pulse = Math.sin(now * 0.008 + powerup.phase) * 2;
    ctx.save();
    ctx.translate(powerup.x, powerup.y);
    ctx.fillStyle = "#ffd35a";
    ctx.fillRect(-12 - pulse, -12 - pulse, 24 + pulse * 2, 24 + pulse * 2);
    ctx.fillStyle = "#04050a";
    ctx.fillRect(-7, -3, 14, 6);
    ctx.fillStyle = "#ff4f75";
    ctx.fillRect(-3, -7, 6, 14);
    ctx.restore();
  }
}

function drawParticles() {
  for (const particle of particles) {
    ctx.globalAlpha = clamp(particle.life / 420, 0, 1);
    ctx.fillStyle = particle.color;
    ctx.fillRect(particle.x - 2, particle.y - 2, 4, 4);
  }
  ctx.globalAlpha = 1;
}

function loop(now = 0) {
  const dt = Math.min(0.033, (now - lastTime) / 1000 || 0);
  lastTime = now;
  drawStars(dt * 1000);
  if (state === "playing") updatePlaying(dt, now);
  updateParticles(dt);
  drawBullets();
  drawPowerups(now);
  for (const enemy of enemies || []) drawEnemy(enemy);
  if (player) drawPlayer();
  drawParticles();
  requestAnimationFrame(loop);
}

function startOrResume() {
  initAudio();
  if (state === "playing") return;
  if (state === "paused") {
    setState("playing");
    return;
  }
  resetGame();
}

function togglePause() {
  if (state === "playing") setState("paused");
  else if (state === "paused") setState("playing");
}

window.addEventListener("keydown", (event) => {
  const key = event.key.toLowerCase();
  if ([" ", "arrowleft", "arrowright", "arrowup", "arrowdown"].includes(key)) event.preventDefault();
  keys.add(key);
  if (key === "enter" || (key === " " && state !== "playing")) startOrResume();
  if (key === "p") togglePause();
});

window.addEventListener("keyup", (event) => {
  keys.delete(event.key.toLowerCase());
});

startButton.addEventListener("click", startOrResume);

document.querySelectorAll("[data-control]").forEach((button) => {
  const control = button.dataset.control;
  const press = (event) => {
    event.preventDefault();
    if (control === " " && state !== "playing") startOrResume();
    touchKeys.add(control);
    button.classList.add("active");
    button.setPointerCapture?.(event.pointerId);
  };
  const release = (event) => {
    event.preventDefault();
    touchKeys.delete(control);
    button.classList.remove("active");
  };
  button.addEventListener("pointerdown", press);
  button.addEventListener("pointerup", release);
  button.addEventListener("pointercancel", release);
  button.addEventListener("lostpointercapture", () => {
    touchKeys.delete(control);
    button.classList.remove("active");
  });
});

document.querySelector("[data-action='pause']").addEventListener("click", (event) => {
  event.preventDefault();
  togglePause();
});

function canvasPoint(event) {
  const rect = canvas.getBoundingClientRect();
  return {
    x: ((event.clientX - rect.left) / rect.width) * W,
    y: ((event.clientY - rect.top) / rect.height) * H
  };
}

canvas.addEventListener("pointerdown", (event) => {
  event.preventDefault();
  if (state !== "playing") {
    startOrResume();
    return;
  }
  touchTarget = canvasPoint(event);
  touchKeys.add(" ");
  canvas.setPointerCapture?.(event.pointerId);
});

canvas.addEventListener("pointermove", (event) => {
  if (state !== "playing" || !touchTarget) return;
  event.preventDefault();
  touchTarget = canvasPoint(event);
});

function endCanvasTouch(event) {
  event.preventDefault();
  touchTarget = null;
  touchKeys.delete(" ");
}

canvas.addEventListener("pointerup", endCanvasTouch);
canvas.addEventListener("pointercancel", endCanvasTouch);
canvas.addEventListener("lostpointercapture", () => {
  touchTarget = null;
  touchKeys.delete(" ");
});

bestEl.textContent = pad(best);
loop();
