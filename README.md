# PSBBN Definitive Project - Slim + GL-iNet Mango (Samba) Edition

> **Fork Slim-Mango** del proyecto [CosmicScale/PSBBN-Definitive-Project](https://github.com/CosmicScale/PSBBN-Definitive-Project) para PS2 Slim SCPH-700xx / 750xx / 770xx / 900xx sin HDD interno. Mantiene **100% estética PSBBN** (Game Collection cover-flow, Music/Movie/Photo/Internet Channels, iconos 3D) usando SD MX4SIO + Samba vía GL-iNet Mango amarillo.

## Diferencias vs Fat original
- **Storage:** `MX4SIO` (SD en slot MC2) con `APA-Jail` en lugar de `IDE HDD`. Particiones `__linux.*` + `__system/__common/__contents` + `OPL` exFAT en `/dev/mmcblk0p3` (`scripts/PSBBN-Installer.sh:1710`, `scripts/HOSDMenu-Installer.sh:773`).
- **LAN:** `SMB2` para PS2 ISOs en `gl-mt300n-v2` Mango. No se copia ISO a SD, solo launcher 8M `PP.*` (`scripts/Game-Installer.sh:2790`, `3450`).
- **Boot:** `FMCB/Fortuna/OpenTuna` + `OSDMenu MBR` + `ATA BDM Assault` en MC (requerido para POPS y BDM).

---

## Diagrama de Cableado

```
 [TU FIBRA / ROUTER PRINCIPAL] ))) WiFi (((
                               |
                               | WiFi Repeater (2.4GHz)
                    +-------------------------+
                    |  GL-iNet Mango Amarillo |
                    |  GL-MT300N-V2 (OpenWrt) |
                    |  IP: 192.168.8.1        |
                    |  Samba4: //PS2SMB       |
                    +------------+------------+
                                 | USB 2.0
                      +----------v----------+
                      |  HDD/SSD USB        |
                      |  /mnt/sda1          |
                      |  ├─ DVD/  *.iso/*.zso  (PS2)
                      |  ├─ CD/   *.iso       (PS2)
                      |  └─ POPS/ SB.*.ELF + *.VCD (PS1 SMB)
                      +---------------------+
                                 |
                    +------------+------------+
                    |  Mango LAN (ETH)        |
                    +------------+------------+
                                 | Cable RJ45 CAT5e (30cm)
                    +------------v------------+
                    |  PS2 Slim 700xx-900xx   |
                    |  ETH 100Mbps + MX4SIO   |
                    |  ├─ Slot1: MC FMCB + BDM Assault
                    |  └─ Slot2: MX4SIO + SDXC 128GB-1TB
                    |       └─ APA-Jail (OPL exFAT)
                    +-------------------------+
                                 | AV/HDMI (Retro GEM)
                    +------------v------------+
                    |  TV 480i / 480p / 1080i |
                    +-------------------------+

 PC (Debian/WSL) --- Lector SD USB --- MX4SIO SD (para instalador)
   └─ games/SMB/DVD/*.iso  (refleja Mango USB, no copia)
   └─ games/POPS/SB.*.ELF  (PS1 SMB)
```

### Alimentación
Mango puede alimentarse del USB de PS2 (5V 500mA) o cargador 5V 1A. Si se alimenta de PS2, se enciende/apaga con la consola.

---

## Instalación

### 1. Mango (5 min)
1. Entra a `192.168.8.1` > Admin > `Applications > Network Storage > Samba` ON.
2. Share `PS2SMB` Path `/mnt/sda1` Allow guest ON.
3. Crea carpetas en USB: `DVD/`, `CD/`, `POPS/`.
4. Modo `Repeater` > conecta a tu WiFi. Deja LAN libre para PS2.

### 2. PS2 Slim
- SD 64GB+ formateada (instalador la formatea). Inserta en MX4SIO (Slot2).
- MemoryCard Slot1 con FMCB 1.966 + Drivers `ATA BDM Assault` (se instalan solo corriendo POPStarter una vez: `POPSLoader > PS1 SMB`).

### 3. PC - Instalador
```bash
git clone https://github.com/TU_USUARIO/PSBBN-Definitive-Project-SLIM.git
cd PSBBN-Definitive-Project-SLIM
./PSBBN-Definitive-Patch.sh
# 7) Configure Mango SMB -> 192.168.8.1 / PS2SMB / guest / (pass vacio)
# 1) Install PSBBN & HOSDMenu -> elige /dev/mmcblk0 (SD) - 32GB min
# 4) Install Games and Apps -> pon ISOs en games/SMB/DVD/ o directo en Mango
```
- Para PS1 SMB: Renombra `POPSTARTER.ELF` a `SB.SLUS_123.45.ELF` en `games/POPS/` y ejecuta `4)`.
- El instalador genera `config/smb.cfg` y escribe `conf_opl.cfg` en la SD:
```ini
eth_op_mode=1
smb_server_ip=192.168.8.1
smb_share=PS2SMB
smb_user=guest
```

### 4. Boot
Inserta SD+MX4SIO (Slot2) + MC FMCB (Slot1) + cable LAN Mango->PS2. Enciende. PSBBN Game Collection lista `DVD/CD (local BDM)` + `SMB2 [Mango]` con mismo cover-flow. OPL lista ambos + arte en `OPL/ART/`.

---

## Archivos Modificados
- `PSBBN-Definitive-Patch.sh:683` `get_opl_partition()`, `884` mmcblk, `7)` menu
- `scripts/PSBBN-Installer.sh:1710`, `scripts/HOSDMenu-Installer.sh:773` p-suffix
- `scripts/Game-Installer.sh:64` `SMB_PS2_LIST`, `2790` scan SMB2, `2036` system.cnf smb
- `scripts/SMB-Config.sh` nuevo asistente
- `scripts/assets/lang/eng.txt:304`, `spa.txt:304` opción 7

## Performance
- ETH PS2 100 Mbps real ~7-11 MB/s, suficiente FMV 4-5 MB/s. USB 1.1 slim no usado.
- Latencia Mango OpenWrt Samba ~2ms, sin stutter en 95% juegos. ZSO comprimido OK con OPL, NHDDL descomprime a ISO.

## Troubleshooting
- `blkid OPL no detectado`: Verifica SD montada, `sudo blkid -t TYPE=exfat | grep OPL`.
- `POPS SMB negro`: Instala BDM Assault en MC y deja MC insertada.
- `OPL no lista SMB`: Verifica `smb.cfg` y que Mango y PS2 estén en `192.168.8.x`, `ping 192.168.8.1` desde PC en misma WiFi.

Licencia: GPL-3.0 igual que upstream. Creditos: CosmicScale, Berion (APA-Jail), pcm720 (OSDMenu), R3Z3N (ATA Assault).
