"""
System Ninja backend - system stats collector for Sailfish OS.

Reads from /proc and sysfs to gather CPU, memory, storage, battery,
network, thermal and process information. Designed to be called from
QML via PyOtherSide.
"""

import os
import subprocess
import time


# ------------------------------------------------------------------
# State for differential calculations
# ------------------------------------------------------------------
_last_cpu_total = 0
_last_cpu_idle = 0
_last_core_stats = {}       # idx -> (total, idle)

_last_net_rx = 0
_last_net_tx = 0
_last_net_time = 0

_last_proc_ticks = {}       # pid -> cpu_ticks
_last_proc_total = 0

MAX_HISTORY = 60
_cpu_history = []
_ram_history = []


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def _uptime_str():
    """Return system uptime as a human readable string."""
    try:
        with open("/proc/uptime") as f:
            seconds = float(f.read().split()[0])
    except (OSError, ValueError):
        return "--"

    days, rem = divmod(int(seconds), 86400)
    hours, rem = divmod(rem, 3600)
    minutes, _ = divmod(rem, 60)

    parts = []
    if days:
        parts.append(f"{days}d")
    if hours:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)


def _read_file(path, default=""):
    """Safely read the first line of a file."""
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def _run_output(cmd):
    """Run a shell command and return its stdout, or empty string on failure."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=5).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


# ------------------------------------------------------------------
# System info
# ------------------------------------------------------------------
def get_system():
    """Gather static system information."""
    model = "Sailfish Device"
    try:
        for line in _read_file("/etc/hw-release").splitlines():
            if line.startswith("NAME="):
                model = line.split("=", 1)[1].strip('"')
                break
    except Exception:
        pass

    processor = "Unknown"
    try:
        processor = _read_file("/proc/device-tree/model").replace("\x00", "")
    except Exception:
        pass

    os_version = "Unknown"
    try:
        for line in _read_file("/etc/os-release").splitlines():
            if line.startswith("VERSION="):
                os_version = line.split("=", 1)[1].strip('"')
                break
    except Exception:
        pass

    return {
        "model": model,
        "processor": processor,
        "kernel": _run_output(["uname", "-r"]),
        "os": "Sailfish OS",
        "os_version": os_version,
        "arch": _run_output(["uname", "-m"]),
        "hostname": _run_output(["uname", "-n"]),
        "uptime": _uptime_str(),
    }


# ------------------------------------------------------------------
# CPU
# ------------------------------------------------------------------
def get_cpu():
    """Read CPU usage and frequency."""
    global _last_cpu_total, _last_cpu_idle, _last_core_stats

    try:
        with open("/proc/stat") as f:
            lines = f.readlines()
    except OSError:
        return {"pct": 0, "cores": 0, "freq": "Unknown", "per_core": []}

    # Aggregate CPU
    agg = list(map(int, lines[0].split()[1:]))
    agg_idle = agg[3]
    agg_total = sum(agg)

    pct = 0
    if _last_cpu_total > 0:
        total_delta = agg_total - _last_cpu_total
        if total_delta > 0:
            idle_delta = agg_idle - _last_cpu_idle
            pct = max(0, min(100, int(100 * (1 - idle_delta / total_delta))))
    _last_cpu_total = agg_total
    _last_cpu_idle = agg_idle

    # Per-core
    per_core = []
    for i, line in enumerate(lines[1:]):
        if not line.startswith("cpu"):
            break
        fields = list(map(int, line.split()[1:]))
        idle, total = fields[3], sum(fields)

        core_pct = 0
        if i in _last_core_stats:
            prev_total, prev_idle = _last_core_stats[i]
            td = total - prev_total
            if td > 0:
                core_pct = max(0, min(100, int(100 * (1 - (idle - prev_idle) / td))))
        _last_core_stats[i] = (total, idle)
        per_core.append(core_pct)

    # Frequency
    freq = "Unknown"
    freqs = []
    for i in range(32):
        for fname in ("scaling_cur_freq", "cpuinfo_cur_freq"):
            path = f"/sys/devices/system/cpu/cpu{i}/cpufreq/{fname}"
            raw = _read_file(path)
            if raw:
                try:
                    freqs.append(int(raw))
                    break
                except ValueError:
                    pass

    if freqs:
        avg = sum(freqs) / len(freqs)
        freq = f"{avg / 1000000:.2f} GHz" if avg >= 1000000 else f"{avg / 1000:.0f} MHz"
    else:
        # Fallback to /proc/cpuinfo
        try:
            with open("/proc/cpuinfo") as f:
                for line in f:
                    if "MHz" in line or "GHz" in line:
                        freq = line.split(":")[1].strip()
                        break
        except OSError:
            pass

    return {"pct": pct, "cores": len(per_core), "freq": freq, "per_core": per_core}


# ------------------------------------------------------------------
# RAM
# ------------------------------------------------------------------
def get_ram():
    """Read memory usage from /proc/meminfo."""
    try:
        data = _read_file("/proc/meminfo")
        total = int(data.split("MemTotal:")[1].split("kB")[0].strip())
        available = int(data.split("MemAvailable:")[1].split("kB")[0].strip())
        used = total - available
        return {
            "used": used // 1024,
            "total": total // 1024,
            "pct": int(100 * used / total),
        }
    except (OSError, ValueError, IndexError):
        return {"used": 0, "total": 0, "pct": 0}


# ------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------
def get_storage():
    """Read root filesystem usage."""
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        return {
            "used": round(used / (1024 ** 3), 1),
            "total": round(total / (1024 ** 3), 1),
            "pct": int(100 * used / total),
        }
    except OSError:
        return {"used": 0, "total": 0, "pct": 0}


# ------------------------------------------------------------------
# Battery
# ------------------------------------------------------------------
def get_battery():
    """Read battery capacity, status and temperature."""
    base = "/sys/class/power_supply/"
    try:
        for name in os.listdir(base):
            if "battery" not in name.lower():
                continue
            path = os.path.join(base, name)

            cap = 0
            try:
                cap = int(_read_file(f"{path}/capacity"))
            except ValueError:
                pass

            status = _read_file(f"{path}/status", "Unknown")

            temp = 0
            try:
                raw = int(_read_file(f"{path}/temp"))
                # Battery temp is typically tenths of a degree
                temp = round(raw / 10.0, 1)
            except ValueError:
                pass

            return {"capacity": cap, "status": status, "temp": temp}
    except OSError:
        pass
    return {"capacity": 0, "status": "Unknown", "temp": 0}


# ------------------------------------------------------------------
# Network
# ------------------------------------------------------------------
def get_network():
    """Read network interface stats and calculate speeds."""
    global _last_net_rx, _last_net_tx, _last_net_time

    try:
        with open("/proc/net/dev") as f:
            lines = f.readlines()
    except OSError:
        return {"iface": "None", "rx_speed": 0, "tx_speed": 0, "ip": "--"}

    rx_total = 0
    tx_total = 0
    iface = "None"

    for line in lines[2:]:
        parts = line.split()
        name = parts[0].rstrip(":")
        if name == "lo" or name.startswith("dummy"):
            continue
        rx_total += int(parts[1])
        tx_total += int(parts[9])
        if iface == "None" and (name.startswith("wlan") or name.startswith("eth") or name.startswith("usb")):
            iface = name

    now = time.time()
    rx_speed = 0
    tx_speed = 0
    if _last_net_time > 0 and now > _last_net_time:
        dt = now - _last_net_time
        rx_speed = max(0, int((rx_total - _last_net_rx) / dt))
        tx_speed = max(0, int((tx_total - _last_net_tx) / dt))
    _last_net_rx = rx_total
    _last_net_tx = tx_total
    _last_net_time = now

    ip = "--"
    if iface != "None":
        try:
            out = subprocess.run(["ip", "addr", "show", iface],
                                 capture_output=True, text=True, timeout=2).stdout
            for line in out.splitlines():
                if "inet " in line:
                    ip = line.strip().split()[1].split("/")[0]
                    break
        except (OSError, subprocess.TimeoutExpired):
            pass

    return {"iface": iface, "rx_speed": rx_speed, "tx_speed": tx_speed, "ip": ip}


# ------------------------------------------------------------------
# Thermal
# ------------------------------------------------------------------
def get_thermal():
    """Read thermal zone temperatures."""
    cpu_temps = []
    all_temps = []

    try:
        for zone in os.listdir("/sys/class/thermal"):
            if not zone.startswith("thermal_zone"):
                continue
            base = f"/sys/class/thermal/{zone}"
            try:
                raw = int(_read_file(f"{base}/temp"))
                typ = _read_file(f"{base}/type").lower()

                # Different sensors use different scales
                if any(x in typ for x in ("tsens", "msm_therm", "xo_therm", "quiet_therm")):
                    t = raw / 10.0
                elif any(x in typ for x in ("battery", "pm660", "bms")):
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
                    if "tsens" in typ or "msm_therm" in typ:
                        cpu_temps.append(t)
            except (OSError, ValueError):
                pass
    except OSError:
        pass

    cpu_temp = round(max(cpu_temps), 1) if cpu_temps else (round(max(all_temps), 1) if all_temps else 0)
    max_temp = round(max(all_temps), 1) if all_temps else 0
    return {"cpu_temp": cpu_temp, "max_temp": max_temp}


# ------------------------------------------------------------------
# Load average
# ------------------------------------------------------------------
def get_load():
    """Read 1m, 5m, 15m load averages."""
    try:
        data = _read_file("/proc/loadavg").split()
        return [round(float(data[0]), 2), round(float(data[1]), 2), round(float(data[2]), 2)]
    except (OSError, ValueError, IndexError):
        return [0.0, 0.0, 0.0]


# ------------------------------------------------------------------
# Processes
# ------------------------------------------------------------------
def get_processes():
    """Return the top 8 CPU-consuming processes."""
    global _last_proc_ticks, _last_proc_total

    try:
        memtotal = int(_read_file("/proc/meminfo").split("MemTotal:")[1].split("kB")[0].strip())
    except (OSError, ValueError, IndexError):
        return []

    try:
        with open("/proc/stat") as f:
            cpu_total_now = sum(map(int, f.readline().split()[1:]))
    except (OSError, ValueError):
        return []

    procs = []
    current_ticks = {}

    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            data = _read_file(f"/proc/{pid}/stat").split()
            name = data[1].strip("()")
            ticks = int(data[13]) + int(data[14])
            current_ticks[int(pid)] = ticks

            mem_pct = 0
            try:
                status = _read_file(f"/proc/{pid}/status")
                vmrss = int(status.split("VmRSS:")[1].split("kB")[0].strip())
                mem_pct = round(100 * vmrss / memtotal, 1)
            except (OSError, ValueError, IndexError):
                pass

            procs.append({"pid": int(pid), "name": name[:22], "cpu_ticks": ticks, "mem_pct": mem_pct})
        except (OSError, ValueError, IndexError):
            continue

    total_diff = cpu_total_now - _last_proc_total
    if _last_proc_total > 0 and total_diff > 0:
        for p in procs:
            pid = p["pid"]
            if pid in _last_proc_ticks:
                tick_diff = p["cpu_ticks"] - _last_proc_ticks[pid]
                p["cpu_pct"] = round(100 * tick_diff / total_diff, 1)
            else:
                p["cpu_pct"] = 0.0
    else:
        for p in procs:
            p["cpu_pct"] = 0.0

    _last_proc_ticks = current_ticks
    _last_proc_total = cpu_total_now

    procs.sort(key=lambda x: x["cpu_pct"], reverse=True)
    return procs[:8]


# ------------------------------------------------------------------
# Aggregate
# ------------------------------------------------------------------
def get_all():
    """Return a complete snapshot of all system stats."""
    global _cpu_history, _ram_history

    cpu = get_cpu()
    ram = get_ram()

    _cpu_history.append(cpu["pct"])
    _ram_history.append(ram["pct"])
    if len(_cpu_history) > MAX_HISTORY:
        _cpu_history = _cpu_history[-MAX_HISTORY:]
    if len(_ram_history) > MAX_HISTORY:
        _ram_history = _ram_history[-MAX_HISTORY:]

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
        "history": {"cpu": _cpu_history[:], "ram": _ram_history[:]},
    }
