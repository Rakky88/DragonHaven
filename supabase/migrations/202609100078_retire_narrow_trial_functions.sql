-- Migration 75 replaced these entry points with bigint-safe implementations.
-- Retaining their old bodies leaves unreachable functions with invalid row
-- types. RESTRICT deliberately refuses any unexpected stored dependency.
drop function public.complete_seasonal_trial_attempt_v74(uuid,text,integer,integer,integer,integer) restrict;
drop function public.get_trial_rankings_v74(text,text,integer) restrict;
drop function public.get_seasonal_trial_rankings_v74(text,text,boolean,integer) restrict;
drop function public.finalize_my_seasonal_event_prizes_v74() restrict;
drop function public.list_seasonal_chronicle_v74() restrict;
drop function public.get_my_profile_v74() restrict;
drop function public.list_my_friends_v74() restrict;
