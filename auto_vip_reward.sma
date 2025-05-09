#include <amxmodx>
#include <amxmisc>
#include <nvault>

#define PLUGIN "Auto VIP Reward"
#define VERSION "1.0"
#define AUTHOR "Sohaib DZ"

new const VAULT_NAME[] = "vip_reward_playtime";
new const VAULT_VIP_TIME[] = "vip_duration_time";

new vip_playtime_required = 1500; // 1500min = 25h
new vip_duration = 4320; // 4320min = 3 Days (72h)
new g_vip_flag = 'o';

new g_total_playtime[33];
new g_vip_time_left[33];
new bool:g_is_vip[33];
new bool:g_connected[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say /viptime", "cmd_vip_time");
    register_concmd("amx_setviptime", "cmd_admin_set_time", ADMIN_RCON, "<minutes>");
    register_concmd("amx_setvipduration", "cmd_admin_set_duration", ADMIN_RCON, "<minutes>");
    register_concmd("amx_setvipflag", "cmd_admin_set_flag", ADMIN_RCON, "<flag>");

    set_task(60.0, "update_playtime", _, _, _, "b");
    set_task(60.0, "check_vip_expiration", _, _, _, "b");
    set_task(140.0, "choose_random_player", _, _, _, "b");
}

public client_putinserver(id) {
    g_connected[id] = true;
    load_playtime(id);
    load_vip_time(id);
    set_task(5.0, "notify_player_status", id);
}

public client_disconnected(id) {
    g_connected[id] = false;
    save_playtime(id);
    save_vip_time(id);
}

public update_playtime() {
    for (new id = 1; id <= get_maxplayers(); id++) {
        if (g_connected[id] && is_user_connected(id) && !is_user_bot(id)) {
            g_total_playtime[id]++;
            if (!g_is_vip[id] && g_total_playtime[id] >= vip_playtime_required) {
                give_vip(id);
            }
        }
    }
}

public check_vip_expiration() {
    for (new id = 1; id <= get_maxplayers(); id++) {
        if (g_connected[id] && g_is_vip[id]) {
            g_vip_time_left[id]--;
            if (g_vip_time_left[id] <= 0) {
                remove_vip(id);
                log_to_file("addons/amxmodx/logs/vip_expired.log", "[VIP] %d's VIP expired while offline.", id);
            }
        }
    }
}

public choose_random_player() {
    new players[32], num;
    get_players(players, num, "ch");
    if (num == 0) return;

    new r = random(num);
    new id = players[r];

    if (!is_user_connected(id)) return;

    if (!g_is_vip[id]) {
        new remaining = vip_playtime_required - g_total_playtime[id];
        remaining = (remaining < 0) ? 0 : remaining;
        new h = (remaining % 1440) / 60;
        new m = remaining % 60;

        new name[32];
        get_user_name(id, name, charsmax(name));
        sohaib_colored_print(0, "!y[!gVIP!y] !yRandom Player:!g %s !yneeds !t%02d hour(s)!y, !t%02d minute(s) !yto get !gVIP", name, h, m);
    }
}

public notify_player_status(id) {
    if (!is_user_connected(id)) return;

    if (g_is_vip[id]) {
        new m = g_vip_time_left[id];
        new d = m / 1440;
        new h = (m % 1440) / 60;
        new min = m % 60;

        new expiry = get_systime() + m * 60;
        new date[32];
        format_time(date, charsmax(date), "%d/%m/%Y at %H:%M", expiry);

        sohaib_colored_print(id, "!y[!gVIP!y] !yYour !tVIP !yexpires in: !g%d day(s)!y, !g%02d hour(s)!y, !g%02d minute(s) !t(!yon !g%s!t)", d, h, min, date);
    } else {
        new remaining = vip_playtime_required - g_total_playtime[id];
        remaining = (remaining < 0) ? 0 : remaining;
        new h = remaining / 60;
        new m = remaining % 60;

        sohaib_colored_print(id, "!y[!gVIP!y] !yTime left to get !tVIP!y: !g%02dh!y:!g%02dmin!y/!g%02dh", h, m, vip_playtime_required / 60);
    }
}

public cmd_vip_time(id) {
    notify_player_status(id);
    return PLUGIN_HANDLED;
}

public cmd_admin_set_time(id, level, cid) {
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
    new arg[8];
    read_argv(1, arg, charsmax(arg));
    vip_playtime_required = clamp(str_to_num(arg), 60, 20000);
    console_print(id, "[VIP] Required playtime updated to %d minute(s)", vip_playtime_required);
    return PLUGIN_HANDLED;
}

