create or replace function private.repay_player_loan(p_amount_vor numeric)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.wallets%rowtype;
  v_loan public.player_loans%rowtype;
  v_payment numeric(20,4);
  v_transaction_id uuid;
  v_remaining numeric(20,4);
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_amount_vor is null or p_amount_vor <= 0 then
    raise exception 'Enter a repayment amount greater than zero' using errcode = '22023';
  end if;

  v_payment := round(p_amount_vor, 4);

  select *
    into v_wallet
    from public.wallets
   where user_id = v_user_id
     and currency = 'VOR'
   for update;

  if not found then
    raise exception 'VOR wallet not found' using errcode = 'P0002';
  end if;

  select *
    into v_loan
    from public.player_loans
   where user_id = v_user_id
   for update;

  if not found or v_loan.status <> 'outstanding' or v_loan.outstanding_vor <= 0 then
    raise exception 'No outstanding loan to repay' using errcode = 'P0002';
  end if;

  if v_payment > v_loan.outstanding_vor then
    raise exception 'Repayment exceeds the outstanding debt of % VOR', v_loan.outstanding_vor using errcode = '22023';
  end if;

  if v_payment > v_wallet.available_balance then
    raise exception 'Insufficient available VOR. Available: %, required: %', v_wallet.available_balance, v_payment using errcode = '23514';
  end if;

  v_remaining := round(v_loan.outstanding_vor - v_payment, 4);
  v_status := case when v_remaining = 0 then 'repaid' else 'outstanding' end;

  update public.wallets
     set total_balance = total_balance - v_payment,
         available_balance = available_balance - v_payment,
         updated_at = now()
   where user_id = v_user_id
     and currency = 'VOR';

  update public.player_loans
     set outstanding_vor = v_remaining,
         status = v_status,
         repaid_at = case when v_status = 'repaid' then now() else null end,
         repayment_method = 'wallet_available_balance'
   where id = v_loan.id;

  insert into public.wallet_transactions
    (user_id, transaction_type, amount, currency, status, reference_type, reference_id, description)
  values
    (v_user_id, 'loan_repayment', v_payment, 'VOR', 'completed', 'player_loan', v_loan.id,
     case when v_status = 'repaid'
       then 'Final loan repayment. Loan fully repaid.'
       else 'Partial loan repayment. Remaining debt: ' || v_remaining::text || ' VOR.'
     end)
  returning id into v_transaction_id;

  return jsonb_build_object(
    'success', true,
    'loan_id', v_loan.id,
    'transaction_id', v_transaction_id,
    'paid_vor', v_payment,
    'remaining_vor', v_remaining,
    'loan_status', v_status,
    'due_at', v_loan.due_at,
    'available_balance', v_wallet.available_balance - v_payment,
    'total_balance', v_wallet.total_balance - v_payment
  );
end;
$function$;

revoke all on function private.repay_player_loan(numeric) from public, anon;
grant execute on function private.repay_player_loan(numeric) to authenticated;

create or replace function public.repay_my_loan(p_amount_vor numeric)
returns jsonb
language sql
security invoker
set search_path = ''
as $function$
  select private.repay_player_loan(p_amount_vor);
$function$;

revoke all on function public.repay_my_loan(numeric) from public, anon;
grant execute on function public.repay_my_loan(numeric) to authenticated;
