create table profiles(id uuid primary key references auth.users on delete cascade, username text, coins int not null default 0, verify_status text not null default 'none', verified bool not null default false, is_admin bool not null default false);
create table videos(id bigint generated always as identity primary key, user_id uuid default auth.uid() references profiles(id) on delete cascade, username text, verified bool default false, title text, url text not null, likes int default 0, status text default 'published', created_at timestamptz default now());
create table topups(id bigint generated always as identity primary key, user_id uuid default auth.uid() references profiles(id), username text, amount int not null check(amount>0), status text default 'pending', pay_link text, created_at timestamptz default now());
create table withdrawals(id bigint generated always as identity primary key, user_id uuid default auth.uid() references profiles(id), username text, amount int not null check(amount>0), method text, status text default 'pending', created_at timestamptz default now());

create function is_admin() returns bool language sql security definer stable as $$ select coalesce((select p.is_admin from profiles p where p.id=auth.uid()),false) $$;
create function on_signup() returns trigger language plpgsql security definer as $$ begin insert into profiles(id,username) values(new.id, coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1))); return new; end $$;
create trigger t_signup after insert on auth.users for each row execute function on_signup();
create function on_video() returns trigger language plpgsql security definer as $$ begin select p.username,p.verified into new.username,new.verified from profiles p where p.id=new.user_id; return new; end $$;
create trigger t_video before insert on videos for each row execute function on_video();
create function on_req() returns trigger language plpgsql security definer as $$ begin select p.username into new.username from profiles p where p.id=new.user_id; return new; end $$;
create trigger t_top before insert on topups for each row execute function on_req();
create trigger t_wd before insert on withdrawals for each row execute function on_req();

alter table profiles enable row level security; alter table videos enable row level security;
alter table topups enable row level security; alter table withdrawals enable row level security;
create policy p1 on profiles for select using(id=auth.uid() or is_admin());
create policy v1 on videos for select using(status='published' or is_admin());
create policy v2 on videos for insert with check(user_id=auth.uid());
create policy v3 on videos for update using(is_admin());
create policy v4 on videos for delete using(is_admin());
create policy t1 on topups for select using(user_id=auth.uid() or is_admin());
create policy t2 on topups for insert with check(user_id=auth.uid());
create policy t3 on topups for update using(is_admin());
create policy w1 on withdrawals for select using(user_id=auth.uid() or is_admin());

create function request_verify() returns void language sql security definer as $$ update profiles set verify_status='pending' where id=auth.uid() and verify_status in ('none','rejected') $$;
create function request_withdraw(a int, m text) returns void language plpgsql security definer as $$ begin
 update profiles set coins=coins-a where id=auth.uid() and coins>=a and a>0;
 if not found then raise exception 'الرصيد غير كاف'; end if;
 insert into withdrawals(user_id,amount,method) values(auth.uid(),a,m); end $$;
create function like_video(v bigint) returns void language sql security definer as $$ update videos set likes=likes+1 where id=v $$;
create function admin_verify(u uuid, ok bool) returns void language plpgsql security definer as $$ begin
 if not is_admin() then raise exception 'denied'; end if;
 update profiles set verify_status=case when ok then 'approved' else 'rejected' end, verified=ok where id=u;
 update videos set verified=ok where user_id=u; end $$;
create function admin_topup_paid(t bigint) returns void language plpgsql security definer as $$ declare r topups; begin
 if not is_admin() then raise exception 'denied'; end if;
 update topups set status='paid' where id=t and status<>'paid' returning * into r;
 if found then update profiles set coins=coins+r.amount where id=r.user_id; end if; end $$;
create function admin_withdraw(w bigint, ok bool) returns void language plpgsql security definer as $$ declare r withdrawals; begin
 if not is_admin() then raise exception 'denied'; end if;
 update withdrawals set status=case when ok then 'paid' else 'rejected' end where id=w and status='pending' returning * into r;
 if found and not ok then update profiles set coins=coins+r.amount where id=r.user_id; end if; end $$;

insert into storage.buckets(id,name,public) values('videos','videos',true) on conflict do nothing;
create policy s1 on storage.objects for insert to authenticated with check(bucket_id='videos');
