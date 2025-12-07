#!/bin/bash

plugins=(
    # general
    "l4d_revive.sp"
    "l4d2_tank_loss_announce.sp"
    "l4d2_mix.sp"
    "admincheats.sp"
    "confoglcompmod.sp"
    "l4d2_tank_facts_announce.sp"
    "l4d_spot_marker.sp"
    "l4d2_vote_manager3.sp"
    "fakelag.sp"
    "l4d2_spectating_cheat.sp"
    "l4d2_cfg_on_hostname.sp"
    "match_announce.sp"
    # "autorecorder.sp"
    "demo_recorder/demo_recorder.sp"
    "optional:pause.sp"
    "l4d2_tank_is_comming.sp"
    "l4d2_mixmap.sp"
    "optional:l4d2_map_transitions.sp"
    "campaigns/campaigns.sp"

    # mismod
    "optional:readyup.sp"
    "optional:starting_items.sp"
    "optional:spechud.sp"
    "optional:l4d_tank_control_eq.sp"
    "optional:l4d_tank_rush.sp"
    "optional:l4d2_bots_dont_resist_jockeys.sp"
    "optional:l4d_weapon_giver.sp"
    "optional:l4d_boss_vote.sp"
    "optional:l4d2_setscores.sp"
    "optional:skeet_database.sp"

    # gauntlet
    "optional/hardcoop:silent_sm_cvar.sp"
    "optional/hardcoop:navmesh.sp"
    "optional/hardcoop:l4d2_meleeinthesaferoom.sp"
    "optional/hardcoop:sm_give_givemenu.sp"
    "optional/hardcoop:AI_HardSI.sp"
    "optional/hardcoop:ai_targeting.sp"
    "optional/hardcoop:autoslayer.sp"
    "optional/hardcoop:coopbosses.sp"
    "optional/hardcoop:healthmanagement.sp"
    "optional/hardcoop:l4d2_playstats_fixed.sp"
    "optional/hardcoop:playermode.sp"
    "optional/hardcoop:specialspawner.sp"
    "optional/hardcoop:survivormanagement.sp"
    "optional/hardcoop:gauntlet_cvars.sp"
    "optional/hardcoop:gauntlet_enforce_survivor.sp"

    # vanillamax
    "optional:vanillamax/PERKAHOLIC_WEAPONS.sp"
    "optional:vanillamax/WeaponHandling.sp"
    "optional:vanillamax/l4d2_guncontrol.sp"
    "optional:vanillamax/psychotic_witch.sp"
    "optional:vanillamax/survivor_legs.sp"
    "optional:vanillamax/vomit_screen_fade.sp"
    "optional:vanillamax/guns_reload.sp"
    "optional:vanillamax/survivor_speed_gun.sp"
)

pushd addons/sourcemod/scripting > /dev/null

output_base="../plugins"

total_errors=0

for plugin in "${plugins[@]}"; do
    IFS=":" read -r -a parts <<< "$plugin"

    if [[ "${#parts[@]}" == 1 ]]; then
        sp_file="${parts[0]}"
        output_dir="$output_base"
    else
        sp_file="${parts[1]}"
        output_dir="$output_base/${parts[0]}"
    fi

    smx_file="$output_dir/$(basename "$sp_file" .sp).smx"
    smx_path="addons/sourcemod/plugins/$(basename "$sp_file" .sp).smx"
    echo -e "Compiling addons/sourcemod/scripting/$sp_file -> $smx_path"
    mkdir -p "$output_dir"

    compiler_output=$(./spcomp64 "$sp_file" -o "$smx_file")

    if echo "$compiler_output" | grep -Eq "[0-9]+ (Error|Warning)s?"; then
        echo -e "\n$compiler_output\n\n"
        errors=$(echo "$compiler_output" | grep -oP "[0-9]+ Errors?" | grep -oP "[0-9]+" || echo 0)
        total_errors=$((total_errors + errors))
    fi
done

echo -e "\nTotal errors: $total_errors"

popd > /dev/null

if [[ $total_errors -gt 0 ]]; then
    exit 1
fi