public cmd_admin_set_duration(id, level, cid) {
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
    new arg[8];
    read_argv(1, arg, charsmax(arg));
    vip_duration = clamp(str_to_num(arg), 60, 10080);
    console_print(id, "[VIP] VIP duration updated to %d minute(s)", vip_duration);
    return PLUGIN_HANDLED;
}

public cmd_admin_set_flag(id, level, cid) {
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;

    new arg[4];
    read_argv(1, arg, charsmax(arg));

   
    if (strlen(arg) != 1 || arg[0] < 'a' || arg[0] > 'z') {
        console_print(id, "[VIP] Invalid flag. Only lowercase letters (a-z) are allowed.");
        return PLUGIN_HANDLED;
    }

    g_vip_flag = arg[0];
    console_print(id, "[VIP] VIP flag updated to: %c", g_vip_flag);

    new name[32];
    get_user_name(id, name, charsmax(name));
    log_to_file("addons/amxmodx/logs/vip_flag_change.log", "[VIP] Admin '%s' set VIP flag to: %c", name, g_vip_flag);

    return PLUGIN_HANDLED;
}

public give_vip(id) {
	
    if (get_user_flags(id) & read_flags(fmt("%c", g_vip_flag))) {
        sohaib_colored_print(id, "!y[!gVIP!y] !yYou already have a permanent !gVIP!y status.");
        return;
    }

    if (g_is_vip[id]) return;
    
    g_is_vip[id] = true;
    g_vip_time_left[id] = vip_duration;

    new flag_str[2]; flag_str[0] = g_vip_flag; flag_str[1] = 0;
    set_user_flags(id, read_flags(flag_str));

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new i = 1; i <= get_maxplayers(); i++) {
        if (is_user_connected(i)) {
            sohaib_colored_print(i, "!y[!gVIP!y] !t%s !yhas earned !gVIP !yfor !t%d minutes!", name, vip_duration);
        }
    }
}

public remove_vip(id) {
    g_is_vip[id] = false;
    g_vip_time_left[id] = 0;

    new flag_str[2]; flag_str[0] = g_vip_flag; flag_str[1] = 0;
    remove_user_flags(id, read_flags(flag_str));

    sohaib_colored_print(id, "!y[!gVIP!y] !yYour !gVIP !yhas expired!t. !yKeep playing to earn it again!t.");
}

public save_playtime(id) {
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    new vault = nvault_open(VAULT_NAME);
    if (vault == INVALID_HANDLE) return;

    new data[16];
    num_to_str(g_total_playtime[id], data, charsmax(data));
    nvault_set(vault, auth, data);
    nvault_close(vault);
}

public load_playtime(id) {
    new auth[35], data[16];
    get_user_authid(id, auth, charsmax(auth));
    new vault = nvault_open(VAULT_NAME);
    if (vault == INVALID_HANDLE) return;

    nvault_get(vault, auth, data, charsmax(data));
    g_total_playtime[id] = str_to_num(data);
    nvault_close(vault);
}

public save_vip_time(id) {
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    new vault = nvault_open(VAULT_VIP_TIME);
    if (vault == INVALID_HANDLE) return;

    new data[16];
    num_to_str(g_vip_time_left[id], data, charsmax(data));
    nvault_set(vault, auth, data);
    nvault_close(vault);
}

public load_vip_time(id) {
    new auth[35], data[16];
    get_user_authid(id, auth, charsmax(auth));
    new vault = nvault_open(VAULT_VIP_TIME);
    if (vault == INVALID_HANDLE) return;

    nvault_get(vault, auth, data, charsmax(data));
    g_vip_time_left[id] = str_to_num(data);
    g_is_vip[id] = g_vip_time_left[id] > 0;

    if (g_is_vip[id]) {
        new flag_str[2]; flag_str[0] = g_vip_flag; flag_str[1] = 0;
        set_user_flags(id, read_flags(flag_str));
    }

    nvault_close(vault);
}

stock sohaib_colored_print(const id, const input[], any:...) {
    new count = 1, players[32];
    static msg[191];
    vformat(msg, 190, input, 3);

    replace_all(msg, 190, "!g", "^4");
    replace_all(msg, 190, "!y", "^1");
    replace_all(msg, 190, "!t", "^3");

    if (id) players[0] = id;
    else get_players(players, count, "ch");

    for (new i = 0; i < count; i++) {
        if (is_user_connected(players[i])) {
            message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
            write_byte(players[i]);
            write_string(msg);
            message_end();
        }
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
