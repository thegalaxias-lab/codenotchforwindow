from pathlib import Path

p = Path(r"C:\Program Files\Grok Bot\resources\app.asar")
data = p.read_bytes()
needles = [
    b"GetSandAccessStatus",
    b"sandUsagePercent",
    b"SandAccess",
    b"nextResetTimestampUtc",
    b"hasAvailableUsage",
    b"DashboardService",
    b"getAggregatedUsage",
    b"api2.cursor.sh",
    b"api2.grok",
    b"sand.",
    b"GetHardLimit",
    b"usagePercent",
    b"Grok Bot Plan",
    b"weeklyUsage",
    b"agent.api",
    b"backendUrl",
    b"BASE_URL",
]
for n in needles:
    idx = 0
    hits = 0
    while hits < 5:
        i = data.find(n, idx)
        if i < 0:
            break
        start = max(0, i - 100)
        end = min(len(data), i + 180)
        chunk = data[start:end]
        s = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        print(f"--- {n.decode(errors='replace')} @ {i} ---")
        print(s)
        print()
        hits += 1
        idx = i + len(n)
    if hits == 0:
        print(f"(no hits for {n.decode(errors='replace')})")
        print()
