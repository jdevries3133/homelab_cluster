from datetime import datetime
import json
from pathlib import Path
import random
from time import sleep

replicated = Path('/replicated/jokes.log')
local = Path('/local/jokes.log')


# ensure the log file exists in both volumes
for p in (replicated, local):
    if not p.exists():
        with open(p, 'w') as f:
            f.write('')


with open('jokes.json', 'r') as fp:
    jokes = [j['body'] for j in json.load(fp)]


while True:
    joke = random.choice(jokes)
    now = datetime.now().strftime("%y-%m-%d -- %H:%M:%S")
    msg = f'[{now}] :: {joke}\n'

    with open(replicated,   'a+') as fp: fp.write(msg)
    with open(local,        'a+') as fp: fp.write(msg)

    sleep(1)
