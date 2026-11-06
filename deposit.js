(() => {
  const address = "0xb5070306324dd921242a431492cc4fdd8f245e21";
  const endpoint = "verify-bep20-deposit";
  const words = {
    en: { title:"USDT deposit · BNB Smart Chain (BEP-20)", amount:"Amount (USDT)", hash:"Transaction hash (TxID)", send:"Verify deposit", address:"VORTERRA deposit address", copy:"Copy address", copied:"Address copied", note:"Send USDT only through BNB Smart Chain (BEP-20). Enter the exact amount and transaction hash after sending. VOR is credited automatically after 12 network confirmations.", history:"Confirmed deposits", empty:"No confirmed deposits yet.", working:"Verifying transaction on BNB Smart Chain…", success:"Deposit confirmed. VOR has been added to your wallet.", error:"Verification failed: ", minmax:"Enter an amount from 50 to 5,000 USDT.", hashRequired:"Enter the transaction hash." },
    fr: { title:"Dépôt USDT · BNB Smart Chain (BEP-20)", amount:"Montant (USDT)", hash:"Hash de transaction (TxID)", send:"Vérifier le dépôt", address:"Adresse de dépôt VORTERRA", copy:"Copier l’adresse", copied:"Adresse copiée", note:"Envoyez uniquement des USDT via BNB Smart Chain (BEP-20). Saisissez le montant exact et le hash après l’envoi. Le VOR est crédité automatiquement après 12 confirmations.", history:"Dépôts confirmés", empty:"Aucun dépôt confirmé.", working:"Vérification sur BNB Smart Chain…", success:"Dépôt confirmé. Le VOR a été ajouté à votre portefeuille.", error:"Échec de la vérification : ", minmax:"Saisissez un montant entre 50 et 5 000 USDT.", hashRequired:"Saisissez le hash de transaction." },
    ar: { title:"إيداع USDT · شبكة BNB Smart Chain (BEP-20)", amount:"مبلغ الإيداع (USDT)", hash:"رقم المعاملة (TxID)", send:"تحقق من الإيداع", address:"عنوان إيداع VORTERRA", copy:"نسخ العنوان", copied:"تم نسخ العنوان", note:"أرسل USDT عبر شبكة BNB Smart Chain (BEP-20) فقط. بعد الإرسال أدخل المبلغ نفسه ورقم المعاملة. يُضاف VOR تلقائياً بعد 12 تأكيداً على الشبكة.", history:"الإيداعات المؤكدة", empty:"لا توجد إيداعات مؤكدة بعد.", working:"جارٍ التحقق من المعاملة على شبكة BNB…", success:"تم تأكيد الإيداع وإضافة VOR إلى محفظتك.", error:"فشل التحقق: ", minmax:"أدخل مبلغاً من 50 إلى 5,000 USDT.", hashRequired:"أدخل رقم المعاملة." }
  };
  const $ = id => document.getElementById(id);
  const style = document.createElement("style");
  style.textContent = `
    #depositApp{display:grid;gap:15px;color:#eee5d2}
    #depositApp .dep-card{border:1px solid #d9b36e44;border-radius:10px;padding:15px;background:linear-gradient(140deg,#252321,#0c0d0e)}
    #depositApp label{display:block;color:#e6ca91;font-size:11px;margin:10px 0 6px}
    #depositApp input{width:100%;padding:12px;border:1px solid #d9b36e55;border-radius:8px;background:#090a0b;color:#fff;font:13px inherit;direction:ltr}
    #depositApp .dep-address{overflow-wrap:anywhere;color:#ffe3a0;font:12px monospace;direction:ltr;text-align:left;padding:11px;background:#0008;border-radius:7px}
    #depositApp .dep-button{margin-top:12px;width:100%;padding:12px;border:1px solid #f6d889;border-radius:8px;background:linear-gradient(100deg,#9b712e,#f6d889,#b58b43);color:#17120a;font-weight:800}
    #depositApp .dep-button:disabled{opacity:.55}
    #depositApp .dep-note{font-size:11px;line-height:1.8;color:#bcb19a}
    #depositApp .dep-message{min-height:20px;font-size:11px;line-height:1.7;color:#f3d99e}
    #depositApp .dep-history{display:grid;gap:8px}
    #depositApp .dep-row{display:flex;justify-content:space-between;gap:10px;padding:10px;border-bottom:1px solid #d9b36e22;font-size:11px}
    #depositApp .dep-row small{display:block;color:#a99a80;margin-top:4px;overflow-wrap:anywhere}
  `;
  document.head.appendChild(style);

  function render() {
    const panel = document.querySelector('[data-wallet-panel="deposit"] .dpanelbody');
    if (!panel || $("depositApp")) return;
    panel.innerHTML = `
      <div id="depositApp">
        <div class="dep-card">
          <div id="depTitle" style="font-weight:700;color:#ffe3a0;margin-bottom:12px"></div>
          <div id="depAddressLabel" style="font-size:11px;color:#cdbb91;margin-bottom:7px"></div>
          <div class="dep-address" id="depAddress">${address}</div>
          <button class="dep-button" type="button" id="depCopy" style="margin-top:8px"></button>
          <p class="dep-note" id="depNote" style="margin-top:12px"></p>
          <label for="depAmount" id="depAmountLabel"></label>
          <input id="depAmount" type="number" min="50" max="5000" step="0.01" inputmode="decimal" placeholder="50.00">
          <label for="depHash" id="depHashLabel"></label>
          <input id="depHash" type="text" inputmode="text" autocomplete="off" autocapitalize="off" spellcheck="false" placeholder="0x…">
          <button class="dep-button" type="button" id="depSubmit"></button>
          <p class="dep-message" id="depMessage" role="status" aria-live="polite"></p>
        </div>
        <div class="dep-card">
          <b id="depHistoryTitle"></b>
          <div class="dep-history" id="depHistory" style="margin-top:10px"></div>
        </div>
      </div>`;
    $("depCopy").addEventListener("click", async () => {
      try { await navigator.clipboard.writeText(address); $("depMessage").textContent = words[currentLang()].copied; }
      catch { $("depMessage").textContent = address; }
    });
    $("depSubmit").addEventListener("click", submitDeposit);
    translate();
  }
  function currentLang() {
    const lang = document.documentElement.lang.toLowerCase();
    return lang.startsWith("fr") ? "fr" : lang.startsWith("ar") ? "ar" : "en";
  }
  function translate() {
    if (!$("depositApp")) return;
    const t = words[currentLang()];
    $("depTitle").textContent=t.title; $("depAddressLabel").textContent=t.address;
    $("depCopy").textContent=t.copy; $("depNote").textContent=t.note;
    $("depAmountLabel").textContent=t.amount; $("depHashLabel").textContent=t.hash;
    $("depSubmit").textContent=t.send; $("depHistoryTitle").textContent=t.history;
    loadHistory();
  }
  async function submitDeposit() {
    const t=words[currentLang()], amount=$("depAmount").value.trim(), hash=$("depHash").value.trim();
    const button=$("depSubmit"), message=$("depMessage");
    if (!amount || Number(amount)<50 || Number(amount)>5000) { message.textContent=t.minmax; return; }
    if (!/^0x[a-fA-F0-9]{64}$/.test(hash)) { message.textContent=t.hashRequired; return; }
    if (!window.currentAuthUser && typeof currentAuthUser === "undefined") { message.textContent="Sign in first."; return; }
    button.disabled=true; message.textContent=t.working;
    try {
      const {data,error}=await vortERRAAuth.functions.invoke(endpoint,{body:{amount_usdt:amount,tx_hash:hash}});
      if(error) throw error;
      if(data?.error) throw new Error(data.error);
      message.textContent=t.success;
      $("depHash").value=""; $("depAmount").value="";
      if(typeof currentAuthUser!=="undefined" && currentAuthUser) await refreshWalletBalances(currentAuthUser);
      await loadHistory();
    } catch(error) { message.textContent=t.error+(error.message||""); }
    finally { button.disabled=false; }
  }
  async function loadHistory() {
    if (!$("depHistory") || typeof vortERRAAuth==="undefined") return;
    const target=$("depHistory"), t=words[currentLang()];
    try {
      const {data,error}=await vortERRAAuth.from("deposit_requests").select("amount_usdt,credited_vor,tx_hash,created_at,status").order("created_at",{ascending:false}).limit(20);
      if(error) throw error;
      target.innerHTML="";
      if(!data?.length){target.textContent=t.empty;return;}
      data.forEach(item=>{
        const row=document.createElement("div");row.className="dep-row";
        const left=document.createElement("div");left.textContent=new Date(item.created_at).toLocaleString();
        const tx=document.createElement("small");tx.textContent=item.tx_hash;left.appendChild(tx);
        const right=document.createElement("b");right.textContent=Number(item.amount_usdt).toLocaleString()+" USDT → "+Number(item.credited_vor).toLocaleString()+" VOR";
        row.append(left,right);target.appendChild(row);
      });
    } catch(error) { target.textContent=error.message||t.empty; }
  }
  render();
  document.querySelectorAll("[data-lang]").forEach(button=>button.addEventListener("click",()=>setTimeout(translate,0)));
  new MutationObserver(translate).observe(document.documentElement,{attributes:true,attributeFilter:["lang"]});
})();