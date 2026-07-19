# NixOS Configuration - System Documentation

This repository contains NixOS system configurations for multiple machines.

## Repository Structure

```
nixos-config/
├── machines/
│   ├── framework/     # Framework laptop configuration
│   └── nuc/          # NUC desktop configuration
├── flake.nix         # Flake configuration
└── flake.lock        # Flake lock file
```

## Machine: Framework Laptop

**Location**: `machines/framework/`

### System Specifications
- **Hostname**: framework
- **Kernel**: Latest Linux kernel (`pkgs.linuxPackages_latest`)
- **Boot**: systemd-boot with EFI support
- **Hibernation**: Configured with 96GB swapfile at `/swap/swapfile`
  - Resume device: `/dev/disk/by-uuid/9152d066-aff6-490f-b831-d727c26b82aa`
  - Resume offset: `5889077`

### Power Management

The system uses **auto-cpufreq** for automatic CPU frequency scaling:
- **Service**: `services.auto-cpufreq.enable = true`
- **Configuration**: `configuration.nix:112-124`
- **Behavior**:
  - **Battery mode**: `powersave` governor, auto turbo
  - **AC power**: `performance` governor, auto turbo
  - **Important**: Power profiles daemon is explicitly disabled (`power-profiles-daemon.enable = false`)

### Desktop Environment

**Primary Window Manager**: Niri (`programs.niri.enable = true`)
- Display Manager: ly (`services.displayManager.ly.enable = true`)
- Also available: Hyprland and COSMIC Desktop
- Xwayland support enabled via COSMIC

**Waybar** is enabled system-wide (`programs.waybar.enable = true`)

### Audio
- **PipeWire** with PulseAudio compatibility
- WirePlumber for session management
- Custom service to disable audio auto-mute: `systemd.services.disable-audio-auto-mute`

### Authentication & Security

**YubiKey Integration**:
- Two YubiKeys configured:
  - **YubiKey 5C Nano** (Serial: 33890039) - Permanently inserted, primary authentication
  - **YubiKey 5C NFC** (Serial: 30635716) - Backup/mobile authentication
- Smart card support via pcscd (PIV/CCID)
- Auto-lock on YubiKey removal (udev rule)
- TPM 2.0 enabled

**PAM Configuration** (`configuration.nix:160-177`):
- **ly login**: Smart card PIN-based authentication (password auth disabled)
  - YubiKey must be inserted
  - Enter PIN to login
- **swaylock**: Smart card PIN-based authentication (secure screen unlock)
  - Requires PIN even though Nano is permanently inserted
  - Prevents unauthorized unlock with physical access
- **sudo**: U2F touch only (convenience for frequent use)
  - Quick touch for sudo operations during session
- U2F control set to "sufficient" (either U2F or smart card works)

**YubiKey PIV Setup**:
- Both YubiKeys configured with PIV certificates in slot 9E (Card Authentication)
- Certificates use `CN=rickard` (matches username for consistency)
- Management keys stored on YubiKeys, protected by PIN (no need to remember hex keys!)
- Certificates listed in `~/.eid/authorized_certificates` (checked by pam_p11)
- Scripts available:
  - `~/setup-yubikey-piv.sh <serial>` - Provision new YubiKeys (10 year certs)
  - `~/renew-yubikey-cert.sh <serial>` - Renew certificate and auto-update authorized_certificates
  - `~/standardize-cert-cn.sh <serial>` - Update certificate CN to match username

**Important**: The `renew-yubikey-cert.sh` script automatically updates `~/.eid/authorized_certificates` with both YubiKey certificates after renewal

### Lid Switch Behavior
- **Docked**: ignore
- **On battery**: suspend
- **External power**: lock

### Networking
- NetworkManager enabled
- Hostname: "framework"
- Timezone: Europe/Stockholm

### Virtualization
- **Podman** enabled with Docker compatibility
- Default network DNS enabled for container communication

### Window Managers Available
1. **Niri** (primary) - Scrollable tiling Wayland compositor
2. **Hyprland** - Dynamic tiling Wayland compositor
3. **COSMIC** - COSMIC Desktop Environment

### System Packages

