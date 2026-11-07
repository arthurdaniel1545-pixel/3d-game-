import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const app = document.getElementById('app')!;
const loading = document.getElementById('loading')!;

// Renderer
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
app.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x87a8c8);
scene.fog = new THREE.Fog(0x87a8c8, 40, 120);

const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.1, 300);
camera.position.set(0, 10, 15);

// Lights
const hemi = new THREE.HemisphereLight(0xbfdfff, 0x445533, 0.6);
scene.add(hemi);
const sun = new THREE.DirectionalLight(0xfff2cc, 1.2);
sun.position.set(50, 80, 30);
sun.castShadow = true;
sun.shadow.mapSize.set(1024, 1024);
sun.shadow.camera.left = -60; sun.shadow.camera.right = 60;
sun.shadow.camera.top = 60; sun.shadow.camera.bottom = -60;
sun.shadow.camera.near = 1; sun.shadow.camera.far = 200;
scene.add(sun);

// Ground
const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(200, 200, 40, 40),
  new THREE.MeshStandardMaterial({ color: 0x3a5a2a, roughness: 0.9 })
);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

// Grid for reference
const grid = new THREE.GridHelper(200, 40, 0x556644, 0x334422);
scene.add(grid);

// Player
const player = new THREE.Group();
const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.4, 1.2, 8, 16), new THREE.MeshStandardMaterial({ color: 0x4466aa }));
body.position.y = 0.8;
body.castShadow = true;
player.add(body);
player.position.set(0, 0, 0);
scene.add(player);

// Colliders
const colliders: THREE.Box3[] = [];
function addCollider(b: THREE.Box3){ colliders.push(b); }

// Simple building boxes
const buildings: THREE.Mesh[] = [];
function makeBuilding(x:number,z:number,w:number,h:number,d:number,color:number){
  const m = new THREE.Mesh(new THREE.BoxGeometry(w,h,d), new THREE.MeshStandardMaterial({color}));
  m.position.set(x,h/2,z);
  m.castShadow=true; m.receiveShadow=true;
  scene.add(m);
  buildings.push(m);
  const b=new THREE.Box3().setFromObject(m);
  addCollider(b);
  return m;
}
makeBuilding(8,8,6,4,6,0x887766);
makeBuilding(-10,5,5,3,5,0x776655);
makeBuilding(12,-6,4,5,4,0x665544);

// Load assets
const loader = new GLTFLoader();
function loadGLB(url:string, pos:THREE.Vector3, scale=1){
  loader.load(url, (gltf)=>{
    const root = gltf.scene;
    root.position.copy(pos);
    root.scale.setScalar(scale);
    root.traverse((o:any)=>{ if(o.isMesh){ o.castShadow=true; o.receiveShadow=true; }});
    scene.add(root);
  }, undefined, (e)=>console.warn('load err', url, e));
}

// Trees from 3dassets
loadGLB('https://cdn.3dassets.dev/assets/27427/v1/model.glb', new THREE.Vector3(5,0,5),1);
loadGLB('https://cdn.3dassets.dev/assets/27426/v1/model.glb', new THREE.Vector3(-6,0,-4),1);
loadGLB('https://cdn.3dassets.dev/assets/27431/v1/model.glb', new THREE.Vector3(15,0,12),1);

// Enemy (zombie) - use a box placeholder + try load model
const enemy = new THREE.Group();
const enemyBody = new THREE.Mesh(new THREE.CapsuleGeometry(0.4,1.2,8,16), new THREE.MeshStandardMaterial({color:0x557733}));
enemyBody.position.y=0.8; enemyBody.castShadow=true;
enemy.add(enemyBody);
enemy.position.set(12,0,8);
scene.add(enemy);

// Try load a zombie model to replace
loader.load('https://cdn.3dassets.dev/assets/12013/v1/model.glb', (gltf)=>{
  // infected rat small; scale up as placeholder creature
  const r = gltf.scene;
  r.scale.setScalar(4);
  r.position.y=0;
  enemy.clear();
  enemy.add(r);
  r.traverse((o:any)=>{ if(o.isMesh){o.castShadow=true;o.receiveShadow=true;}});
}, undefined, ()=>{});

// Controls state
const keys: Record<string,boolean> = {};
window.addEventListener('keydown', e=>{ keys[e.code]=true; });
window.addEventListener('keyup', e=>{ keys[e.code]=false; });

