from pathlib import Path
org = Path('pancernik.txt').read_text()
rev = '\n'.join([l[::-1] for l in org.split('\n')])
with open('pancernik_right.txt', 'w', newline='\n') as file:
    file.write(rev)