(() => {
  const client = vortERRAAuth;
  const language = () => {
    const v = (document.documentElement.lang || "en").toLowerCase();
    return v.startsWith("ar") ? "ar" : v.startsWith("fr") ? "fr" : "en";
  };
  const words = {
    en: {owner:"Owner Dashboard",title:"VORTERRA · OWNER CONTROL",subtitle:"Live platform figures from the database",refresh:"Refresh data",players:"Registered players",withdrawalCount:"Withdrawal requests",pendingWithdrawals:"Pending requests",pendingAmount:"Pending withdrawal value",cities:"Player cities",assets:"Owned facilities",total:"Total VOR balance",available:"Available VOR",reserved:"Reserved VOR",borrowers:"Indebted accounts",depositCount:"Confirmed deposit count",usdt:"Internal USDT",deposits:"Confirmed deposits",debt:"Outstanding loans",cohort:"Loan places issued",list:"Player accounts",withdrawalList:"Withdrawal requests",email:"Account",joined:"Joined",balance:"Wallet",debtValue:"Debt",due:"Due date",loading:"Loading live account data…",failed:"Could not load owner data: ",noLoan:"No outstanding loan",indebted:"IN DEBT",principal:"Original loan",outstanding:"Outstanding debt",issued:"Issue date",repayRule:"Repay from your available VOR balance at any time. Partial payments are allowed; the full balance is due within two months.",repayTitle:"Repay your loan",repayAmount:"Amount to repay (VOR)",repayButton:"Pay loan",repayWorking:"Processing repayment securely…",repaySuccess:"Repayment recorded: ",repayRemaining:"Remaining debt: ",repayFailed:"Repayment failed: ",daysLeft:"Days remaining",overdue:"Repayment deadline passed. Please clear the remaining debt.",dueSoon:"The loan must be fully repaid within two months of issue.",withdrawTitle:"Debt status before withdrawal",withdrawRule:"Withdrawals remain blocked until the loan is fully repaid. You can repay directly from your available VOR balance in the Loans section.",noDebt:"No outstanding loan is recorded for this account.",withdrawAmount:"Withdrawal amount",fee:"Fee",net:"Net payout",status:"Status",action:"Review",approve:"Approve",reject:"Reject",reviewing:"Saving decision…",requested:"Requested",pending:"Pending",approved:"Approved",rejected:"Rejected",paid:"Paid",cancelled:"Cancelled",adminOnly:"This panel is available only to the VORTERRA owner account."},
    fr: {owner:"Tableau du propriétaire",title:"VORTERRA · CONTRÔLE DU PROPRIÉTAIRE",subtitle:"Données réelles de la plateforme depuis la base de données",refresh:"Actualiser",players:"Joueurs inscrits",withdrawalCount:"Demandes de retrait",pendingWithdrawals:"Demandes en attente",pendingAmount:"Montant en attente",cities:"Villes des joueurs",assets:"Installations détenues",total:"Solde VOR total",available:"VOR disponibles",reserved:"VOR réservés",borrowers:"Comptes endettés",depositCount:"Nombre de dépôts confirmés",usdt:"USDT interne",deposits:"Dépôts confirmés",debt:"Prêts restants",cohort:"Prêts initiaux attribués",list:"Comptes joueurs",withdrawalList:"Demandes de retrait",email:"Compte",joined:"Inscription",balance:"Portefeuille",debtValue:"Dette",due:"Échéance",loading:"Chargement des données réelles…",failed:"Impossible de charger les données : ",noLoan:"Aucun prêt en cours",indebted:"ENDetté",principal:"Prêt initial",outstanding:"Dette restante",issued:"Date d’octroi",repayRule:"Remboursez à tout moment depuis votre solde VOR disponible. Les paiements partiels sont autorisés ; le prêt doit être entièrement remboursé sous deux mois.",repayTitle:"Rembourser votre prêt",repayAmount:"Montant à rembourser (VOR)",repayButton:"Payer le prêt",repayWorking:"Remboursement sécurisé en cours…",repaySuccess:"Remboursement enregistré : ",repayRemaining:"Dette restante : ",repayFailed:"Échec du remboursement : ",daysLeft:"Jours restants",overdue:"La date limite est dépassée. Veuillez régler la dette restante.",dueSoon:"Le prêt doit être entièrement remboursé dans les deux mois suivant son octroi.",withdrawTitle:"État de la dette avant retrait",withdrawRule:"Les retraits restent bloqués jusqu’au remboursement intégral du prêt. Vous pouvez rembourser directement depuis votre solde VOR disponible dans la section Prêts.",noDebt:"Aucun prêt impayé n’est enregistré.",withdrawAmount:"Montant",fee:"Frais",net:"Net à payer",status:"Statut",action:"Décision",approve:"Approuver",reject:"Refuser",reviewing:"Enregistrement…",requested:"Demandé",pending:"En attente",approved:"Approuvé",rejected:"Refusé",paid:"Payé",cancelled:"Annulé",adminOnly:"Ce panneau est réservé au compte propriétaire de VORTERRA."},
    ar: {owner:"لوحة تحكم المالك",title:"VORTERRA · لوحة إدارة المنصة",subtitle:"إحصائيات مباشرة من قاعدة البيانات",refresh:"تحديث البيانات",players:"اللاعبون المسجلون",withdrawalCount:"طلبات السحب",pendingWithdrawals:"طلبات قيد المراجعة",pendingAmount:"قيمة السحب المعلق",cities:"مدن اللاعبين",assets:"المنشآت المملوكة",total:"إجمالي أرصدة VOR",available:"أرصدة VOR المتاحة",reserved:"أرصدة VOR المحجوزة",borrowers:"الحسابات المدينة",depositCount:"عدد الإيداعات المؤكدة",usdt:"رصيد USDT الداخلي",deposits:"الإيداعات المؤكدة",debt:"القروض المتبقية",cohort:"القروض الممنوحة من الألف",list:"حسابات اللاعبين",withdrawalList:"طلبات السحب",email:"الحساب",joined:"تاريخ التسجيل",balance:"المحفظة",debtValue:"الدين",due:"موعد السداد",loading:"جارٍ تحميل بيانات الحسابات…",failed:"تعذر تحميل بيانات المالك: ",noLoan:"لا يوجد قرض مستحق",indebted:"مدان",principal:"قيمة القرض الأصلية",outstanding:"الدين المتبقي",issued:"تاريخ منح القرض",repayRule:"يمكنك السداد في أي وقت من رصيد VOR المتاح. يُسمح بالسداد الجزئي، ويجب تسديد كامل القرض خلال شهرين.",repayTitle:"سداد القرض",repayAmount:"مبلغ السداد (VOR)",repayButton:"دفع القرض",repayWorking:"جارٍ تنفيذ السداد بأمان…",repaySuccess:"تم تسجيل السداد: ",repayRemaining:"الدين المتبقي: ",repayFailed:"تعذر السداد: ",daysLeft:"الأيام المتبقية",overdue:"انتهت مهلة السداد. يرجى تسديد الدين المتبقي.",dueSoon:"يجب تسديد القرض بالكامل خلال شهرين من تاريخ منحه.",withdrawTitle:"حالة الدين قبل السحب",withdrawRule:"تظل عمليات السحب متوقفة حتى تسديد القرض بالكامل. يمكنك السداد مباشرة من رصيد VOR المتاح في قسم القروض.",noDebt:"لا يوجد دين قرض مستحق مسجل على هذا الحساب.",withdrawAmount:"المبلغ",fee:"الرسوم",net:"الصافي",status:"الحالة",action:"المراجعة",approve:"قبول",reject:"رفض",reviewing:"جارٍ حفظ القرار…",requested:"تاريخ الطلب",pending:"قيد المراجعة",approved:"مقبول",rejected:"مرفوض",paid:"مدفوع",cancelled:"ملغى",adminOnly:"هذه اللوحة مخصصة لحساب مالك VORTERRA فقط."}
  };
  const t = () => words[language()];
  const fmt = v => Number(v || 0).toLocaleString(language()==="ar"?"ar-DZ":"en-US",{minimumFractionDigits:2,maximumFractionDigits:2});
  const date = v => v ? new Date(v).toLocaleDateString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-GB") : "—";

  function styles() {
    if (document.getElementById("ownerDashboardStyles")) return;
    const s = document.createElement("style"); s.id = "ownerDashboardStyles";
    s.textContent = "#dashboard .owner-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));gap:12px;margin:18px 0}#dashboard .owner-stat{padding:16px;border:1px solid #d9b36e44;border-radius:12px;background:linear-gradient(145deg,#211b12,#090a0b)}#dashboard .owner-stat small{display:block;color:#cbb88e;font-size:10px}#dashboard .owner-stat strong{display:block;color:#ffe3a0;font-size:22px;margin-top:8px;overflow-wrap:anywhere}#dashboard .owner-table-wrap{overflow:auto;border:1px solid #d9b36e33;border-radius:12px}#dashboard .owner-table{width:100%;border-collapse:collapse;min-width:620px;font-size:11px}#dashboard .owner-table th,#dashboard .owner-table td{padding:11px;text-align:start;border-bottom:1px solid #ffffff12}#dashboard .owner-table th{color:#e8cb8f;background:#ffffff08}#dashboard .owner-table td{color:#ddd2bc}#dashboard .owner-toolbar{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}#dashboard .owner-refresh{padding:10px 15px;border:1px solid #e4c17c;border-radius:8px;background:#8b6428;color:#fff1d0;font-weight:700}#dashboard .wallet-activity-list{display:grid;gap:8px}#dashboard .wallet-activity-row{padding:11px 0;border-bottom:1px solid #d9b36e22}#dashboard .wallet-activity-row em{white-space:nowrap;font-style:normal;font-weight:700;color:#f3d99e}#dashboard .loan-live{padding:15px;border:1px solid #d9b36e55;border-radius:12px;background:linear-gradient(145deg,#201b13,#090a0b);display:grid;gap:12px;margin-bottom:12px}#dashboard .loan-live-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(135px,1fr));gap:10px}#dashboard .loan-live-grid div{padding:10px;background:#ffffff08;border-radius:8px}#dashboard .loan-live small{display:block;color:#c6b38b;font-size:10px;margin-bottom:5px}#dashboard .loan-live strong{color:#ffe3a0;font-size:16px;overflow-wrap:anywhere}#dashboard .loan-live p{color:#c9c0ad;font-size:11px;line-height:1.8;margin:0}#dashboard .loan-status{color:#ffcc8c;font-weight:800}#dashboard .loan-repay-form{display:grid;gap:9px;padding-top:12px;border-top:1px solid #d9b36e33}#dashboard .loan-repay-form label{font-size:11px;color:#e5ca95}#dashboard .loan-repay-form input{width:100%;box-sizing:border-box;padding:11px;border:1px solid #d9b36e66;border-radius:8px;background:#090a0b;color:#fff;font:inherit;direction:ltr}#dashboard .loan-repay-form button:disabled{opacity:.45;cursor:not-allowed}#dashboard .owner-review-btn{margin:2px;padding:6px 8px;border:1px solid #d9b36e66;border-radius:6px;background:#241a0e;color:#f2dca8;font-size:10px;cursor:pointer}#dashboard .owner-review-btn:disabled{opacity:.5}";
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
      const walletResult=await client.from("wallets").select("available_balance").maybeSingle();
      if(walletResult.error)throw walletResult.error;
      const available=Number(walletResult.data?.available_balance||0);
      const status=document.createElement("strong");status.className="loan-status";status.textContent=amount>0?x.indebted:x.noLoan;
      const grid=document.createElement("div");grid.className="loan-live-grid";
      [[x.principal,fmt(d.principal_vor)+" VOR"],[x.outstanding,fmt(amount)+" VOR"],[x.available,fmt(available)+" VOR"],[x.issued,date(d.issued_at)],[x.due,date(d.due_at)]].forEach(([label,value])=>{const cell=document.createElement("div"),small=document.createElement("small"),strong=document.createElement("strong");small.textContent=label;strong.textContent=value;cell.append(small,strong);grid.appendChild(cell)});
      const rule=document.createElement("p");rule.textContent=x.repayRule;card.replaceChildren(status,grid,rule);
      const dueTime=d.due_at?new Date(d.due_at).getTime():0;
      const days=dueTime?Math.ceil((dueTime-Date.now())/86400000):null;
      if(amount>0&&days!==null){const deadline=document.createElement("p");deadline.textContent=days<0?x.overdue:x.dueSoon+" "+x.daysLeft+": "+days;card.appendChild(deadline);}
      if(amount>0){
        const form=document.createElement("form");form.className="loan-repay-form";
        const title=document.createElement("strong");title.textContent=x.repayTitle;
        const label=document.createElement("label");label.textContent=x.repayAmount;
        const input=document.createElement("input");input.type="number";input.name="amount";input.min="0.0001";input.max=String(amount);input.step="0.0001";input.required=true;input.inputMode="decimal";input.placeholder="0.00";
        const button=document.createElement("button");button.type="submit";button.className="dprimary";button.textContent=x.repayButton;button.disabled=available<=0;
        const message=document.createElement("p");message.className="reg-message";message.setAttribute("role","status");message.setAttribute("aria-live","polite");
        form.append(title,label,input,button,message);card.appendChild(form);
        form.addEventListener("submit",async event=>{
          event.preventDefault();
          const payment=Number(input.value);
          if(!Number.isFinite(payment)||payment<=0||payment>amount){message.textContent=x.repayFailed+x.outstanding+": "+fmt(amount)+" VOR";return;}
          button.disabled=true;message.textContent=x.repayWorking;
          try{
            const result=await client.rpc("repay_my_loan",{p_amount_vor:payment});
            if(result.error)throw result.error;
            const data=Array.isArray(result.data)?result.data[0]:result.data;
            message.textContent=x.repaySuccess+fmt(data?.paid_vor??payment)+" VOR · "+x.repayRemaining+fmt(data?.remaining_vor??0)+" VOR";
            await loadLoan();
            await loadWalletActivity();
            const auth=await client.auth.getUser();
            if(auth.data?.user){
              if(typeof refreshWalletBalances==="function")await refreshWalletBalances(auth.data.user);
              await loadPlayerOverview(auth.data.user);
            }
          }catch(error){message.textContent=x.repayFailed+(error.message||"");button.disabled=false;}
        });
      }
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
    set("#myWithdrawalHistory",copy.history);set("#walletRulesText",copy.walletRules);set("#walletStatusNote",copy.manual);
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

  let projectCatalogCache = null;
  async function getProjectCatalog(){
    if(projectCatalogCache)return projectCatalogCache;
    const r=await fetch("data/projects.json",{cache:"no-store"});
    if(!r.ok)throw new Error("Project catalogue unavailable");
    const d=await r.json();
    projectCatalogCache=(d.projects||[]).slice().sort((a,b)=>a.number-b.number);
    return projectCatalogCache;
  }
  async function loadActualProjectData(user){
    try{
      const [catalog,assetsResult]=await Promise.all([
        getProjectCatalog(),
        client.from("player_projects").select("id,city_id,project_key,acquisition_type,acquired_at,expires_at,condition_percent").eq("owner_id",user.id).order("acquired_at",{ascending:false})
      ]);
      if(assetsResult.error)throw assetsResult.error;
      const assets=assetsResult.data||[];
      const grid=document.getElementById("ownedProjects"),empty=document.getElementById("cityEmpty");
      if(grid){
        grid.innerHTML="";
        assets.forEach(asset=>{
          const p=catalog.find(x=>x.id===asset.project_key);if(!p)return;
          const card=document.createElement("article");card.className="downed-card";
          const h=document.createElement("h3");h.textContent=p.name?.[language()]||p.name?.en||p.id;
          const detail=document.createElement("p");
          const isBuy=asset.acquisition_type==="purchase";
          const price=isBuy?p.purchase_price:p.monthly_rent;
          detail.textContent=(isBuy?(language()==="ar"?"شراء":"Purchase"):(language()==="ar"?"إيجار شهري":"Monthly rent"))+" · "+fmt(price)+" VOR";
          const meta=document.createElement("small");
          meta.textContent=(language()==="ar"?"ضمن أصول حسابك":language()==="fr"?"Dans vos actifs":"In your account assets")+(asset.expires_at&&!isBuy?" · "+(language()==="ar"?"ينتهي ":"Expires ")+date(asset.expires_at):"");
          card.append(h,detail,meta);grid.appendChild(card);
        });
      }
      if(empty)empty.hidden=assets.length>0;
      const note=document.getElementById("projectOwnershipNote");
      if(note)note.textContent=language()==="ar"?"الملكية والمدفوعات محفوظة في قاعدة البيانات.":"Ownership and payments are stored in the database.";
      const cards=[...document.querySelectorAll("#projectGrid .dproject-card")];
      cards.forEach((card,index)=>{
        const project=catalog[index];if(!project)return;
        const active=assets.some(a=>a.project_key===project.id&&(a.acquisition_type==="purchase"||(a.expires_at&&new Date(a.expires_at)>new Date())));
        const actions=card.querySelector(".dproject-actions");
        if(active&&actions){
          actions.innerHTML="";
          const label=document.createElement("button");label.type="button";label.disabled=true;
          label.textContent=language()==="ar"?"تم اقتناؤه":language()==="fr"?"Déjà acquis":"Already acquired";
          actions.appendChild(label);
        }
      });
    }catch(e){console.warn("Could not load real project ownership:",e);}
  }

  async function handleProjectAcquisitionClick(event){
    const button=event.target.closest("#projectGrid .dproject-actions button");
    if(!button)return;
    event.preventDefault();event.stopImmediatePropagation();
    if(button.disabled)return;
    button.disabled=true;
    try{
      const userResult=await client.auth.getUser();
      const user=userResult.data?.user;
      if(userResult.error||!user)throw new Error(language()==="ar"?"سجّل الدخول أولاً.":"Please sign in first.");
      const card=button.closest(".dproject-card");
      const cards=[...document.querySelectorAll("#projectGrid .dproject-card")];
      const index=cards.indexOf(card);
      const catalog=await getProjectCatalog();
      const project=catalog[index];
      if(!project)throw new Error("Project not found");
      const actionIndex=[...card.querySelectorAll(".dproject-actions button")].indexOf(button);
      const mode=actionIndex===0?"purchase":"monthly_rent";
      const price=mode==="purchase"?project.purchase_price:project.monthly_rent;
      const question=language()==="ar"?(mode==="purchase"?"تأكيد شراء "+project.name.ar+" مقابل "+price+" VOR؟":"تأكيد إيجار "+project.name.ar+" شهرياً مقابل "+price+" VOR؟"):(mode==="purchase"?"Confirm purchase for "+price+" VOR?":"Confirm first month rent for "+price+" VOR?");
      if(!window.confirm(question))return;
      const result=await client.rpc("acquire_vorterra_project",{
        p_project_key:project.id,p_city_id:null,p_acquisition_type:mode
      });
      if(result.error)throw result.error;
      const wallet=await client.from("wallets").select("available_balance").eq("user_id",user.id).eq("currency","VOR").maybeSingle();
      if(!wallet.error&&wallet.data){
        const balance=document.querySelector("#dashboard .dbalance b");
        if(balance)balance.textContent=fmt(wallet.data.available_balance)+" VOR";
        const available=document.getElementById("walletAvailableBalance");
        if(available)available.textContent=fmt(wallet.data.available_balance)+" VOR";
      }
      alert(language()==="ar"?"تمت العملية بنجاح. خُصم "+fmt(result.data.amount_vor)+" VOR من محفظتك.":"Success. "+fmt(result.data.amount_vor)+" VOR was charged to your wallet.");
      await loadActualProjectData(user);
      await loadPlayerOverview(user);
      if(typeof window.refreshVorterraOperations==="function")await window.refreshVorterraOperations();
    }catch(e){
      console.error("Project acquisition failed:",e);
      alert(e.message||"Project acquisition failed");
    }finally{button.disabled=false;}
  }
  document.addEventListener("click",handleProjectAcquisitionClick,true);


  const playerNumber = value => Number(value||0).toLocaleString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-US",{minimumFractionDigits:0,maximumFractionDigits:2});
  const marketWords = {
    en:{empty:"No active player listings yet.",mine:"Your listing",player:"Player",sale:"For sale",rent:"For rent",qty:"Quantity",unit:"Unit price",duration:"Duration",remove:"Remove listing",posted:"Listing published to the live marketplace.",removed:"Listing removed.",login:"Sign in to use the marketplace.",failed:"Could not load marketplace: ",createFailed:"Could not publish listing: ",productRequired:"Enter a product, quantity and unit price.",assetRequired:"Enter an asset, rent price and duration."},
    fr:{empty:"Aucune annonce active pour le moment.",mine:"Votre annonce",player:"Joueur",sale:"À vendre",rent:"À louer",qty:"Quantité",unit:"Prix unitaire",duration:"Durée",remove:"Supprimer l’annonce",posted:"Annonce publiée sur le marché.",removed:"Annonce supprimée.",login:"Connectez-vous pour utiliser le marché.",failed:"Impossible de charger le marché : ",createFailed:"Publication impossible : ",productRequired:"Saisissez le produit, la quantité et le prix unitaire.",assetRequired:"Saisissez l’actif, le prix de location et la durée."},
    ar:{empty:"لا توجد عروض نشطة من اللاعبين حتى الآن.",mine:"عرضك",player:"لاعب",sale:"للبيع",rent:"للإيجار",qty:"الكمية",unit:"سعر الوحدة",duration:"المدة",remove:"حذف العرض",posted:"تم نشر العرض في السوق الفعلي.",removed:"تم حذف العرض.",login:"سجّل الدخول لاستخدام السوق.",failed:"تعذر تحميل السوق: ",createFailed:"تعذر نشر العرض: ",productRequired:"أدخل المنتج والكمية وسعر الوحدة.",assetRequired:"أدخل الأصل وسعر الإيجار والمدة."}
  };
  const mw=()=>marketWords[language()];
  const safeMarketText=value=>String(value??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  async function getSignedInPlayer(){
    const {data,error}=await client.auth.getUser();
    if(error)throw error;
    if(!data?.user)throw new Error(mw().login);
    return data.user;
  }
  async function renderLiveMarket(){
    const ids=["mySaleListings","saleListings","rentListings"];
    ids.forEach(id=>{const el=document.getElementById(id);if(el)el.innerHTML="";});
    try{
      const user=await getSignedInPlayer();
      const {data,error}=await client.from("market_listings").select("id,owner_id,listing_type,product_name,quantity,unit_price,asset_name,rent_duration,created_at").eq("status","active").order("created_at",{ascending:false}).limit(100);
      if(error)throw error;
      const rows=data||[];
      const mine=rows.filter(x=>x.owner_id===user.id);
      const sales=rows.filter(x=>x.listing_type==="sale");
      const rents=rows.filter(x=>x.listing_type==="rent");
      const draw=(id,items,type)=>{
        const el=document.getElementById(id);if(!el)return;
        el.innerHTML="";
        if(!items.length){const empty=document.createElement("div");empty.className="dempty";empty.textContent=mw().empty;el.appendChild(empty);return;}
        items.forEach(item=>{
          const card=document.createElement("article");card.className="dlisting";
          const info=document.createElement("div");
          const title=document.createElement("strong");title.textContent=type==="sale"?item.product_name:item.asset_name;
          const detail=document.createElement("small");
          detail.textContent=type==="sale"
            ? mw().qty+": "+playerNumber(item.quantity)+" · "+mw().unit+": "+playerNumber(item.unit_price)+" VOR"
            : mw().unit+": "+playerNumber(item.unit_price)+" VOR · "+mw().duration+": "+item.rent_duration;
          const who=document.createElement("small");who.textContent=item.owner_id===user.id?mw().mine:mw().player;
          info.append(title,detail,who);card.appendChild(info);
          if(item.owner_id===user.id){
            const del=document.createElement("button");del.type="button";del.textContent=mw().remove;
            del.addEventListener("click",async()=>{
              del.disabled=true;
              try{const {error}=await client.from("market_listings").delete().eq("id",item.id).eq("owner_id",user.id);if(error)throw error;await renderLiveMarket();}
              catch(err){alert(mw().failed+(err.message||""));del.disabled=false;}
            });
            card.appendChild(del);
          }
          el.appendChild(card);
        });
      };
      draw("mySaleListings",mine.filter(x=>x.listing_type==="sale"),"sale");
      draw("saleListings",sales.filter(x=>x.owner_id!==user.id),"sale");
      draw("rentListings",rents,"rent");
      const note=document.getElementById("marketLiveNote");if(note)note.textContent=language()==="ar"?"العروض تُقرأ مباشرة من قاعدة بيانات VORTERRA.":language()==="fr"?"Les annonces sont chargées directement depuis la base VORTERRA.":"Listings are loaded directly from the VORTERRA database.";
    }catch(err){
      console.warn("Live marketplace:",err);
      const note=document.getElementById("marketLiveNote");if(note)note.textContent=mw().failed+(err.message||"");
    }
  }
  function bindLiveMarketForms(){
    const bind=(id,type)=>{
      const form=document.getElementById(id);if(!form||form.dataset.liveBound)return;form.dataset.liveBound="1";
      form.addEventListener("submit",async event=>{
        event.preventDefault();if(!form.reportValidity())return;
        const button=form.querySelector('button[type="submit"]');if(button)button.disabled=true;
        try{
          const user=await getSignedInPlayer();const fd=new FormData(form);
          let row;
          if(type==="sale"){
            const product=String(fd.get("product")||"").trim(),quantity=Number(fd.get("quantity")),price=Number(fd.get("price"));
            if(!product||!Number.isFinite(quantity)||quantity<=0||!Number.isFinite(price)||price<=0)throw new Error(mw().productRequired);
            row={owner_id:user.id,listing_type:"sale",product_name:product,quantity,unit_price:price};
          }else{
            const asset=String(fd.get("asset")||"").trim(),price=Number(fd.get("price")),duration=String(fd.get("duration")||"").trim();
            if(!asset||!Number.isFinite(price)||price<=0||!duration)throw new Error(mw().assetRequired);
            row={owner_id:user.id,listing_type:"rent",asset_name:asset,unit_price:price,rent_duration:duration};
          }
          const {error}=await client.from("market_listings").insert(row);if(error)throw error;
          form.reset();await renderLiveMarket();alert(mw().posted);
        }catch(err){alert(mw().createFailed+(err.message||""));}
        finally{if(button)button.disabled=false;}
      });
    };
    bind("marketSellForm","sale");bind("marketRentForm","rent");
    document.querySelectorAll("#dashboard [data-market-tab]").forEach(b=>{if(b.dataset.liveTabBound)return;b.dataset.liveTabBound="1";b.addEventListener("click",()=>renderLiveMarket());});
  }
  async function loadWalletActivity(){
    const target=document.getElementById("walletActivityList");if(!target)return;
    const labels={
      en:{empty:"No wallet transactions yet.",failed:"Could not load wallet activity: ",completed:"Completed",pending:"Pending",rejected:"Rejected",cancelled:"Cancelled"},
      fr:{empty:"Aucune transaction pour le moment.",failed:"Impossible de charger l’activité : ",completed:"Terminée",pending:"En attente",rejected:"Refusée",cancelled:"Annulée"},
      ar:{empty:"لا توجد معاملات مالية مسجلة بعد.",failed:"تعذر تحميل سجل المحفظة: ",completed:"مكتملة",pending:"قيد الانتظار",rejected:"مرفوضة",cancelled:"ملغاة"}
    }[language()];
    target.innerHTML="";
    try{
      const {data,error}=await client.from("wallet_transactions")
        .select("id,transaction_type,amount,currency,status,description,created_at")
        .order("created_at",{ascending:false}).limit(50);
      if(error)throw error;
      if(!data?.length){const empty=document.createElement("div");empty.className="wallet-empty";empty.textContent=labels.empty;target.appendChild(empty);return;}
      const debitTypes=new Set(["project_purchase","project_monthly_rent","conversion_out","loan_repayment","market_purchase","withdrawal"]);
      data.forEach(item=>{
        const row=document.createElement("article");row.className="dactivity wallet-activity-row";
        const icon=document.createElement("i");icon.textContent=debitTypes.has(item.transaction_type)?"↘":"↗";
        const info=document.createElement("div");
        const title=document.createElement("b");title.textContent=item.description||String(item.transaction_type||"").replaceAll("_"," ");
        const meta=document.createElement("small");
        const when=new Date(item.created_at).toLocaleString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-GB");
        const state=labels[item.status]||item.status||"";
        meta.textContent=when+" · "+state;
        const amount=document.createElement("em");
        const sign=debitTypes.has(item.transaction_type)?"−":"+";
        amount.textContent=sign+fmt(item.amount)+" "+item.currency;
        info.append(title,meta);row.append(icon,info,amount);target.appendChild(row);
      });
    }catch(error){
      const message=document.createElement("div");message.className="wallet-empty";message.textContent=labels.failed+(error.message||"");target.appendChild(message);
    }
  }

  async function loadPlayerOverview(user){
    const ids=["playerOverviewBalance","playerOverviewAssets","playerOverviewContracts","playerOverviewWorkers"];
    try{
      const [walletResult,assetsResult,activityResult,contractResult]=await Promise.all([
        client.from("wallets").select("total_balance,available_balance").eq("user_id",user.id).eq("currency","VOR").maybeSingle(),
        client.from("player_projects").select("id",{count:"exact",head:true}).eq("owner_id",user.id),
        client.from("wallet_transactions").select("id,transaction_type,amount,currency,status,description,created_at").eq("user_id",user.id).order("created_at",{ascending:false}).limit(5),
        client.from("player_employment_contracts").select("id",{count:"exact",head:true}).eq("status","active")
      ]);
      if(walletResult.error)throw walletResult.error;
      if(assetsResult.error)throw assetsResult.error;
      if(activityResult.error)throw activityResult.error;
      if(contractResult.error)throw contractResult.error;
      const balance=document.getElementById(ids[0]);
      if(balance)balance.innerHTML=playerNumber(walletResult.data?.available_balance||0)+' <small>VOR</small>';
      const assets=document.getElementById(ids[1]);if(assets)assets.textContent=String(assetsResult.count||0).padStart(2,"0");
      const activeContracts=contractResult.count||0;
      const contracts=document.getElementById(ids[2]);if(contracts)contracts.textContent=String(activeContracts).padStart(2,"0");
      const workers=document.getElementById(ids[3]);if(workers)workers.textContent=String(activeContracts).padStart(2,"0");
      const contractsNote=document.getElementById("playerOverviewContractsNote");
      if(contractsNote)contractsNote.textContent=language()==="ar"?"مرتبطة بمشاريع مملوكة":language()==="fr"?"Liés aux projets détenus":"Linked to owned projects";
      const workersNote=document.getElementById("playerOverviewWorkersNote");
      if(workersNote)workersNote.textContent=language()==="ar"?"عمال بعقود نشطة":language()==="fr"?"Travailleurs sous contrat actif":"Workers under active contracts";
      const activity=document.getElementById("playerRecentActivity");
      if(activity){
        activity.innerHTML="";
        const records=activityResult.data||[];
        if(!records.length){const empty=document.createElement("div");empty.className="dempty";empty.textContent=language()==="ar"?"لا توجد حركات مالية مسجلة بعد.":language()==="fr"?"Aucune activité financière enregistrée.":"No financial activity recorded yet.";activity.appendChild(empty);}
        records.forEach(item=>{
          const row=document.createElement("div");row.className="dactivity";
          const icon=document.createElement("i");icon.textContent="◈";
          const info=document.createElement("div");const title=document.createElement("b");title.textContent=item.description||item.transaction_type.replaceAll("_"," ");
          const meta=document.createElement("small");meta.textContent=new Date(item.created_at).toLocaleString(language()==="ar"?"ar-DZ":language()==="fr"?"fr-FR":"en-GB");
          const amount=document.createElement("em");amount.textContent=(item.amount>0?"+":"")+playerNumber(item.amount)+" "+item.currency;
          info.append(title,meta);row.append(icon,info,amount);activity.appendChild(row);
        });
      }
    }catch(err){console.warn("Player overview data:",err);const activity=document.getElementById("playerRecentActivity");if(activity)activity.textContent=language()==="ar"?"تعذر تحميل بيانات الحساب.": "Could not load account data: "+(err.message||"");}
  }

  async function init(user) {
    if(!user)return;styles();localizeWithdrawalForm();bindWithdrawalForm();bindLiveMarketForms();await Promise.all([loadLoan(),loadPlayerWithdrawalRequests(),loadActualProjectData(user),loadPlayerOverview(user),loadWalletActivity(),renderLiveMarket()]);
    if(typeof window.refreshVorterraOperations==="function")await window.refreshVorterraOperations();
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