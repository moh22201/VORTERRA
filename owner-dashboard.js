(() => {
  const client = vortERRAAuth;
  const language = () => {
    const v = (document.documentElement.lang || "en").toLowerCase();
    return v.startsWith("ar") ? "ar" : v.startsWith("fr") ? "fr" : "en";
  };
  const words = {
    en: {owner:"Owner Dashboard",title:"VORTERRA · OWNER CONTROL",subtitle:"Live platform figures from the database",refresh:"Refresh data",players:"Registered players",cities:"Player cities",assets:"Owned facilities",total:"Total VOR balance",available:"Available VOR",usdt:"Internal USDT",deposits:"Confirmed deposits",debt:"Outstanding loans",cohort:"Loan places issued",list:"Player accounts",email:"Account",joined:"Joined",balance:"Wallet",debtValue:"Debt",due:"Due date",loading:"Loading live account data…",failed:"Could not load owner data: ",noLoan:"No outstanding loan",indebted:"IN DEBT",principal:"Original loan",outstanding:"Outstanding debt",issued:"Issue date",repayRule:"The loan principal becomes eligible for repayment only after it is circulated through a facility purchase.",withdrawTitle:"Debt status before withdrawal",withdrawRule:"Your account is marked as indebted. The outstanding loan amount must be accounted for before any withdrawal payout. The withdrawal request and payout workflow is not active yet.",noDebt:"No outstanding loan is recorded for this account.",adminOnly:"This panel is available only to the VORTERRA owner account."},
    fr: {owner:"Tableau du propriétaire",title:"VORTERRA · CONTRÔLE DU PROPRIÉTAIRE",subtitle:"Données réelles de la plateforme depuis la base de données",refresh:"Actualiser",players:"Joueurs inscrits",cities:"Villes des joueurs",assets:"Installations détenues",total:"Solde VOR total",available:"VOR disponibles",usdt:"USDT interne",deposits:"Dépôts confirmés",debt:"Prêts restants",cohort:"Prêts initiaux attribués",list:"Comptes joueurs",email:"Compte",joined:"Inscription",balance:"Portefeuille",debtValue:"Dette",due:"Échéance",loading:"Chargement des données réelles…",failed:"Impossible de charger les données : ",noLoan:"Aucun prêt en cours",indebted:"ENDetté",principal:"Prêt initial",outstanding:"Dette restante",issued:"Date d’octroi",repayRule:"Le capital du prêt devient remboursable uniquement après sa circulation par l’achat d’une installation.",withdrawTitle:"État de la dette avant retrait",withdrawRule:"Votre compte est marqué comme endetté. Le montant restant du prêt doit être pris en compte avant tout paiement. Le processus de retrait n’est pas encore actif.",noDebt:"Aucun prêt impayé n’est enregistré.",adminOnly:"Ce panneau est réservé au compte propriétaire de VORTERRA."},
    ar: {owner:"لوحة تحكم المالك",title:"VORTERRA · لوحة إدارة المنصة",subtitle:"إحصائيات مباشرة من قاعدة البيانات",refresh:"تحديث البيانات",players:"اللاعبون المسجلون",cities:"مدن اللاعبين",assets:"المنشآت المملوكة",total:"إجمالي أرصدة VOR",available:"أرصدة VOR المتاحة",usdt:"رصيد USDT الداخلي",deposits:"الإيداعات المؤكدة",debt:"القروض المتبقية",cohort:"القروض الممنوحة من الألف",list:"حسابات اللاعبين",email:"الحساب",joined:"تاريخ التسجيل",balance:"المحفظة",debtValue:"الدين",due:"موعد السداد",loading:"جارٍ تحميل بيانات الحسابات…",failed:"تعذر تحميل بيانات المالك: ",noLoan:"لا يوجد قرض مستحق",indebted:"مدان",principal:"قيمة القرض الأصلية",outstanding:"الدين المتبقي",issued:"تاريخ منح القرض",repayRule:"لا يصبح مبلغ القرض مؤهلاً للتسديد إلا بعد تدويره من خلال شراء منشأة.",withdrawTitle:"حالة الدين قبل السحب",withdrawRule:"حسابك مسجل كمدين. يجب احتساب قيمة القرض المتبقية قبل صرف أي طلب سحب. نظام طلب السحب والصرف لم يُفعّل بعد.",noDebt:"لا يوجد دين قرض مستحق مسجل على هذا الحساب.",adminOnly:"هذه اللوحة مخصصة لحساب مالك VORTERRA فقط."}
  };
  const t = () => words[language()];
  const fmt = v => Number(v || 0).toLocaleString(language()==="ar"?"ar-DZ":"en-US",{minimumFractionDigits:2,maximumFractionDigits:2});
  const date = v => v ? new Date(v).toLocaleDateString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-GB") : "—";

  function styles() {
    if (document.getElementById("ownerDashboardStyles")) return;
    const s = document.createElement("style"); s.id = "ownerDashboardStyles";
    s.textContent = "#dashboard .owner-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));gap:12px;margin:18px 0}#dashboard .owner-stat{padding:16px;border:1px solid #d9b36e44;border-radius:12px;background:linear-gradient(145deg,#211b12,#090a0b)}#dashboard .owner-stat small{display:block;color:#cbb88e;font-size:10px}#dashboard .owner-stat strong{display:block;color:#ffe3a0;font-size:22px;margin-top:8px;overflow-wrap:anywhere}#dashboard .owner-table-wrap{overflow:auto;border:1px solid #d9b36e33;border-radius:12px}#dashboard .owner-table{width:100%;border-collapse:collapse;min-width:620px;font-size:11px}#dashboard .owner-table th,#dashboard .owner-table td{padding:11px;text-align:start;border-bottom:1px solid #ffffff12}#dashboard .owner-table th{color:#e8cb8f;background:#ffffff08}#dashboard .owner-table td{color:#ddd2bc}#dashboard .owner-toolbar{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}#dashboard .owner-refresh{padding:10px 15px;border:1px solid #e4c17c;border-radius:8px;background:#8b6428;color:#fff1d0;font-weight:700}#dashboard .loan-live{padding:15px;border:1px solid #d9b36e55;border-radius:12px;background:linear-gradient(145deg,#201b13,#090a0b);display:grid;gap:12px;margin-bottom:12px}#dashboard .loan-live-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(135px,1fr));gap:10px}#dashboard .loan-live-grid div{padding:10px;background:#ffffff08;border-radius:8px}#dashboard .loan-live small{display:block;color:#c6b38b;font-size:10px;margin-bottom:5px}#dashboard .loan-live strong{color:#ffe3a0;font-size:16px;overflow-wrap:anywhere}#dashboard .loan-live p{color:#c9c0ad;font-size:11px;line-height:1.8;margin:0}#dashboard .loan-status{color:#ffcc8c;font-weight:800}";
    document.head.appendChild(s);
  }

  function addOwnerPanel() {
    const side=document.querySelector("#dashboard .dside"), main=document.querySelector("#dashboard .dmain");
    if(!side||!main||document.querySelector('[data-view="owner"]')) return;
    const btn=document.createElement("button");btn.type="button";btn.dataset.view="owner";btn.innerHTML="<span>◆</span><span></span>";btn.lastElementChild.textContent=t().owner;
    btn.addEventListener("click",()=>openDashboardPanel("owner"));
    side.insertBefore(btn,side.querySelector("footer"));
    const panel=document.createElement("section");panel.className="dview";panel.dataset.panel="owner";
    panel.innerHTML='<div class="dtoolbar owner-toolbar"><div><h2 data-owner-title></h2><p data-owner-subtitle></p></div><button type="button" class="owner-refresh" data-owner-refresh></button></div><div class="owner-grid" data-owner-stats></div><div class="dpanel"><div class="dpanelhead"><b data-owner-list-title></b><small>DATABASE</small></div><div class="dpanelbody"><div class="owner-table-wrap"><table class="owner-table"><thead><tr><th data-owner-email></th><th data-owner-joined></th><th data-owner-balance></th><th data-owner-debt></th><th data-owner-due></th></tr></thead><tbody data-owner-players></tbody></table></div></div></div><p class="dnote" data-owner-message></p>';
    main.appendChild(panel);panel.querySelector("[data-owner-refresh]").addEventListener("click",loadOwner);
  }

  async function loadOwner() {
    const panel=document.querySelector('[data-panel="owner"]');if(!panel)return;
    const x=t();
    [["[data-owner-title]",x.title],["[data-owner-subtitle]",x.subtitle],["[data-owner-refresh]",x.refresh],["[data-owner-list-title]",x.list],["[data-owner-email]",x.email],["[data-owner-joined]",x.joined],["[data-owner-balance]",x.balance],["[data-owner-debt]",x.debtValue],["[data-owner-due]",x.due],["[data-owner-message]",x.loading]].forEach(([q,v])=>panel.querySelector(q).textContent=v);
    const stats=panel.querySelector("[data-owner-stats]"), rows=panel.querySelector("[data-owner-players]");stats.innerHTML="";rows.innerHTML="";
    try {
      const [a,b]=await Promise.all([client.rpc("get_owner_dashboard_summary"),client.rpc("get_owner_dashboard_players",{p_limit:100})]);
      if(a.error)throw a.error;if(b.error)throw b.error;const d=a.data||{};
      [[x.players,d.players],[x.cities,d.cities],[x.assets,d.owned_projects],[x.total,fmt(d.wallet_total_vor)],[x.available,fmt(d.wallet_available_vor)],[x.usdt,fmt(d.wallet_usdt_internal)],[x.deposits,fmt(d.confirmed_deposits_usdt)+" USDT"],[x.debt,fmt(d.outstanding_loans_vor)+" VOR"],[x.cohort,String(d.loan_slots_awarded??0)+" / 1,000"]].forEach(([label,value])=>{const card=document.createElement("article");card.className="owner-stat";const small=document.createElement("small");small.textContent=label;const strong=document.createElement("strong");strong.textContent=value??"0";card.append(small,strong);stats.appendChild(card)});
      (Array.isArray(b.data)?b.data:[]).forEach(p=>{const tr=document.createElement("tr");[p.email||p.display_name||p.user_id,date(p.created_at),fmt(p.wallet_total_vor)+" VOR",fmt(p.loan_outstanding_vor)+" VOR",date(p.loan_due_at)].forEach(v=>{const td=document.createElement("td");td.textContent=v;tr.appendChild(td)});rows.appendChild(tr)});
      panel.querySelector("[data-owner-message]").textContent="";
    } catch(e) {panel.querySelector("[data-owner-message]").textContent=e.code==="42501"?x.adminOnly:x.failed+(e.message||"");}
  }

  async function loadLoan() {
    const loanBody=document.querySelector('[data-wallet-panel="loans"] .dpanelbody');
    const withdrawBody=document.querySelector('[data-wallet-panel="withdraw"] .dpanelbody');
    if(!loanBody||!withdrawBody)return;
    const x=t();let card=loanBody.querySelector("#livePlayerLoan");
    if(!card){card=document.createElement("div");card.id="livePlayerLoan";card.className="loan-live";loanBody.replaceChildren(card)}
    let notice=withdrawBody.querySelector("#withdrawLoanNotice");
    if(!notice){notice=document.createElement("div");notice.id="withdrawLoanNotice";notice.className="loan-live";withdrawBody.appendChild(notice)}
    card.textContent=x.loading;notice.textContent=x.loading;
    try{
      const r=await client.rpc("get_my_loan_status");if(r.error)throw r.error;const d=r.data;
      if(!d?.has_loan){card.textContent=x.noLoan;notice.textContent=x.noDebt;return}
      const amount=Number(d.outstanding_vor||0);
      const status=document.createElement("strong");status.className="loan-status";status.textContent=amount>0?x.indebted:x.noLoan;
      const grid=document.createElement("div");grid.className="loan-live-grid";
      [[x.principal,fmt(d.principal_vor)+" VOR"],[x.outstanding,fmt(amount)+" VOR"],[x.issued,date(d.issued_at)],[x.due,date(d.due_at)]].forEach(([label,value])=>{const cell=document.createElement("div"),small=document.createElement("small"),strong=document.createElement("strong");small.textContent=label;strong.textContent=value;cell.append(small,strong);grid.appendChild(cell)});
      const rule=document.createElement("p");rule.textContent=x.repayRule;card.replaceChildren(status,grid,rule);
      const head=document.createElement("strong");head.textContent=x.withdrawTitle;const detail=document.createElement("p");detail.textContent=amount>0?x.withdrawRule+" "+x.outstanding+": "+fmt(amount)+" VOR.":x.noDebt;notice.replaceChildren(head,detail);
    }catch(e){card.textContent=e.message||"Loan status unavailable";notice.textContent=e.message||"Loan status unavailable"}
  }

  async function init(user) {
    if(!user)return;styles();await loadLoan();
    const r=await client.rpc("get_owner_dashboard_summary");
    if(!r.error){addOwnerPanel();await loadOwner()}
  }
  client.auth.getSession().then(({data})=>init(data?.session?.user));
  client.auth.onAuthStateChange((event,session)=>{
    if(event==="SIGNED_OUT"){document.querySelector('[data-view="owner"]')?.remove();document.querySelector('[data-panel="owner"]')?.remove();return}
    if(session?.user&&["SIGNED_IN","INITIAL_SESSION","TOKEN_REFRESHED"].includes(event))setTimeout(()=>init(session.user),0);
  });
  document.addEventListener("click",event=>{
    if(event.target.closest("#dashboard [data-lang]"))setTimeout(()=>{
      const label=document.querySelector('#dashboard [data-view="owner"] span:last-child');if(label)label.textContent=t().owner;
      loadLoan();if(document.querySelector('[data-panel="owner"]'))loadOwner();
    },0);
  });
})();