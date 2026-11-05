const particleLayer=document.getElementById("particles");
const enterButton=document.getElementById("enter-button");
const intro=document.getElementById("intro");

if(particleLayer){
  for(let i=0;i<54;i++){
    const coin=document.createElement("span");
    coin.className="coin"+(i%5===0?" blue":"");
    coin.style.left=(Math.random()*100)+"%";
    coin.style.animationDelay=(-Math.random()*18)+"s";
    coin.style.animationDuration=(8+Math.random()*12)+"s";
    coin.style.opacity=".0";
    particleLayer.appendChild(coin);
  }
}

function escapeCardText(value){return String(value).replace(/[&<>"\']/g,char=>({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","\'":"&#39;"}[char]));}

function renderMemberCard(first,last,country,city,reference){
  return `
    <div class="card-preview-result">
      <div class="member-card-scene">
        <article class="member-card" id="finished-member-card" aria-label="VORTERRA electronic membership card">
          <div class="member-card-inner">
            <div class="member-brand"><span>VORTERRA</span><small>WORLD MEMBER • 2026</small></div>
            <div class="member-card-middle">
              <span class="member-chip" aria-hidden="true"></span>
              <span class="member-contactless" aria-hidden="true">)))</span>
            </div>
            <div class="member-card-name">${escapeCardText(first)} ${escapeCardText(last)}</div>
            <div class="member-card-foot"><span>MEMBER REFERENCE<strong>${escapeCardText(reference)}</strong></span><span>${escapeCardText(city.toUpperCase())}<br>${escapeCardText(country.toUpperCase())}</span></div>
          </div>
          <span class="member-card-monogram" aria-hidden="true">V</span>
        </article>
      </div>
      <div class="card-result-actions">
        <button class="card-back-button" id="edit-identity" type="button">EDIT DETAILS</button>
        <button class="card-continue" id="continue-registration" type="button">CONTINUE →</button>
      </div>
    </div>`;
}

function showIdentityCard(){
  const content=document.querySelector(".intro-content");
  content.innerHTML=`
    <section class="identity-stage" aria-labelledby="identity-title">
      <p class="identity-heading" id="identity-title">VORTERRA • YOUR WORLD IDENTITY</p>
      <p class="identity-subtitle">Create your member profile and preview your personal electronic card.</p>
      <div class="identity-layout">
        <div class="member-card-scene">
          <article class="member-card" id="live-member-card" aria-label="VORTERRA electronic membership card preview">
            <div class="member-card-inner">
              <div class="member-brand"><span>VORTERRA</span><small>WORLD MEMBER • 2026</small></div>
              <div class="member-card-middle"><span class="member-chip" aria-hidden="true"></span><span class="member-contactless" aria-hidden="true">)))</span></div>
              <div class="member-card-name" id="live-card-name">YOUR NAME</div>
              <div class="member-card-foot"><span>MEMBER REFERENCE<strong>VOR • PENDING</strong></span><span id="live-card-location">YOUR CITY<br>YOUR COUNTRY</span></div>
            </div>
            <span class="member-card-monogram" aria-hidden="true">V</span>
          </article>
        </div>
        <form class="card-form-panel" id="identity-form">
          <h2 class="card-form-title">PERSONAL DETAILS</h2>
          <p class="card-form-help">These details will appear on your VORTERRA member card. Choose your in-game city, not your home address.</p>
          <div class="identity-fields">
            <label class="identity-field">GIVEN NAME<input name="firstName" autocomplete="given-name" maxlength="28" placeholder="First name" required></label>
            <label class="identity-field">FAMILY NAME<input name="lastName" autocomplete="family-name" maxlength="28" placeholder="Family name" required></label>
            <label class="identity-field">COUNTRY<input name="country" autocomplete="country-name" maxlength="40" placeholder="Country" required></label>
            <label class="identity-field">CITY<input name="city" maxlength="40" placeholder="Chosen city" required></label>
          </div>
          <button class="card-submit" type="submit">ISSUE MY MEMBER CARD <span aria-hidden="true">✦</span></button>
        </form>
      </div>
    </section>`;
  const form=document.getElementById("identity-form");
  const card=document.getElementById("live-member-card");
  const cardName=document.getElementById("live-card-name");
  const cardLocation=document.getElementById("live-card-location");
  const scene=document.querySelector(".member-card-scene");
  const updateCard=()=>{
    const data=new FormData(form);
    const first=String(data.get("firstName")||"").trim();
    const last=String(data.get("lastName")||"").trim();
    const country=String(data.get("country")||"").trim();
    const city=String(data.get("city")||"").trim();
    cardName.textContent=(first+" "+last).trim()||"YOUR NAME";
    cardLocation.innerHTML=(city?city.toUpperCase():"YOUR CITY")+"<br>"+(country?country.toUpperCase():"YOUR COUNTRY");
  };
  form.addEventListener("input",updateCard);
  scene.addEventListener("pointermove",(event)=>{
    if(event.pointerType==="touch")return;
    const rect=scene.getBoundingClientRect();
    const x=(event.clientX-rect.left)/rect.width-.5;
    const y=(event.clientY-rect.top)/rect.height-.5;
    card.style.transform="rotateY("+(-13+x*20)+"deg) rotateX("+(7-y*14)+"deg) translateY(-3px)";
  });
  scene.addEventListener("pointerleave",()=>{card.style.transform="rotateY(-13deg) rotateX(7deg)";});
  form.addEventListener("submit",(event)=>{
    event.preventDefault();
    if(!form.reportValidity())return;
    const data=new FormData(form);
    const first=String(data.get("firstName")).trim();
    const last=String(data.get("lastName")).trim();
    const country=String(data.get("country")).trim();
    const city=String(data.get("city")).trim();
    const reference="VOR-"+Math.random().toString(36).slice(2,8).toUpperCase();
    content.innerHTML=`
      <section class="identity-stage">
        <p class="identity-heading">YOUR VORTERRA MEMBER CARD</p>
        <p class="identity-subtitle">Your personal identity card is ready for preview.</p>
        ${renderMemberCard(first,last,country,city,reference)}
      </section>`;
    const resultCard=document.getElementById("finished-member-card");
    const resultScene=resultCard.parentElement;
    resultScene.addEventListener("pointermove",(e)=>{
      if(e.pointerType==="touch")return;
      const r=resultCard.getBoundingClientRect();
      const x=(e.clientX-r.left)/r.width-.5;
      const y=(e.clientY-r.top)/r.height-.5;
      resultCard.style.transform="rotateY("+(-x*18)+"deg) rotateX("+(y*12)+"deg) translateY(-5px)";
    });
    resultScene.addEventListener("pointerleave",()=>{resultCard.style.transform="rotateY(0) rotateX(0)";});
    document.getElementById("edit-identity").addEventListener("click",showIdentityCard);
    document.getElementById("continue-registration").addEventListener("click",()=>{
      content.innerHTML=`<div class="identity-stage"><p class="identity-heading">MEMBER CARD PREVIEW COMPLETE</p><h1 class="wordmark">VORTERRA</h1><p class="identity-subtitle">Account registration with Google or email and password will be the next stage.</p><p class="next-stage-note">ACCOUNT REGISTRATION — NEXT DEVELOPMENT STAGE</p></div>`;
    });
  });
}

enterButton?.addEventListener("click",()=>{
  intro.classList.add("leaving");
  enterButton.disabled=true;
  window.setTimeout(()=>{
    intro.classList.remove("leaving");
    showIdentityCard();
  },900);
});