Key installed packages:
- **Editors**: helix
- **Terminals**: kitty, ghostty
- **Browsers**: google-chrome
- **Launcher**: fuzzel
- **Lock/Idle**: swaylock, swayidle, hyprlock
- **Notifications**: swaynotificationcenter (swaync)
- **Shell**: fish (with plugins: done, fzf-fish, forgit, hydro, plugin-git, grc)
- **Audio tools**: pavucontrol, pamixer, pw-volume, pwvucontrol
- **Bluetooth**: bluez, bluez-tools, bluetuith
- **YubiKey**: yubioath-flutter, opensc, yubico-piv-tool, yubikey-manager
- **Niri tools**: niriswitcher, xwayland-satellite
- **Wayland tools**: swww, wl-clipboard, cliphist
- **Screen tools**: sunsetr, brightnessctl, hyprshot, hyprpaper, hyprsunset
- **Development**: devenv, nodejs, code-cursor
- **Calendar**: gcalcli, libnotify

### Nix Configuration
- Flakes enabled
- Nix command enabled
- Trusted users: root, rickard
- Automatic garbage collection: weekly (delete older than 7 days)
- Auto-upgrade enabled from flake `#framework`

### User Account
- **Username**: rickard
- **Shell**: fish
- **Groups**: podman, networkmanager, wheel (sudo)

### State Version
- **25.05** (NixOS unstable/testing)

## Machine: NUC

**Location**: `machines/nuc/`

The NUC is the always-on home server. Besides being a Sway desktop, it runs the
smart-home stack: Home Assistant (`services.home-assistant`), the Matter server
(`services.matter-server`), and a Caddy reverse proxy exposing HA at
`https://gg26c.duckdns.org` (external, DuckDNS) and `http://nuc.local` (internal).

### Home Assistant — climate control

The entire HA setup lives inline in `machines/nuc/configuration.nix` under
`services.home-assistant.config` (helpers, template sensors, scripts, automations).

**Guiding philosophy: cooling-only, and keep it simple.**
Winter heat is handled by water-based subfloor heating on both floors and is **not**
managed by HA — high-thermal-mass concrete walls hold heat easily. The house is SW-facing
with large windows, so the real problem is summer cooling of the main floor (sun load) and
the basement bedroom (heat leak from the adjacent heater/laundry room).

**Hardware & integrations:**
- **AC** — two Mitsubishi inverter heads via MELCloud (`melcloud_home` component):
  `climate.basement_ac` and `climate.living_room_ac`. Cooling only. MELCloud is a laggy,
  rate-limited **cloud** API, so control is set-and-hold (few writes), never rapid toggling.
- **ERV** — Tuya-local (`localtuya`), exposes fan speeds and a heat-exchange **bypass**
  driven by `number.smart_erv_erv_bypass_start_temp_x` (start temp X) and
  `..._erv_bypass_range_y` (range Y). Bypass opens when outdoor air is in the cool band
  `[X, X+Y]`, i.e. only when OA is below indoor → incoming air always *aids* cooling.
- **Room sensors ("alpstuga")** — the source of truth for room temperature/humidity, since
  the AC units' internal return-air sensors are miscalibrated:
  - `sensor.alpstuga_air_quality_monitor_temperature` = **main floor**
  - `sensor.alpstuga_air_quality_monitor_temperature_2` = **basement**
  - `_2` variants of humidity / CO₂ / PM2.5 exist per location too.
- **LK Systems** — water/leak system via a custom-built component (`lksystems`, patched at
  build time in `configuration.nix`).

**AC control model (offset + modulation, alpstuga as authority):**
The AC setpoint is commanded as `room target + per-unit offset`
(`ac_target_temperature_*` + `ac_sensor_offset_*`, offsets ≈ +4 basement / +1 main). The
offset compensates for the miscalibrated internal sensor so the inverter modulates toward
the true room target instead of short-cycling. HA then uses the alpstuga reading as a coarse
on/off authority with dual hysteresis (`ac_hysteresis_on/off`) plus min-run (900s) / min-off
(600s) timers to protect the compressor and minimise cloud calls. This all lives in the
`ac_two_zone_external_control` automation.

**ERV ↔ AC coordination:** none needed. Because the bypass window only opens when OA is
cooler than indoor, free cooling and mechanical cooling always push the same direction — an
earlier `erv_ac_staged_cooling` arbitration automation was removed as unnecessary
complexity. The ERV bypass pre-cools the thermal mass on cool nights (OA usually drops below
18°C); the AC handles daytime sun-load peaks.

