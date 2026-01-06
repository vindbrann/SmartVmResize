# Linux VM Resizer

Un outil TUI (Terminal User Interface) moderne pour redimensionner vos partitions et volumes LVM à chaud sur Linux, sans redémarrage et sans maux de tête.

![Bash](https://img.shields.io/badge/Language-Bash-green)
![License](https://img.shields.io/badge/License-MIT-blue)

## Pourquoi cet outil ?
Agrandir un disque sur une VM Linux (VMware, Proxmox, etc.) implique souvent une série de commandes manuelles fastidieuses et risquées (`fdisk`, calculs de secteurs, `pvresize`, `lvextend`, `resize2fs`...).

**Linux VM Resizer** automatise tout cela avec une interface graphique en console (grâce à `gum`).

**Fonctionnalités :**
* ✅ **Scan automatique** des nouveaux espaces disques (rescan SCSI).
* ✅ **Interface visuelle** pour choisir le disque et le volume.
* ✅ **Sécurisé** : Détection automatique des partitions et PVs.
* ✅ **Flexible** : Choisissez une taille précise (ex: `5G`) ou tout l'espace (`MAX`).
* ✅ **Tout-en-un** : Gère la partition, le LVM et le système de fichiers (ext4/xfs) en une passe.

## Pré-requis

L'outil a besoin de deux dépendances pour fonctionner :

1.  **cloud-guest-utils** (fournit `growpart`)
2.  **gum** (fournit l'interface graphique)

```bash
# Sur Debian / Ubuntu
sudo apt update && sudo apt install cloud-guest-utils -y

# Installation de Gum (Binaire officiel)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL [https://repo.charm.sh/apt/gpg.key](https://repo.charm.sh/apt/gpg.key) | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] [https://repo.charm.sh/apt/](https://repo.charm.sh/apt/) * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum -y
```

## Installation rapide
Clonez le dépôt et rendez le script exécutable :
```bash
git clone [https://github.com/VOTRE-PSEUDO/linux-vm-resizer.git](https://github.com/VOTRE-PSEUDO/linux-vm-resizer.git)
cd linux-vm-resizer
chmod +x vm-resize.sh
sudo mv vm-resize.sh /usr/local/bin/vm-resize
```

## Utilisation
Lancez simplement la commande (avec sudo) :
```bash
sudo vm-resize
```
Laissez-vous guider par les menus !

## Disclaimer
Bien que cet outil ait été testé, la manipulation de partitions comporte toujours des risques. Assurez-vous d'avoir des sauvegardes de vos données avant de manipuler vos disques de production.

## License
Distribué sous la licence MIT. Voir LICENSE pour plus d'informations.