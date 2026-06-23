import sys
import os
import json
import re
import datetime

sys.stdout.reconfigure(encoding='utf-8')

trans_path = 'C:/Users/ACER/.gemini/antigravity/brain/22fcb295-5af0-468a-9363-71ad5af1f843/.system_generated/logs/transcript_full.jsonl'
lines = []
with open(trans_path, encoding='utf-8') as f:
    for line in f:
        lines.append(json.loads(line))

media_dir = 'C:/Users/ACER/.gemini/antigravity/brain/22fcb295-5af0-468a-9363-71ad5af1f843'
files = [f for f in os.listdir(media_dir) if f.endswith('.png') or f.endswith('.pdf')]

out_path = 'scratch/mapped_results.txt'
with open(out_path, 'w', encoding='utf-8') as out:
    for filename in sorted(files):
        m = re.search(r'media__(\d+)', filename)
        if not m:
            continue
        
        timestamp_ms = int(m.group(1))
        dt = datetime.datetime.fromtimestamp(timestamp_ms / 1000.0, datetime.timezone.utc)
        dt_str = dt.strftime('%Y-%m-%dT%H:%M:%SZ')
        out.write(f"File: {filename} ({dt_str})\n")
        
        close_steps = []
        for idx, obj in enumerate(lines):
            t_str = obj.get('created_at', '')
            if not t_str:
                continue
            try:
                o_dt = datetime.datetime.strptime(t_str, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=datetime.timezone.utc)
                diff = abs((o_dt - dt).total_seconds())
                if diff < 120: # within 2 minutes
                    content_snippet = obj.get('content', '')
                    if isinstance(content_snippet, str):
                        content_snippet = content_snippet.replace('\n', ' ')[:150]
                    else:
                        content_snippet = str(content_snippet)[:150]
                    close_steps.append((obj.get('step_index'), obj.get('source'), obj.get('type'), content_snippet))
            except Exception as e:
                pass
                
        for step in close_steps:
            out.write(f"  Step {step[0]} ({step[1]}, {step[2]}): {step[3]}\n")
        out.write("\n")

print("Mapped results written to scratch/mapped_results.txt")
