#!/usr/bin/env python3
import sys
import time
import tkinter as tk
from pathlib import Path

# Configuration
THRESHOLD = 100  # percent
POLL_INTERVAL = 1.0  # seconds

# Helper to read battery files
def read_bat_file(name, fallback=""):
    try:
        return (Path("/sys/class/power_supply")
                .glob("BAT*"))
    except Exception:
        return []

def read_value(path, default=""):
    try:
        return Path(path).read_text().strip()
    except Exception:
        return default

# Main window
root = tk.Tk()
root.overrideredirect(True)      # no window decorations
root.attributes("-topmost", True)
label = tk.Label(root,
                 font=("Sans", 24),
                 fg="white",
                 bg="#222",  # dark background—change as you like
                 padx=20, pady=10)
label.pack()

# Center the window on the screen
def center():
    root.update_idletasks()
    w = root.winfo_width()
    h = root.winfo_height()
    ws = root.winfo_screenwidth()
    hs = root.winfo_screenheight()
    x = (ws // 2) - (w // 2)
    y = (hs // 2) - (h // 2)
    root.geometry(f"{w}x{h}+{x}+{y}")

# Periodic update
def update():
    # Read capacity and status
    cap = read_value("/sys/class/power_supply/BAT0/capacity", "100")
    stat = read_value("/sys/class/power_supply/BAT0/status", "Unknown")

    try:
        cap_i = int(cap)
    except ValueError:
        cap_i = 100

    if stat == "Discharging" and cap_i <= THRESHOLD:
        now = float(read_value("/sys/class/power_supply/BAT0/energy_now", "0"))
        full = float(read_value("/sys/class/power_supply/BAT0/energy_full", "1"))
        percent = now * 100 / full if full > 0 else 0
        text = f"❮ Battery low {percent:.2f}% remaining ❯"
        label.config(text=text)
        center()
        root.deiconify()
    else:
        root.withdraw()  # hide window

    root.after(int(POLL_INTERVAL * 1000), update)

# Kick off
root.withdraw()
root.after(100, update)
root.mainloop()