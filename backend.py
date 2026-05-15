import os
import subprocess
import time

# ── State for differential calculations ──
last_cpu_total = 0
last_cpu_idle = 0
last_core_stats = {}      # idx → (total, idle)
last_net_rx = 0
last_net_tx = 0
last_net_time = 0

# ── Process tracking for real-time CPU % ──
last_proc_ticks = {}   # pid → cpu_ticks
last_proc_total = 0

# ── History ring buffers ──
MAX_HISTORY = 60
cpu_history = []
ram_history = []

# ── Helpers ──
def _uptime_str():
    try:
        with open('/proc/uptime') as f:
            s = float(f.read().split()[0])
        d, rem = divmod(int(s), 86400)
        h, rem = divmod(rem, 3600)
        m, _ = divmod(rem, 60)
        parts = []
        if d: parts.append(f"{d}d")
        if h: parts.append(f"{h}h")
        parts.append(f"{m}m")
        return " ".join(parts)
    except:
        return "--"


def get_system():
    kernel = "Unknown"
    try:
        kernel = subprocess.run(['uname', '-r'], capture_output=True, text=True).stdout.strip()
    except:
        pass

    model = "Sailfish Device"
    try:
        result = subprocess.run(['cat', '/etc/hw-release'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if line.startswith('NAME='):
                model = line.split('=', 1)[1].strip('"')
                break
    except:
        pass

    processor = "Unknown"
    try:
        with open('/proc/device-tree/model') as f:
            processor = f.read().strip().replace('\x00', '')
    except:
        pass

    os_version = "Unknown"
    try:
        result = subprocess.run(['cat', '/etc/os-release'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if line.startswith('VERSION='):
                os_version = line.split('=', 1)[1].strip('"')
                break
    except:
        pass

    arch = "Unknown"
    try:
        arch = subprocess.run(['uname', '-m'], capture_output=True, text=True).stdout.strip()
    except:
        pass

    hostname = "Unknown"
    try:
        hostname = subprocess.run(['uname', '-n'], capture_output=True, text=True).stdout.strip()
    except:
        pass

    return {
        "model": model,
        "processor": processor,
        "kernel": kernel,
        "os": "Sailfish OS",
        "os_version": os_version,
        "arch": arch,
        "hostname": hostname,
        "uptime": _uptime_str()
    }


def get_cpu():
    global last_cpu_total, last_cpu_idle, last_core_stats
    try:
        with open('/proc/stat') as f:
            lines = f.readlines()

        # Aggregate
        agg = list(map(int, lines[0].split()[1:]))
        agg_idle, agg_total = agg[3], sum(agg)
        pct = 0
        if last_cpu_total > 0:
            td = agg_total - last_cpu_total
            pct = max(0, min(100, int(100 * (1 - (agg_idle - last_cpu_idle) / td)))) if td > 0 else 0
        last_cpu_total, last_cpu_idle = agg_total, agg_idle

        # Per-core
        per_core = []
        for i, line in enumerate(lines[1:]):
            if not line.startswith('cpu'):
                break
            fields = list(map(int, line.split()[1:]))
            idle, total = fields[3], sum(fields)
            core_pct = 0
            if i in last_core_stats:
                pt, pi = last_core_stats[i]
                td = total - pt
                core_pct = max(0, min(100, int(100 * (1 - (idle - pi) / td)))) if td > 0 else 0
            last_core_stats[i] = (total, idle)
            per_core.append(core_pct)

        # Frequency from cpufreq sysfs (most accurate on ARM)
        freq = "Unknown"
        freqs = []
        for i in range(32):
            for fname in ('scaling_cur_freq', 'cpuinfo_cur_freq'):
                path = f'/sys/devices/system/cpu/cpu{i}/cpufreq/{fname}'
                if os.path.exists(path):
                    try:
                        with open(path) as f:
                            freqs.append(int(f.read().strip()))
                        break
                    except:
                        pass
        if freqs:
            avg = sum(freqs) / len(freqs)
            freq = f"{avg/1000000:.2f} GHz" if avg >= 1000000 else f"{avg/1000:.0f} MHz"
        else:
            # Fallback to /proc/cpuinfo
            try:
                with open('/proc/cpuinfo') as f:
                    for line in f:
                        if 'MHz' in line or 'GHz' in line:
                            freq = line.split(':')[1].strip()
                            break
            except:
                pass

        return {"pct": pct, "cores": len(per_core), "freq": freq, "per_core": per_core}
    except:
        return {"pct": 0, "cores": 0, "freq": "Unknown", "per_core": []}


def get_ram():
    try:
        with open('/proc/meminfo') as f:
            data = f.read()
        total = int(data.split('MemTotal:')[1].split('kB')[0].strip())
        available = int(data.split('MemAvailable:')[1].split('kB')[0].strip())
        used = total - available
        return {"used": used // 1024, "total": total // 1024, "pct": int(100 * used / total)}
    except:
        return {"used": 0, "total": 0, "pct": 0}


def get_storage():
    try:
        st = os.statvfs('/')
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        return {"used": round(used / (1024**3), 1), "total": round(total / (1024**3), 1), "pct": int(100 * used / total)}
    except:
        return {"used": 0, "total": 0, "pct": 0}


def get_battery():
    try:
        base = '/sys/class/power_supply/'
        for d in os.listdir(base):
            if 'battery' in d.lower():
                p = os.path.join(base, d)
                with open(f'{p}/capacity') as f:
                    cap = int(f.read().strip())
                status = "Unknown"
                try:
                    with open(f'{p}/status') as f:
                        status = f.read().strip()
                except:
                    pass
                temp = 0
                try:
                    with open(f'{p}/temp') as f:
                        t = int(f.read().strip())
                        # Battery temp in power_supply is typically tenths of °C
                        temp = round(t / 10.0, 1)
                except:
                    pass
                return {"capacity": cap, "status": status, "temp": temp}
    except:
        pass
    return {"capacity": 0, "status": "Unknown", "temp": 0}


def get_network():
    global last_net_rx, last_net_tx, last_net_time
    try:
        with open('/proc/net/dev') as f:
            lines = f.readlines()

        rx_total = tx_total = 0
        iface = "None"
        for line in lines[2:]:
            parts = line.split()
            name = parts[0].rstrip(':')
            if name != 'lo' and not name.startswith('dummy'):
                rx_total += int(parts[1])
                tx_total += int(parts[9])
                if iface == "None" and (name.startswith('wlan') or name.startswith('eth') or name.startswith('usb')):
                    iface = name

        now = time.time()
        rx_speed = tx_speed = 0
        if last_net_time > 0 and now > last_net_time:
            dt = now - last_net_time
            rx_speed = max(0, int((rx_total - last_net_rx) / dt))
            tx_speed = max(0, int((tx_total - last_net_tx) / dt))
        last_net_rx, last_net_tx, last_net_time = rx_total, tx_total, now

        ip = "--"
        if iface != "None":
            try:
                out = subprocess.run(['ip', 'addr', 'show', iface], capture_output=True, text=True, timeout=2).stdout
                for line in out.split('\n'):
                    if 'inet ' in line:
                        ip = line.strip().split()[1].split('/')[0]
                        break
            except:
                pass

        return {"iface": iface, "rx_speed": rx_speed, "tx_speed": tx_speed, "ip": ip}
    except:
        return {"iface": "None", "rx_speed": 0, "tx_speed": 0, "ip": "--"}


def get_thermal():
    cpu_temps = []
    all_temps = []
    try:
        for zone in os.listdir('/sys/class/thermal'):
            if not zone.startswith('thermal_zone'):
                continue
            try:
                base = f'/sys/class/thermal/{zone}'
                with open(f'{base}/temp') as f:
                    raw = int(f.read().strip())
                with open(f'{base}/type') as f:
                    typ = f.read().strip().lower()

                # Different sensors use different scales
                if 'tsens' in typ or 'msm_therm' in typ or 'xo_therm' in typ or 'quiet_therm' in typ:
                    t = raw / 10.0
                elif 'battery' in typ or 'pm660' in typ or 'bms' in typ:
                    t = raw / 1000.0
                else:
                    if raw > 10000:
                        t = raw / 1000.0
                    elif raw > 200:
                        t = raw / 10.0
                    else:
                        t = raw

                if 0 < t < 120:
                    all_temps.append(t)
                    if 'tsens' in typ or 'msm_therm' in typ:
                        cpu_temps.append(t)
            except:
                pass
    except:
        pass
    return {
        "cpu_temp": round(max(cpu_temps), 1) if cpu_temps else (round(max(all_temps), 1) if all_temps else 0),
        "max_temp": round(max(all_temps), 1) if all_temps else 0
    }


def get_load():
    try:
        with open('/proc/loadavg') as f:
            data = f.read().split()
        return [round(float(data[0]), 2), round(float(data[1]), 2), round(float(data[2]), 2)]
    except:
        return [0.0, 0.0, 0.0]


def get_processes():
    global last_proc_ticks, last_proc_total
    procs = []
    try:
        with open('/proc/meminfo') as f:
            memtotal = int(f.read().split('MemTotal:')[1].split('kB')[0].strip())

        # Total CPU ticks for percentage calculation
        with open('/proc/stat') as f:
            cpu_total_now = sum(map(int, f.readline().split()[1:]))

        current_ticks = {}
        for pid in os.listdir('/proc'):
            if pid.isdigit():
                try:
                    with open(f'/proc/{pid}/stat') as f:
                        data = f.read().split()
                    name = data[1].strip('()')
                    ticks = int(data[13]) + int(data[14])
                    current_ticks[int(pid)] = ticks

                    mem_pct = 0
                    try:
                        with open(f'/proc/{pid}/status') as f:
                            status = f.read()
                        vmrss = int(status.split('VmRSS:')[1].split('kB')[0].strip())
                        mem_pct = round(100 * vmrss / memtotal, 1)
                    except:
                        pass

                    procs.append({"pid": int(pid), "name": name[:22], "cpu_ticks": ticks, "mem_pct": mem_pct})
                except:
                    pass

        # Calculate real-time CPU percentages based on tick differences
        total_diff = cpu_total_now - last_proc_total
        if last_proc_total > 0 and total_diff > 0:
            for p in procs:
                pid = p["pid"]
                if pid in last_proc_ticks:
                    tick_diff = p["cpu_ticks"] - last_proc_ticks[pid]
                    p["cpu_pct"] = round(100 * tick_diff / total_diff, 1)
                else:
                    p["cpu_pct"] = 0.0
        else:
            for p in procs:
                p["cpu_pct"] = 0.0

        last_proc_ticks = current_ticks
        last_proc_total = cpu_total_now

        procs.sort(key=lambda x: x["cpu_pct"], reverse=True)
        return procs[:8]
    except:
        return []


def get_all():
    global cpu_history, ram_history
    cpu = get_cpu()
    ram = get_ram()

    cpu_history.append(cpu["pct"])
    ram_history.append(ram["pct"])
    if len(cpu_history) > MAX_HISTORY:
        cpu_history = cpu_history[-MAX_HISTORY:]
    if len(ram_history) > MAX_HISTORY:
        ram_history = ram_history[-MAX_HISTORY:]

    return {
        "system": get_system(),
        "cpu": cpu,
        "ram": ram,
        "storage": get_storage(),
        "battery": get_battery(),
        "network": get_network(),
        "thermal": get_thermal(),
        "load": get_load(),
        "processes": get_processes(),
        "history": {"cpu": cpu_history[:], "ram": ram_history[:]}
    }
