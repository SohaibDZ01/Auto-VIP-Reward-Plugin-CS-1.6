# Auto VIP Reward Plugin

### Author: **Sohaib DZ**  
### Version: **1.1**  
### Platform: **AMX Mod X (for Counter-Strike 1.6 and related mods)**

---

## 📌 Description

The **Auto VIP Reward** plugin automatically grants VIP status to players after they accumulate a specific amount of playtime. VIP status is temporary and expires after a configurable duration. This plugin includes admin commands to adjust the required playtime, VIP duration, and VIP access flag dynamically.

---

## ✅ Features

- Automatically tracks and saves player playtime using **nVault**.
- Grants temporary VIP status (AMXX flag) when a player reaches the playtime threshold.
- Saves and restores remaining VIP time across sessions.
- Notifies players about VIP status and time remaining.
- Admin commands to customize:
  - Required playtime for VIP
  - VIP duration
  - VIP access flag
- Randomly announces a non-VIP player’s remaining time to reach VIP.
- Colorful in-game chat messages using `SayText`.

---

## ⚙️ Configuration

- `vip_playtime_required`: Time required to become VIP (default: **1500 minutes = 25 hours**).
- `vip_duration`: How long VIP status lasts (default: **4320 minutes = 3 days**).
- `g_vip_flag`: The access flag given to VIP players (default: **'o'**).

---

## 🛠 Admin Commands

| Command | Access Level | Description |
|--------|--------------|-------------|
| `amx_setviptime <minutes>` | RCON | Set the required playtime for VIP |
| `amx_setvipduration <minutes>` | RCON | Set the VIP duration |
| `amx_setvipflag <flag>` | RCON | Set the VIP access flag (single lowercase letter) |

---

## 💬 Player Command

- `say /viptime`: Shows the player's progress towards VIP or time left until VIP expires.

---

## 💾 Data Storage

- Uses **nVault** to store:
  - Player's total playtime.
  - Remaining VIP time (for persistence after disconnection).

---

## 📊 How it Works

1. **Tracking**: Every minute, the plugin updates playtime for connected human players.
2. **Rewarding**: Once a player hits the required playtime and isn’t already VIP, they are automatically granted VIP status for the configured duration.
3. **Expiration**: VIP time decreases every minute. When it hits zero, the VIP flag is removed, and the player is notified.
4. **Persistence**: Playtime and VIP time are saved and reloaded using the player's SteamID via `nVault`.

---

## 🎯 Optional: Customize Chat Colors

Chat colors use `!g`, `!y`, `!t` markers:
- `!g` → Green
- `!y` → Default color
- `!t` → Team color

You can modify the `sohaib_colored_print` function for different formatting or remove color codes.

---

## 🧩 Dependencies

- AMX Mod X (1.8.2 or later recommended)
- `nvault` module must be enabled in `modules.ini`.

---

## 🔒 Notes

- Players with a permanent VIP flag will not be given temporary VIP.
- Ensure that the VIP flag you choose does not conflict with admin flags.
