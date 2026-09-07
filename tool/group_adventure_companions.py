"""Owner-authorized disposable companions for one fixed production lobby.

Credentials never leave memory. Cleanup waits for completion AND every real
participant's reward acknowledgement, because deleting participants earlier
would change the participant count in the reward response. Safe to rerun.
"""
import datetime
import json
import pathlib
import secrets
import subprocess
import sys
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path(__file__).resolve().parent.parent
CLI = ROOT / '.tools/supabase-2.115.0/supabase.exe'
PROJECT = 'tnzathhutuwmohmjfrlo'
BASE = 'https://' + PROJECT + '.supabase.co'
HOST = '55e93ae4-a734-433c-a126-0edb303cb33e'
LOBBY = '2abfc0ab-e313-466a-9a64-11346dfcdc29'
MARKER = 'companions-4132f5c7-20260907'
STATE = ROOT / '.tools/group-companions-state.json'


def cli(*args):
    result = subprocess.run([str(CLI), *args, '--output', 'json'], cwd=ROOT,
                            capture_output=True, text=True, encoding='utf-8')
    if result.returncode:
        raise RuntimeError('Operator CLI failed; no credential output recorded.')
    return json.loads(result.stdout)


def query(sql):
    return cli('db', 'query', '--linked', '--project-ref', PROJECT, sql)['rows']


def call(path, key, body=None, method=None, token=None):
    request = urllib.request.Request(BASE + path,
        headers={'apikey': key, 'Authorization': 'Bearer ' + (token or key),
                 'Content-Type': 'application/json', 'User-Agent': 'DragonHaven-Companions/1.0'},
        data=None if body is None else json.dumps(body).encode('utf-8'),
        method=method or ('GET' if body is None else 'POST'))
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read(2 * 1024 * 1024)
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raise RuntimeError('Companion request failed: HTTP ' + str(error.code)) from None


def lobby():
    return query(f"""select l.id, l.status, l.ends_at, l.slot=private.group_adventure_slot(now()) as current_slot,
        l.required_players, (select count(*) from public.group_adventure_participants p where p.lobby_id=l.id) as participants
        from public.group_adventure_lobbies l join public.profiles h on h.user_id=l.owner_id
        where l.id='{LOBBY}' and l.owner_id='{HOST}' and h.keeper_code='DH-4132F5C7'""")[0]


def marked():
    return query(f"""select u.id, p.display_name,
        exists(select 1 from public.group_adventure_participants gp where gp.user_id=u.id and gp.lobby_id='{LOBBY}') as joined
        from auth.users u join public.profiles p on p.user_id=u.id
        where u.raw_app_meta_data->>'dragonhaven_companions'='{MARKER}'
        and u.email like '%@dragonhaven-companions.invalid'""")


def save():
    evidence = {'lobby': lobby(), 'accounts': marked(),
                'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat()}
    STATE.write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    print(json.dumps(evidence))


def main():
    mode = sys.argv[1] if len(sys.argv) == 2 else 'inspect'
    if mode not in ('inspect', 'join', 'cleanup'):
        raise RuntimeError('Unknown bounded companion action.')
    if mode == 'inspect':
        save()
        return
    keys = cli('projects', 'api-keys', '--project-ref', PROJECT, '--reveal')
    if isinstance(keys, dict):
        keys = keys.get('api_keys', keys.get('keys', []))
    key = next(k['api_key'] for k in keys if k['name'] == 'service_role')
    if mode == 'cleanup':
        # No gameplay clock manipulation or reward acknowledgement on behalf of
        # the real Keeper. Completed timestamps alone are insufficient.
        eligible = query(f"""select l.status='completed' and not exists(
            select 1 from public.group_adventure_participants p join auth.users u on u.id=p.user_id
            where p.lobby_id=l.id and p.reward_acknowledged_at is null
            and coalesce(u.raw_app_meta_data->>'dragonhaven_companions','') <> '{MARKER}') as ready
            from public.group_adventure_lobbies l where l.id='{LOBBY}' and l.owner_id='{HOST}'""")
        if not eligible or not eligible[0]['ready']:
            print('WAIT: adventure or real participant reward acknowledgement pending; no accounts removed.')
            return
        for account in marked():
            owner = str(uuid.UUID(account['id']))
            # Refuse removal if a companion was placed in another adventure.
            busy = query(f"select count(*) as n from public.group_adventure_participants p join public.group_adventure_lobbies l on l.id=p.lobby_id where p.user_id='{owner}' and l.id<>'{LOBBY}' and (l.status<>'completed' or p.reward_acknowledged_at is null)")[0]['n']
            if busy:
                raise RuntimeError('Companion has another unsettled adventure; cleanup held.')
            call('/auth/v1/admin/users/' + owner, key, method='DELETE')
        save()
        return
    for name in ('Love', 'Kisses', 'Hugs'):
        current = lobby()
        if current['status'] != 'waiting' or not current['current_slot'] or current['participants'] >= current['required_players']:
            break
        previous = next((a for a in marked() if a['display_name'] == name), None)
        if previous and previous['joined']:
            continue
        password = secrets.token_urlsafe(32) + 'Dh7!'
        address = f'{MARKER}-{name.lower()}@dragonhaven-companions.invalid'
        if previous:
            owner = str(uuid.UUID(previous['id']))
            call('/auth/v1/admin/users/' + owner, key, {'password': password}, 'PUT')
        else:
            created = call('/auth/v1/admin/users', key, {'email': address, 'password': password,
                'email_confirm': True, 'user_metadata': {'display_name': name},
                'app_metadata': {'dragonhaven_companions': MARKER, 'lobby_id': LOBBY}})
            owner = str(uuid.UUID(created['id']))
        # Friendship is prerequisite for the authorized join. Create only the
        # synthetic companion -> fixed Keeper relationship, never impersonate her.
        exists = query(f"select count(*) as n from public.friendships where requester_id='{owner}' and addressee_id='{HOST}'")[0]['n']
        if not exists:
            call('/rest/v1/friendships', key, {'requester_id': owner, 'addressee_id': HOST,
                'status': 'accepted', 'responded_at': datetime.datetime.now(datetime.timezone.utc).isoformat()})
        session = call('/auth/v1/token?grant_type=password', key, {'email': address, 'password': password})
        # Normal bounded RPC validates the synthetic dragon, free slots,
        # combined requirements, start time and rewards. No host save is touched.
        call('/rest/v1/rpc/join_group_adventure_lobby', key, {'p_lobby_id': LOBBY,
             'p_dragon': {'client_id': f'companion-{name.lower()}', 'name': name,
                          'lineage_id': 'thunderpuff', 'stage': 'ascended', 'xp': 2600,
                          'might': 10, 'arcana': 10, 'spirit': 10, 'evolution_path': 'arcana',
                          'prismatic': False, 'sinister': False}}, token=session['access_token'])
        save()
    save()


if __name__ == '__main__':
    main()