// Mouse camera (pointer lock)
let yaw = 0, pitch = 0;
const sens = 0.002;
document.addEventListener('click', ()=>{ renderer.domElement.requestPointerLock(); });
document.addEventListener('mousemove', (e)=>{
  if(document.pointerLockElement===renderer.domElement){
    yaw -= e.movementX*sens;
    pitch -= e.movementY*sens;
    pitch = Math.max(-1.2, Math.min(1.2, pitch));
  }
});

// Touch controls
let touchMove = {x:0,y:0};
let touchLook = {x:0,y:0};
const joyBase = document.createElement('div');
joyBase.style.cssText='position:fixed;left:20px;bottom:20px;width:120px;height:120px;border-radius:60px;background:rgba(255,255,255,0.15);z-index:15;touch-action:none;';
document.body.appendChild(joyBase);
const joyKnob = document.createElement('div');
joyKnob.style.cssText='position:absolute;left:40px;top:40px;width:40px;height:40px;border-radius:20px;background:rgba(255,255,255,0.4);';
joyBase.appendChild(joyKnob);

let activeJoyId: number | null = null;
let joyStart = {x:0,y:0};
joyBase.addEventListener('pointerdown', (e)=>{
  activeJoyId=e.pointerId; joyBase.setPointerCapture(e.pointerId);
  joyStart={x:e.clientX,y:e.clientY};
});
joyBase.addEventListener('pointermove', (e)=>{
  if(activeJoyId!==e.pointerId) return;
  const dx=e.clientX-joyStart.x, dy=e.clientY-joyStart.y;
  const len=Math.hypot(dx,dy); const max=50;
  const cx = len>max? dx/len*max : dx;
  const cy = len>max? dy/len*max : dy;
  joyKnob.style.transform=`translate(${cx}px,${cy}px)`;
  touchMove.x = cx/max; touchMove.y = cy/max;
});
joyBase.addEventListener('pointerup', (e)=>{ if(activeJoyId===e.pointerId){activeJoyId=null; touchMove.x=0;touchMove.y=0; joyKnob.style.transform='translate(0,0)';} });

// Look area (right half of screen)
let activeLookId: number|null = null;
let lookStart={x:0,y:0};
window.addEventListener('pointerdown', (e)=>{
  if(e.clientX > window.innerWidth/2){ activeLookId=e.pointerId; lookStart={x:e.clientX,y:e.clientY}; }
});
window.addEventListener('pointermove', (e)=>{
  if(activeLookId===e.pointerId){
    const dx=e.clientX-lookStart.x, dy=e.clientY-lookStart.y;
    yaw -= dx*0.005; pitch -= dy*0.005; pitch=Math.max(-1.2,Math.min(1.2,pitch));
    lookStart={x:e.clientX,y:e.clientY};
  }
});
window.addEventListener('pointerup', (e)=>{ if(activeLookId===e.pointerId) activeLookId=null; });

// Jump button
const jumpBtn = document.createElement('button');
jumpBtn.textContent='JUMP';
jumpBtn.style.cssText='position:fixed;right:20px;bottom:20px;padding:14px 18px;font-size:16px;z-index:15;touch-action:none;';
document.body.appendChild(jumpBtn);
let jumpPressed=false;
jumpBtn.addEventListener('pointerdown', ()=>{ jumpPressed=true; });

// HUD
const hud = document.getElementById('hud')!;
hud.innerHTML = `
<div style="position:absolute;left:10px;top:10px;background:rgba(0,0,0,0.5);padding:8px 12px;border-radius:8px;font-size:14px;">
HP: <span id="hp">100</span> | Hunger: <span id="hunger">100</span> | Thirst: <span id="thirst">100</span>
</div>
<div style="position:absolute;left:10px;bottom:160px;background:rgba(0,0,0,0.5);padding:8px 12px;border-radius:8px;font-size:12px;" id="msg"></div>
`;

// State
const state = { hp:100, hunger:100, thirst:100, vy:0, onGround:true };
const GRAVITY=-18;
const JUMP=7;

function updateHUD(){
  (document.getElementById('hp') as HTMLElement).textContent = Math.round(state.hp).toString();
  (document.getElementById('hunger') as HTMLElement).textContent = Math.round(state.hunger).toString();
  (document.getElementById('thirst') as HTMLElement).textContent = Math.round(state.thirst).toString();
}

// Collision check
function collides(pos:THREE.Vector3){
  const pbox = new THREE.Box3().setFromCenterAndSize(pos, new THREE.Vector3(0.8,1.8,0.8));
  for(const c of colliders){ if(pbox.intersectsBox(c)) return true; }
  return false;
}