**Helpers (`input_*`):**
- `input_boolean.erv_ac_coordination_enabled` — master enable for automated AC control.
- `input_select.erv_mode` — Normal / Boost / Away / Quiet (mapped to fan speeds by
  `script.erv_apply_mode`).
- `input_number.ac_target_temperature_{basement,main_floor}` — desired room temps.
- `input_number.ac_sensor_offset_{basement,main_floor}` — internal-sensor compensation.
- `input_number.ac_hysteresis_{on,off}` — cooling on/off thresholds.

**Automations:**
- `ac_two_zone_external_control` — the two-zone AC cooling thermostat (see model above).
- `erv_apply_mode_on_change` + `script.erv_apply_mode` — apply the selected ERV fan speed.
- `erv_boost_on_poor_air` / `erv_recover_to_auto` / `erv_boost_timeout` — auto-Boost the ERV
  on high CO₂ / PM2.5 / humidity, then recover; independent of cooling.
- `erv_away_when_empty` / `erv_normal_when_occupied` — occupancy-based ERV mode via
  `zone.home`.
- `erv_bypass_window_auto` — computes bypass X/Y from indoor temps and writes them to the
  Tuya ERV (write-on-change only, indoor-aware safety to disable bypass when already cool).

**Verifying changes:** `nix eval .#nixosConfigurations.nuc.config.services.home-assistant.config`
checks the config evaluates; deploy with `nixos-rebuild`; then in HA Developer Tools verify
`climate.basement_ac` / `climate.living_room_ac` react and check Settings → Logs for template
errors.

## Flake Configuration

The system uses Nix flakes for reproducible builds. Main branch is `main`.

### System Upgrade
Auto-upgrade is configured to run automatically:
```nix
system.autoUpgrade = {
  enable = true;
  flake = "/etc/nixos#framework";
  flags = [ "--update-input" "nixpkgs" ];
}
```

## Common Tasks

### Rebuilding the System
```bash
sudo nixos-rebuild switch --flake /etc/nixos#framework
```

### Testing Configuration Changes
```bash
sudo nixos-rebuild test --flake /etc/nixos#framework
```

### Updating Flake Inputs
```bash
cd /etc/nixos
nix flake update
```

### Setting Up a New YubiKey

To provision a new YubiKey with PIV authentication:

```bash
# List available YubiKeys
ykman list

# Run setup script with the serial number
~/setup-yubikey-piv.sh <serial-number>
```

The script will:
1. Change the default PIN (from 123456)
2. Change the default PUK (from 12345678)
3. Generate and protect a new management key
4. Create a self-signed certificate in slot 9E for authentication

### Checking YubiKey Status

```bash
# Check PIV configuration for a specific YubiKey
ykman --device <serial> piv info

# List all connected YubiKeys
ykman list

# View authorized certificates
cat ~/.eid/authorized_certificates
```

### YubiKey Certificate Lifecycle

**Current certificate expiry dates**:
- Nano (33890039): 2035-10-18 (10 years) ✓
- NFC (30635716): 2035-10-18 (10 years) ✓

**To renew a certificate** (automatically updates authorized_certificates):
```bash
~/renew-yubikey-cert.sh <serial-number> [validity-days]
# Default validity is 3650 days (10 years)
```

**Certificate validation**:
- pam_p11 checks certificates in `~/.eid/authorized_certificates`
- No CN-to-username mapping (uses full certificate matching)
- Certificates must not be expired
- Both certificates use `CN=rickard` for consistency

### pam_p11 vs pam_pkcs11

**Currently using**: pam_p11 (lightweight, simple)

**Why pam_p11?**
- Single user setup
- Self-signed certificates
- Simple authorized_certificates approach
- Less configuration overhead

**When to consider pam_pkcs11**:
- Multiple users
- Proper Certificate Authority (CA) setup
- Need CRL/OCSP revocation checking
- LDAP/Active Directory integration

## Notes for AI Assistants

- The working directory in `/etc/nixos` is symlinked to this repository
- Always check which machine configuration you're modifying (framework vs nuc)
- **Primary window manager is Niri** - most user configs will be in `~/.config/niri/`
- Power management is handled by auto-cpufreq, not power-profiles-daemon
- YubiKey authentication is critical - don't break PAM configuration
- The system uses systemd-boot, not GRUB
