const particleLayer=document.getElementById("particles");
const enterButton=document.getElementById("enter-button");
const intro=document.getElementById("intro");

if(particleLayer){
  for(let i=0;i<34;i++){
    const coin=document.createElement("span");
    coin.className="coin"+(i%5===0?" blue":"");
    coin.style.left=(Math.random()*100)+"%";
    coin.style.animationDelay=(-Math.random()*12)+"s";
    coin.style.animationDuration=(8+Math.random()*9)+"s";
    coin.style.transform="scale("+(0.55+Math.random()*.8)+")";
    particleLayer.appendChild(coin);
  }
}

function showIdentityCard(){
  const content=document.querySelector(".intro-content");
  content.innerHTML=`
    <section class="identity-stage" aria-labelledby="identity-title">
      <p class="identity-heading" id="identity-title">PLAYER IDENTITY</p>
      <p class="identity-subtitle">Create your VORTERRA identity card. Your city location means the city you choose in the game — never your home address or precise device location.</p>
      <div class="identity-card-wrap">
        <div class="identity-card" id="identity-card">
          <form class="identity-face identity-front" id="identity-form">
            <div class="card-topline"><span>VORTERRA NETWORK</span><span>PLAYER CARD</span></div>
            <div class="card-chip" aria-hidden="true"></div>
            <div class="identity-fields">
              <label class="identity-field">FIRST NAME<input name="firstName" autocomplete="given-name" maxlength="28" placeholder="First name" required></label>
              <label class="identity-field">LAST NAME<input name="lastName" autocomplete="family-name" maxlength="28" placeholder="Last name" required></label>
              <label class="identity-field">COUNTRY<input name="country" autocomplete="country-name" maxlength="40" placeholder="Country" required></label>
              <label class="identity-field">CITY<input name="city" maxlength="40" placeholder="Chosen city" required></label>
            </div>
            <button class="card-submit" type="submit">CREATE IDENTITY CARD <span aria-hidden="true">→</span></button>
            <span class="card-watermark" aria-hidden="true">V</span>
          </form>
          <div class="identity-face identity-back">
            <div>
              <div class="card-topline"><span>VORTERRA</span><span>WORLD MEMBER</span></div>
              <h2 class="card-back-title">PLAYER IDENTITY</h2>
              <p class="card-player-name" id="card-player-name">PLAYER NAME</p>
              <p class="card-player-location" id="card-player-location">CITY · COUNTRY</p>
              <p class="card-id-label">PLAYER REFERENCE</p>
              <div class="card-player-id" id="card-player-id">VOR-000000</div>
              <p class="card-note">Your city reference is used for in-game regional distance and trading features. This preview is not yet connected to an account or database.</p>
            </div>
            <div class="identity-actions">
              <button class="card-back-button" id="edit-identity" type="button">EDIT DETAILS</button>
              <button class="card-continue" id="continue-registration" type="button">CONTINUE →</button>
            </div>
            <span class="card-watermark" aria-hidden="true">V</span>
          </div>
        </div>
      </div>
    </section>`;
  const form=document.getElementById("identity-form");
  const card=document.getElementById("identity-card");
  form.addEventListener("submit",(event)=>{
    event.preventDefault();
    if(!form.reportValidity()) return;
    const data=new FormData(form);
    const first=String(data.get("firstName")).trim();
    const last=String(data.get("lastName")).trim();
    const country=String(data.get("country")).trim();
    const city=String(data.get("city")).trim();
    document.getElementById("card-player-name").textContent=first+" "+last;
    document.getElementById("card-player-location").textContent=city+" · "+country;
    const reference="VOR-"+Math.random().toString(36).slice(2,8).toUpperCase();
    document.getElementById("card-player-id").textContent=reference;
    card.classList.add("is-flipped");
  });
  document.getElementById("edit-identity").addEventListener("click",()=>card.classList.remove("is-flipped"));
  document.getElementById("continue-registration").addEventListener("click",()=>{
    content.innerHTML=`
      <div class="identity-stage">
        <p class="identity-heading">IDENTITY CARD COMPLETE</p>
        <h1 class="wordmark">VORTERRA</h1>
        <p class="identity-subtitle">The next stage is account registration with Google or email and password.</p>
        <p class="next-stage-note">ACCOUNT REGISTRATION — NEXT DEVELOPMENT STAGE</p>
      </div>`;
  });
}

enterButton?.addEventListener("click",()=>{
  intro.classList.add("leaving");
  enterButton.disabled=true;
  enterButton.setAttribute("aria-label","Introduction complete");
  window.setTimeout(()=>{
    intro.classList.remove("leaving");
    showIdentityCard();
  },780);
});