// Resize
window.addEventListener('resize', ()=>{
  camera.aspect = window.innerWidth/window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// Enemy AI
let enemyState: 'patrol'|'chase' = 'patrol';
let enemyTarget = new THREE.Vector3(12,0,8);
const enemySpeed = 2.5;

// Day/night simple
let timeOfDay = 0.3;

// Main loop
const clock = new THREE.Clock();
function animate(){
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.05);

  // Input
  let mx=0, mz=0;
  if(keys['KeyW']) mz -=1;
  if(keys['KeyS']) mz +=1;
  if(keys['KeyA']) mx -=1;
  if(keys['KeyD']) mx +=1;
  // touch
  mx += touchMove.x;
  mz += touchMove.y;

  // Move relative to camera yaw
  const fwd = new THREE.Vector3(-Math.sin(yaw),0,-Math.cos(yaw));
  const right = new THREE.Vector3(Math.cos(yaw),0,-Math.sin(yaw));
  const move = fwd.clone().multiplyScalar(-mz).add(right.clone().multiplyScalar(mx));
  if(move.length()>0.01){ move.normalize(); }

  const speed = keys['ShiftLeft']? 6 : 3.5;
  const next = player.position.clone().addScaledVector(move, speed*dt);
  next.y = player.position.y;
  if(!collides(next)) player.position.copy(next);

  // Gravity/jump
  state.vy += GRAVITY*dt;
  player.position.y += state.vy*dt;
  if(player.position.y <= 0){ player.position.y=0; state.vy=0; state.onGround=true; }
  if(jumpPressed && state.onGround){ state.vy=JUMP; state.onGround=false; jumpPressed=false; }

  // First-person camera
  camera.position.set(player.position.x, player.position.y+1.6, player.position.z);
  camera.rotation.set(pitch, yaw, 0, 'YXZ');

  // Enemy AI
  const distToPlayer = enemy.position.distanceTo(player.position);
  if(distToPlayer < 18) enemyState='chase'; else if(distToPlayer>25) enemyState='patrol';
  if(enemyState==='chase'){
    const dir = player.position.clone().sub(enemy.position); dir.y=0;
    if(dir.length()>0.5){ dir.normalize(); const np=enemy.position.clone().addScaledVector(dir, enemySpeed*dt); np.y=0; enemy.position.copy(np); }
    // damage on close
    if(distToPlayer < 1.5){ state.hp -= 15*dt; if(state.hp<0) state.hp=0; }
  } else {
    // patrol toward target
    const dir = enemyTarget.clone().sub(enemy.position); dir.y=0;
    if(dir.length()<1){ enemyTarget.set(Math.random()*20-10,0,Math.random()*20-10); }
    else { dir.normalize(); enemy.position.addScaledVector(dir, enemySpeed*0.5*dt); }
  }
  enemy.position.y=0;

  // Survival decay
  state.hunger = Math.max(0, state.hunger - 0.5*dt);
  state.thirst = Math.max(0, state.thirst - 0.8*dt);
  if(state.hunger<20 || state.thirst<20) state.hp = Math.max(0, state.hp - 2*dt);

  // Day/night
  timeOfDay = (timeOfDay + dt*0.02) % 1;
  const sunAngle = timeOfDay*Math.PI*2;
  sun.position.set(Math.cos(sunAngle)*60, Math.abs(Math.sin(sunAngle))*80+10, Math.sin(sunAngle)*60);
  const brightness = 0.3 + 0.7*Math.max(0, Math.sin(sunAngle));
  sun.intensity = brightness*1.2;
  hemi.intensity = 0.3 + brightness*0.4;
  const sky = new THREE.Color().setHSL(0.6, 0.4, 0.2 + brightness*0.5);
  scene.background = sky;
  scene.fog = new THREE.Fog(sky, 40, 120);

  updateHUD();
  renderer.render(scene, camera);
}
loading.style.display='none';
animate();

// Save simple
window.addEventListener('beforeunload', ()=>{
  try { localStorage.setItem('survival_save', JSON.stringify({pos:player.position.toArray(), hp:state.hp, hunger:state.hunger, thirst:state.thirst})); } catch(e){}
});
// Load
try {
  const s = localStorage.getItem('survival_save');
  if(s){ const d=JSON.parse(s); player.position.fromArray(d.pos); state.hp=d.hp; state.hunger=d.hunger; state.thirst=d.thirst; }
} catch(e){}
