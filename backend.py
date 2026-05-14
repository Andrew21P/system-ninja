import os
import subprocess

last_cpu_total = 0
last_cpu_idle = 0

def get_cpu():
    global last_cpu_total, last_cpu_idle
    try:
        with open('/proc/stat') as f:
            line = f.readline()
        fields = list(map(int, line.split()[1:]))
        idle = fields[3]
        total = sum(fields)
        if last_cpu_total > 0:
            total_diff = total - last_cpu_total
            idle_diff = idle - last_cpu_idle
            pct = max(0, min(100, int(100 * (1 - idle_diff / total_diff))))
        else:
            pct = 0
        last_cpu_total = total
        last_cpu_idle = idle
        
        cores = 0
        freq = "Unknown"
        try:
            with open('/proc/cpuinfo') as f:
                data = f.read()
            cores = data.count('processor\t:')
            for line in data.split('\n'):
                if 'MHz' in line or 'GHz' in line:
                    freq = line.split(':')[1].strip()
                    break
        except:
            pass
        return {"pct": pct, "cores": cores, "freq": freq}
    except:
        return {"pct": 0, "cores": 0, "freq": "Unknown"}

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
                path = os.path.join(base, d)
                with open(f'{path}/capacity') as f:
                    cap = int(f.read().strip())
                status = "Unknown"
                try:
                    with open(f'{path}/status') as f:
                        status = f.read().strip()
                except:
                    pass
                return {"capacity": cap, "status": status}
    except:
        pass
    return {"capacity": 0, "status": "Unknown"}

def get_network():
    try:
        result = subprocess.run(['ip', 'addr', 'show', 'wlan0'],
                              capture_output=True, text=True, timeout=2)
        output = result.stdout
        if 'state UP' in output:
            status = "WiFi Connected"
        elif 'wlan0' in output:
            status = "WiFi Down"
        else:
            status = "No WiFi"
        ip = "No IP"
        for line in output.split('\n'):
            if 'inet ' in line and 'wlan0' not in line:
                ip = line.strip().split()[1].split('/')[0]
                break
        return {"status": status, "ip": ip}
    except:
        return {"status": "Unknown", "ip": "--"}

def get_processes():
    procs = []
    try:
        for pid in os.listdir('/proc')[:100]:
            if pid.isdigit():
                try:
                    with open(f'/proc/{pid}/stat') as f:
                        data = f.read().split()
                    name = data[1].strip('()')
                    utime = int(data[13])
                    stime = int(data[14])
                    procs.append({"pid": pid, "name": name[:18], "cpu": utime + stime})
                except:
                    pass
        procs.sort(key=lambda x: x["cpu"], reverse=True)
        return procs[:5]
    except:
        return []

def get_all():
    return {
        "cpu": get_cpu(),
        "ram": get_ram(),
        "storage": get_storage(),
        "battery": get_battery(),
        "network": get_network(),
        "processes": get_processes()
    }
