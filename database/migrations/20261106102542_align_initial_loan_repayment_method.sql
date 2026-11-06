alter table public.player_loans
  alter column repayment_method set default 'wallet_available_balance';

update public.player_loans
   set repayment_method='wallet_available_balance'
 where status='outstanding';
