(() => {
  const client = vortERRAAuth;
  const language = () => {
    const v = (document.documentElement.lang || "en").toLowerCase();
    return v.startsWith("ar") ? "ar" : v.startsWith("fr") ? "fr" : "en";
  };
  const words = {
    en: {owner:"Owner Dashboard",title:"VORTERRA · OWNER CONTROL",subtitle:"Live platform figures from the database",refresh:"Refresh data",players:"Registered players",withdrawalCount:"Withdrawal requests",pendingWithdrawals:"Pending requests",pendingAmount:"Pending withdrawal value",cities:"Player cities",assets:"Owned facilities",total:"Total VOR balance",available:"Available VOR",reserved:"Reserved VOR",borrowers:"Indebted accounts",depositCount:"Confirmed deposit count",usdt:"Internal USDT",deposits:"Confirmed deposits",debt:"Outstanding loans",cohort:"Loan places issued",list:"Player accounts",withdrawalList:"Withdrawal requests",email:"Account",joined:"Joined",balance:"Wallet",debtValue:"Debt",due:"Due date",loading:"Loading live account data…",failed:"Could not load owner data: ",noLoan:"No outstanding loan",indebted:"IN DEBT",principal:"Original loan",outstanding:"Outstanding debt",issued:"Issue date",repayRule:"The loan principal becomes eligible for repayment only after it is circulated through a facility purchase.",withdrawTitle:"Debt status before withdrawal",withdrawRule:"Your account is marked as indebted. The outstanding loan amount must be accounted for before any withdrawal payout. The withdrawal request and payout workflow is not active yet.",noDebt:"No outstanding loan is recorded for this account.",withdrawAmount:"Withdrawal amount",fee:"Fee",net:"Net payout",status:"Status",action:"Review",approve:"Approve",reject:"Reject",reviewing:"Saving decision…",requested:"Requested",pending:"Pending",approved:"Approved",rejected:"Rejected",paid:"Paid",cancelled:"Cancelled",adminOnly:"This panel is available only to the VORTERRA owner account."},
    fr: {owner:"Tableau du propriétaire",title:"VORTERRA · CONTRÔLE DU PROPRIÉTAIRE",subtitle:"Données réelles de la plateforme depuis la base de données",refresh:"Actualiser",players:"Joueurs inscrits",withdrawalCount:"Demandes de retrait",pendingWithdrawals:"Demandes en attente",pendingAmount:"Montant en attente",cities:"Villes des joueurs",assets:"Installations détenues",total:"Solde VOR total",available:"VOR disponibles",reserved:"VOR réservés",borrowers:"Comptes endettés",depositCount:"Nombre de dépôts confirmés",usdt:"USDT interne",deposits:"Dépôts confirmés",debt:"Prêts restants",cohort:"Prêts initiaux attribués",list:"Comptes joueurs",withdrawalList:"Demandes de retrait",email:"Compte",joined:"Inscription",balance:"Portefeuille",debtValue:"Dette",due:"Échéance",loading:"Chargement des données réelles…",failed:"Impossible de charger les données : ",noLoan:"Aucun prêt en cours",indebted:"ENDetté",principal:"Prêt initial",outstanding:"Dette restante",issued:"Date d’octroi",repayRule:"Le capital du prêt devient remboursable uniquement après sa circulation par l’achat d’une installation.",withdrawTitle:"État de la dette avant retrait",withdrawRule:"Votre compte est marqué comme endetté. Le montant restant du prêt doit être pris en compte avant tout paiement. Le processus de retrait n’est pas encore actif.",noDebt:"Aucun prêt impayé n’est enregistré.",withdrawAmount:"Montant",fee:"Frais",net:"Net à payer",status:"Statut",action:"Décision",approve:"Approuver",reject:"Refuser",reviewing:"Enregistrement…",requested:"Demandé",pending:"En attente",approved:"Approuvé",rejected:"Refusé",paid:"Payé",cancelled:"Annulé",adminOnly:"Ce panneau est réservé au compte propriétaire de VORTERRA."},
    ar: {owner:"لوحة تحكم المالك",title:"VORTERRA · لوحة إدارة المنصة",subtitle:"إحصائيات مباشرة من قاعدة البيانات",refresh:"تحديث البيانات",players:"اللاعبون المسجلون",withdrawalCount:"طلبات السحب",pendingWithdrawals:"طلبات قيد المراجعة",pendingAmount:"قيمة السحب المعلق",cities:"مدن اللاعبين",assets:"المنشآت المملوكة",total:"إجمالي أرصدة VOR",available:"أرصدة VOR المتاحة",reserved:"أرصدة VOR المحجوزة",borrowers:"الحسابات المدينة",depositCount:"عدد الإيداعات المؤكدة",usdt:"رصيد USDT الداخلي",deposits:"الإيداعات المؤكدة",debt:"القروض المتبقية",cohort:"القروض الممنوحة من الألف",list:"حسابات اللاعبين",withdrawalList:"طلبات السحب",email:"الحساب",joined:"تاريخ التسجيل",balance:"المحفظة",debtValue:"الدين",due:"موعد السداد",loading:"جارٍ تحميل بيانات الحسابات…",failed:"تعذر تحميل بيانات المالك: ",noLoan:"لا يوجد قرض مستحق",indebted:"مدان",principal:"قيمة القرض الأصلية",outstanding:"الدين المتبقي",issued:"تاريخ منح القرض",repayRule:"لا يصبح مبلغ القرض مؤهلاً للتسديد إلا بعد تدويره من خلال شراء منشأة.",withdrawTitle:"حالة الدين قبل السحب",withdrawRule:"حسابك مسجل كمدين. يجب احتساب قيمة القرض المتبقية قبل صرف أي طلب سحب. نظام طلب السحب والصرف لم يُفعّل بعد.",noDebt:"لا يوجد دين قرض مستحق مسجل على هذا الحساب.",withdrawAmount:"المبلغ",fee:"الرسوم",net:"الصافي",status:"الحالة",action:"المراجعة",approve:"قبول",reject:"رفض",reviewing:"جارٍ حفظ القرار…",requested:"تاريخ الطلب",pending:"قيد المراجعة",approved:"مقبول",rejected:"مرفوض",paid:"مدفوع",cancelled:"ملغى",adminOnly:"هذه اللوحة مخصصة لحساب مالك VORTERRA فقط."}
  };
  const t = () => words[language()];
  const fmt = v => Number(v || 0).toLocaleString(language()==="ar"?"ar-DZ":"en-US",{minimumFractionDigits:2,maximumFractionDigits:2});
  const date = v => v ? new Date(v).toLocaleDateString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-GB") : "—";

  function styles() {
    if (document.getElementById("ownerDashboardStyles")) return;
    const s = document.createElement("style"); s.id = "ownerDashboardStyles";
    s.textContent = "#dashboard .owner-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));gap:12px;margin:18px 0}#dashboard .owner-stat{padding:16px;border:1px solid #d9b36e44;border-radius:12px;background:linear-gradient(145deg,#211b12,#090a0b)}#dashboard .owner-stat small{display:block;color:#cbb88e;font-size:10px}#dashboard .owner-stat strong{display:block;color:#ffe3a0;font-size:22px;margin-top:8px;overflow-wrap:anywhere}#dashboard .owner-table-wrap{overflow:auto;border:1px solid #d9b36e33;border-radius:12px}#dashboard .owner-table{width:100%;border-collapse:collapse;min-width:620px;font-size:11px}#dashboard .owner-table th,#dashboard .owner-table td{padding:11px;text-align:start;border-bottom:1px solid #ffffff12}#dashboard .owner-table th{color:#e8cb8f;background:#ffffff08}#dashboard .owner-table td{color:#ddd2bc}#dashboard .owner-toolbar{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}#dashboard .owner-refresh{padding:10px 15px;border:1px solid #e4c17c;border-radius:8px;background:#8b6428;color:#fff1d0;font-weight:700}#dashboard .loan-live{padding:15px;border:1px solid #d9b36e55;border-radius:12px;background:linear-gradient(145deg,#201b13,#090a0b);display:grid;gap:12px;margin-bottom:12px}#dashboard .loan-live-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(135px,1fr));gap:10px}#dashboard .loan-live-grid div{padding:10px;background:#ffffff08;border-radius:8px}#dashboard .loan-live small{display:block;color:#c6b38b;font-size:10px;margin-bottom:5px}#dashboard .loan-live strong{color:#ffe3a0;font-size:16px;overflow-wrap:anywhere}#dashboard .loan-live p{color:#c9c0ad;font-size:11px;line-height:1.8;margin:0}#dashboard .loan-status{color:#ffcc8c;font-weight:800}#dashboard .owner-review-btn{margin:2px;padding:6px 8px;border:1px solid #d9b36e66;border-radius:6px;background:#241a0e;color:#f2dca8;font-size:10px;cursor:pointer}#dashboard .owner-review-btn:disabled{opacity:.5}";
    document.head.appendChild(s);
  }

  function addOwnerPanel() {
    const side=document.querySelector("#dashboard .dside"), main=document.querySelector("#dashboard .dmain");
    if(!side||!main||document.querySelector('[data-view="owner"]')) return;
    const btn=document.createElement("button");btn.type="button";btn.dataset.view="owner";btn.innerHTML="<span>◆</span><span></span>";btn.lastElementChild.textContent=t().owner;
    btn.addEventListener("click",()=>openDashboardPanel("owner"));
    side.insertBefore(btn,side.querySelector("footer"));
    const panel=document.createElement("section");panel.className="dview";panel.dataset.panel="owner";
    panel.innerHTML='<div class="dtoolbar owner-toolbar"><div><h2 data-owner-title></h2><p data-owner-subtitle></p></div><button type="button" class="owner-refresh" data-owner-refresh></button></div><div class="owner-grid" data-owner-stats></div><div class="dpanel"><div class="dpanelhead"><b data-owner-list-title></b><small>DATABASE</small></div><div class="dpanelbody"><div class="owner-table-wrap"><table class="owner-table"><thead><tr><th data-owner-email></th><th data-owner-joined></th><th data-owner-balance></th><th data-owner-debt></th><th data-owner-due></th></tr></thead><tbody data-owner-players></tbody></table></div></div></div><div class="dpanel" style="margin-top:16px"><div class="dpanelhead"><b data-owner-withdrawal-title></b><small>MANUAL REVIEW</small></div><div class="dpanelbody"><div class="owner-table-wrap"><table class="owner-table"><thead><tr><th data-owner-email></th><th data-owner-withdraw-amount></th><th data-owner-fee></th><th data-owner-net></th><th data-owner-status></th><th data-owner-requested></th><th data-owner-action></th></tr></thead><tbody data-owner-withdrawals></tbody></table></div></div></div><p class="dnote" data-owner-message></p>';
    main.appendChild(panel);panel.querySelector("[data-owner-refresh]").addEventListener("click",loadOwner);
  }

  async function loadOwner() {
    const panel=document.querySelector('[data-panel="owner"]');if(!panel)return;
    const x=t();
    [["[data-owner-title]",x.title],["[data-owner-subtitle]",x.subtitle],["[data-owner-refresh]",x.refresh],["[data-owner-list-title]",x.list],["[data-owner-email]",x.email],["[data-owner-joined]",x.joined],["[data-owner-balance]",x.balance],["[data-owner-debt]",x.debtValue],["[data-owner-due]",x.due],["[data-owner-withdrawal-title]",x.withdrawalList],["[data-owner-withdraw-amount]",x.withdrawAmount],["[data-owner-fee]",x.fee],["[data-owner-net]",x.net],["[data-owner-status]",x.status],["[data-owner-requested]",x.requested],["[data-owner-action]",x.action],["[data-owner-message]",x.loading]].forEach(([q,v])=>panel.querySelector(q).textContent=v);
    const stats=panel.querySelector("[data-owner-stats]"), rows=panel.querySelector("[data-owner-players]"), withdrawalRows=panel.querySelector("[data-owner-withdrawals]");stats.innerHTML="";rows.innerHTML="";withdrawalRows.innerHTML="";
    try {
      const [a,b,c]=await Promise.all([client.rpc("get_owner_dashboard_summary"),client.rpc("get_owner_dashboard_players",{p_limit:5000}),client.rpc("get_owner_withdrawal_requests",{p_limit:200})]);
      if(a.error)throw a.error;if(b.error)throw b.error;if(c.error)throw c.error;const d=a.data||{};
      [[x.players,d.players],[x.cities,d.cities],[x.assets,d.owned_projects],[x.total,fmt(d.wallet_total_vor)],[x.available,fmt(d.wallet_available_vor)],[x.reserved,fmt(d.wallet_reserved_vor)],[x.borrowers,d.borrowers??0],[x.depositCount,d.confirmed_deposit_count??0],[x.usdt,fmt(d.wallet_usdt_internal)],[x.deposits,fmt(d.confirmed_deposits_usdt)+" USDT"],[x.debt,fmt(d.outstanding_loans_vor)+" VOR"],[x.cohort,String(d.loan_slots_awarded??0)+" / 1,000"],[x.withdrawalCount,d.withdrawal_requests??0],[x.pendingWithdrawals,d.pending_withdrawals??0],[x.pendingAmount,fmt(d.pending_withdrawal_amount_usdt)+" USDT"]].forEach(([label,value])=>{const card=document.createElement("article");card.className="owner-stat";const small=document.createElement("small");small.textContent=label;const strong=document.createElement("strong");strong.textContent=value??"0";card.append(small,strong);stats.appendChild(card)});
      (Array.isArray(b.data)?b.data.slice().sort((a,b)=>Number((b.loan_outstanding_vor||0)>0)-Number((a.loan_outstanding_vor||0)>0)):[]).forEach(p=>{const tr=document.createElement("tr");[p.email||p.display_name||p.user_id,date(p.created_at),fmt(p.wallet_total_vor)+" VOR",(Number(p.loan_outstanding_vor||0)>0?x.indebted+" · ":"")+fmt(p.loan_outstanding_vor)+" VOR",date(p.loan_due_at)].forEach(v=>{const td=document.createElement("td");td.textContent=v;tr.appendChild(td)});rows.appendChild(tr)});
      (Array.isArray(c.data)?c.data:[]).forEach(w=>{const tr=document.createElement("tr");const vals=[w.email||w.display_name||w.user_id,fmt(w.amount_usdt)+" USDT",fmt(w.fee_usdt)+" USDT",fmt(w.net_usdt)+" USDT",x[w.status]||w.status,date(w.created_at)];vals.forEach(v=>{const td=document.createElement("td");td.textContent=v;tr.appendChild(td)});const actions=document.createElement("td");if(w.status==="pending"){["approved","rejected"].forEach(decision=>{const btn=document.createElement("button");btn.type="button";btn.className="owner-review-btn";btn.textContent=decision==="approved"?x.approve:x.reject;btn.addEventListener("click",async()=>{if(!confirm((decision==="approved"?x.approve:x.reject)+"?"))return;btn.disabled=true;try{const result=await client.rpc("review_withdrawal_request",{p_request_id:w.id,p_decision:decision,p_note:null});if(result.error)throw result.error;await loadOwner()}catch(e){btn.disabled=false;panel.querySelector("[data-owner-message]").textContent=e.message||"Review failed"}});actions.appendChild(btn)})}else actions.textContent="—";tr.appendChild(actions);withdrawalRows.appendChild(tr)});
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


  async function loadPlayerWithdrawalRequests(){
    const list=document.getElementById("myWithdrawalRequests");if(!list||!client.auth)return;
    const labels={en:{pending:"Pending",approved:"Approved",rejected:"Rejected",paid:"Paid",cancelled:"Cancelled",empty:"No requests yet.",error:"Could not load requests: "},fr:{pending:"En attente",approved:"Approuvé",rejected:"Refusé",paid:"Payé",cancelled:"Annulé",empty:"Aucune demande.",error:"Chargement impossible : "},ar:{pending:"قيد المراجعة",approved:"مقبول",rejected:"مرفوض",paid:"مدفوع",cancelled:"ملغى",empty:"لا توجد طلبات حتى الآن.",error:"تعذر تحميل الطلبات: "}};
    const l=labels[language()];list.textContent="…";
    try{
      const r=await client.from("withdrawal_requests").select("id,amount_usdt,fee_usdt,net_usdt,status,created_at").order("created_at",{ascending:false}).limit(20);
      if(r.error)throw r.error;list.innerHTML="";
      if(!r.data?.length){list.textContent=l.empty;return;}
      r.data.forEach(w=>{const item=document.createElement("div");item.className="withdraw-request-item";const left=document.createElement("div"),amount=document.createElement("strong"),meta=document.createElement("small"),status=document.createElement("span");amount.textContent=fmt(w.amount_usdt)+" USDT";meta.textContent=new Date(w.created_at).toLocaleString();left.append(amount,meta);status.className="withdraw-status";status.textContent=l[w.status]||w.status;item.append(left,status);list.appendChild(item)});
    }catch(e){list.textContent=l.error+(e.message||"");}
  }

  function localizeWithdrawalForm(){
    const copy={
      en:{amount:"Amount to withdraw (USDT)",rules:"Minimum 10 USDT · Maximum 5,000 USDT · 5% fee · Weekly limit: 50% of internal USDT balance. Requests are reviewed manually. Accounts with outstanding loans cannot withdraw.",submit:"Submit withdrawal request",history:"My withdrawal requests",empty:"No requests yet.",walletRules:"Withdrawals: 10–5,000 USDT, 5% fee, and a weekly limit of 50% of internal USDT balance. Requests are reviewed manually. Outstanding loans prevent withdrawal.",manual:"Withdrawal requests are recorded for manual review. No automatic USDT payout is made."},
      fr:{amount:"Montant du retrait (USDT)",rules:"Minimum 10 USDT · Maximum 5 000 USDT · frais de 5 % · Limite hebdomadaire : 50 % du solde USDT interne. Les demandes sont examinées manuellement. Les comptes ayant un prêt impayé ne peuvent pas retirer.",submit:"Envoyer la demande de retrait",history:"Mes demandes de retrait",empty:"Aucune demande pour le moment.",walletRules:"Retraits : 10 à 5 000 USDT, frais de 5 % et limite hebdomadaire de 50 % du solde USDT interne. Examen manuel. Les prêts impayés bloquent les retraits.",manual:"Les demandes sont enregistrées pour examen manuel. Aucun paiement USDT automatique n’est effectué."},
      ar:{amount:"مبلغ السحب (USDT)",rules:"الحد الأدنى 10 USDT · الحد الأقصى 5,000 USDT · رسوم 5٪ · الحد الأسبوعي 50٪ من رصيد USDT الداخلي. الطلبات تخضع للمراجعة اليدوية، والحساب المدين لا يمكنه السحب.",submit:"إرسال طلب السحب",history:"طلبات السحب الخاصة بي",empty:"لا توجد طلبات حتى الآن.",walletRules:"السحب: من 10 إلى 5,000 USDT، رسوم 5٪، وحد أسبوعي 50٪ من رصيد USDT الداخلي. الطلبات تخضع للمراجعة اليدوية، والقروض المستحقة تمنع السحب.",manual:"تُسجّل طلبات السحب للمراجعة اليدوية، ولا يتم إرسال USDT تلقائياً."}
    }[language()];
    const set=(q,v)=>{const el=document.querySelector(q);if(el)el.textContent=v};
    set('label[for="withdrawalAmount"]',copy.amount);set('.withdraw-help',copy.rules);set('#withdrawalSubmit',copy.submit);set('[data-wallet-panel="withdraw"] .dpanelhead b',language()==="ar"?"طلب السحب":language()==="fr"?"Demande de retrait":"Withdrawal request");
    set("#myWithdrawalHistory",copy.history);set("#walletRulesText",copy.walletRules);set("#walletPreviewNote",copy.manual);
  }

  function bindWithdrawalForm(){
    const form=document.getElementById("withdrawalRequestForm");if(!form||form.dataset.bound)return;form.dataset.bound="1";
    form.addEventListener("submit",async e=>{
      e.preventDefault();const button=document.getElementById("withdrawalSubmit"),message=document.getElementById("withdrawalRequestMessage"),amount=Number(document.getElementById("withdrawalAmount").value);
      if(!Number.isFinite(amount)||amount<10||amount>5000){message.textContent=language()==="ar"?"أدخل مبلغاً بين 10 و5000 USDT.":"Enter an amount between 10 and 5,000 USDT.";return;}
      button.disabled=true;message.textContent=language()==="ar"?"جارٍ تسجيل الطلب…":"Submitting request…";
      try{const r=await client.rpc("create_withdrawal_request",{p_amount_usdt:amount});if(r.error)throw r.error;
        const d=Array.isArray(r.data)?r.data[0]:r.data;
        message.textContent=language()==="ar"?"تم تسجيل طلب السحب للمراجعة. الصافي بعد الرسوم: "+fmt(d.net_usdt)+" USDT":"Request recorded for manual review. Net after fee: "+fmt(d.net_usdt)+" USDT";
        form.reset();await loadPlayerWithdrawalRequests();
      }catch(err){message.textContent=(language()==="ar"?"تعذر تسجيل الطلب: ":"Request failed: ")+(err.message||"");}
      finally{button.disabled=false;}
    });
  }

  async function init(user) {
    if(!user)return;styles();localizeWithdrawalForm();bindWithdrawalForm();await Promise.all([loadLoan(),loadPlayerWithdrawalRequests()]);
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
      localizeWithdrawalForm();loadLoan();loadPlayerWithdrawalRequests();if(document.querySelector('[data-panel="owner"]'))loadOwner();
    },0);
  });
})();