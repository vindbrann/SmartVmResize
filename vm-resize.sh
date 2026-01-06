#!/bin/bash
# ============================================================
# SMART RESIZE - Outil TUI pour agrandissement LVM à chaud
#
# Pré-requis :
# 1. gum (Interface) -> https://github.com/charmbracelet/gum
# 2. cloud-guest-utils (pour la commande 'growpart')
#
# Installation :
# sudo apt install cloud-guest-utils -y
# ============================================================

# Verif root
if [ "$EUID" -ne 0 ]; then 
    echo "Erreur: Ce script doit être lancé avec sudo."
    exit 1
fi

# --- PHASE 1 : ANALYSE ET RECOLTE ---

# 1. Selection du disque
DISK_NAME=$(lsblk -d -n -o NAME,SIZE,MODEL | gum choose --header "Selectionnez le disque a etendre :" | awk '{print $1}')
if [ -z "$DISK_NAME" ]; then exit; fi

# Rescan du bus
gum spin --spinner dot --title "Rescan du disque..." -- sleep 2
echo 1 > /sys/class/block/$DISK_NAME/device/rescan

# 2. Identification intelligente de la partition LVM
PV_PATH=$(pvs --noheadings -o pv_name | grep "$DISK_NAME" | xargs)

if [ -z "$PV_PATH" ]; then
    gum style --foreground 196 "Erreur: Aucun Volume Physique LVM trouve sur $DISK_NAME"
    exit 1
fi

PART_NUM=$(echo "$PV_PATH" | grep -o '[0-9]*$')

# 3. Agrandissement partition (Growpart)
if [ -n "$PART_NUM" ]; then
    gum spin --spinner line --title "Agrandissement partition $PART_NUM sur $DISK_NAME..." -- growpart /dev/$DISK_NAME $PART_NUM 2>/dev/null
fi

# 4. Agrandissement du PV
gum spin --spinner line --title "Mise a jour du Physical Volume..." -- pvresize $PV_PATH > /dev/null

# --- PHASE 2 : DISTRIBUTION ---

VG_NAME=$(pvs --noheadings -o vg_name $PV_PATH | xargs)
VG_FREE=$(vgs --noheadings -o vg_free --units g $VG_NAME | xargs)

# Affichage du dashboard
gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Disque: $DISK_NAME" "Partition LVM: $PV_PATH" "VG Cible: $VG_NAME" "ESPACE LIBRE A DISTRIBUER: $VG_FREE"

# Choix du LV
LV_SELECTION=$(lvs $VG_NAME --noheadings --units g -o lv_path,lv_size,lv_name | awk '{printf "%-25s (Actuel: %s)\n", $1, $2}' | gum choose --header "Quel volume voulez-vous agrandir ?")
LV_PATH=$(echo "$LV_SELECTION" | awk '{print $1}')

if [ -z "$LV_PATH" ]; then exit; fi

# Saisie de la taille
ADD_SIZE=$(gum input --header "INDIQUEZ LA TAILLE A AJOUTER (Ex: 5G, 500M) OU TAPEZ 'MAX' :" --placeholder "Ex: 10G")

if [ -z "$ADD_SIZE" ]; then exit; fi

# Gestion intelligente des unites
if [[ "$ADD_SIZE" == "MAX" ]] || [[ "$ADD_SIZE" == "TOUT" ]]; then ADD_SIZE="100%FREE"; fi
# Si l'utilisateur tape juste un chiffre (ex: 20), on ajoute G par defaut
if [[ "$ADD_SIZE" =~ ^[0-9]+$ ]]; then ADD_SIZE="${ADD_SIZE}G"; fi

# Confirmation
gum confirm "CONFIRMER : Ajouter +$ADD_SIZE a $LV_PATH ?" || exit

# --- PHASE 3 : EXECUTION ---

# CORRECTION DU BUG : Choix intelligent entre -L (Taille) et -l (Pourcentage)
if [[ "$ADD_SIZE" == *"%"* ]]; then
    # Mode Pourcentage (ex: 100%FREE) -> option minuscule -l
    OUTPUT=$(lvextend -r -l +$ADD_SIZE $LV_PATH 2>&1)
else
    # Mode Taille (ex: 5G) -> option majuscule -L
    OUTPUT=$(lvextend -r -L +$ADD_SIZE $LV_PATH 2>&1)
fi

STATUS=$?

if [ $STATUS -eq 0 ]; then
    gum style --foreground 46 "SUCCES ! Volume etendu."
    lvs $LV_PATH -o lv_name,lv_size --units g
else
    gum style --foreground 196 "ERREUR :"
    echo "$OUTPUT"
fi