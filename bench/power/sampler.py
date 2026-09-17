#!/usr/bin/env python3
"""1 Hz power/utilization sampler. Run as root. Usage: sampler.py OUT.csv SECONDS"""
import csv, glob, os, subprocess, sys, time

out, dur = sys.argv[1], float(sys.argv[2])
RAPL = "/sys/class/powercap/intel-rapl:0"

def rd(p, conv=float):
    try:
        with open(p) as f: return conv(f.read().strip())
    except Exception: return None

def cpu_stat():
    with open("/proc/stat") as f: v = list(map(int, f.readline().split()[1:]))
    idle = v[3] + v[4]; return sum(v), idle

amd_hw = None
for h in glob.glob("/sys/class/hwmon/hwmon*"):
    if rd(h + "/name", str) == "amdgpu" and os.path.exists(h + "/power1_average"):
        amd_hw = h
nvidia = subprocess.run(["which", "nvidia-smi"], capture_output=True).returncode == 0
e_max = rd(RAPL + "/max_energy_range_uj")

fh = open(out, "w", newline=""); w = csv.writer(fh)
w.writerow(["ts", "gpu_w", "gpu_busy_pct", "gpu_vram_mib", "gpu_temp_c", "cpu_pkg_w", "cpu_util_pct", "mem_used_mib"])
t0 = time.time(); prev_e = rd(RAPL + "/energy_uj"); prev_t = time.time(); prev_c = cpu_stat()
while time.time() - t0 < dur:
    time.sleep(1.0)
    now = time.time(); e = rd(RAPL + "/energy_uj"); c = cpu_stat()
    de = (e - prev_e) if e is not None and prev_e is not None else None
    if de is not None and de < 0 and e_max: de += e_max
    cpu_w = de / 1e6 / (now - prev_t) if de is not None else None
    dt, di = c[0] - prev_c[0], c[1] - prev_c[1]
    util = 100.0 * (dt - di) / dt if dt else None
    prev_e, prev_t, prev_c = e, now, c
    gw = gb = gm = gt = None
    if amd_hw:
        gw = rd(amd_hw + "/power1_average") / 1e6
        dev = os.path.realpath(amd_hw + "/device")
        gb = rd(dev + "/gpu_busy_percent"); vm = rd(dev + "/mem_info_vram_used")
        gm = vm / 1048576 if vm else None
        gt = (rd(amd_hw + "/temp2_input") or rd(amd_hw + "/temp1_input") or 0) / 1000
    elif nvidia:
        r = subprocess.run(["nvidia-smi", "--query-gpu=power.draw,utilization.gpu,memory.used,temperature.gpu",
                            "--format=csv,noheader,nounits"], capture_output=True, text=True).stdout.split(",")
        gw, gb, gm, gt = [float(x) for x in r]
    mi = {l.split(":")[0]: int(l.split()[1]) for l in open("/proc/meminfo")}
    mem = (mi["MemTotal"] - mi["MemAvailable"]) / 1024
    w.writerow([f"{now:.3f}", gw, gb, gm, gt, None if cpu_w is None else round(cpu_w, 2),
                None if util is None else round(util, 1), round(mem)])
    fh.flush()
