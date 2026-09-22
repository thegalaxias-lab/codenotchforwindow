from pathlib import Path

p = Path(r"C:\Program Files\Grok Bot\resources\app.asar")
data = p.read_bytes()
needles = [
    b"usagePercent",
    b"productUsage",
    b"GrokBot",
    b"grok_bot",
    b"GetGrok",
    b"Billing",
    b"rateLimit",
    b"Weekly Grok",
    b"SuperGrok Heavy",
    b"usage-summary",
    b"cli-chat-proxy",
    b"grok_api",
    b"GetUsage",
    b"Bot Limit",
    b"usageLimits",
    b"includedUsage",
    b"GetRateLimits",
    b"subscription_tier",
    b"agent-computer",
    b"computePool",
]
for n in needles:
    idx = 0
    hits = 0
    while hits < 6:
        i = data.find(n, idx)
        if i < 0:
            break
        start = max(0, i - 90)
        end = min(len(data), i + 140)
        chunk = data[start:end]
        s = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        print(f"--- {n.decode(errors='replace')} @ {i} ---")
        print(s)
        hits += 1
        idx = i + len(n)
    if hits == 0:
        print(f"(no hits for {n.decode(errors='replace')})")
