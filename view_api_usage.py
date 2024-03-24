"""

Usage:

    kubectl get all --all-namespaces -o json | python3 main.py

Easily take a peek at the APIs in use inside a cluster.
"""

import sys
import json

input = sys.stdin.read()
data = json.loads(input)

api_users = {}
for item in data['items']:
    key = f'{item["apiVersion"]}/{item["kind"]}'
    api_users.setdefault(key, [])
    api_users[key].append(item['metadata']['name'])

for api, users in api_users.items():
    print(f'=== {api} ===')
    print(', '.join(users))
    print('=' * (len(api) + 8), '\n')
