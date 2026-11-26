{
  config,
  inputs,
  osConfig,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.browsers;
  palette = import ../../../lib/palette.nix;
in
{
  imports = [ inputs.zen-browser.homeModules.default ];

  config = lib.mkIf (cfg.enable && cfg.zen.enable) {
    # MIME associations are managed via handlr in home/desktop/xdg.nix.
    home.sessionVariables.BROWSER = "zen-beta";

    programs.zen-browser = {
      enable = true;

      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "always";
        PasswordManagerEnabled = false;
        OfferToSaveLogins = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;

        ExtensionSettings =
          let
            # AMO's /latest.xpi also accepts an extension id, which does not move
            # when AMO renames a slug; braces have to be percent-encoded.
            fromAmo = id: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${
                builtins.replaceStrings [ "{" "}" ] [ "%7B" "%7D" ] id
              }/latest.xpi";
              installation_mode = "normal_installed";
            };
          in
          {
            "*".installation_mode = "allowed";
            # uBlock Origin
            "uBlock0@raymondhill.net" = fromAmo "uBlock0@raymondhill.net";
            # Bitwarden
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = fromAmo "{446900e4-71c2-419f-a6a7-df9c091e268b}";
            # SponsorBlock
            "sponsorBlocker@ajay.app" = fromAmo "sponsorBlocker@ajay.app";
            # Keepa
            "amptra@keepa.com" = fromAmo "amptra@keepa.com";
            # Video DownloadHelper
            "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = fromAmo "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
            # Wappalyzer
            "wappalyzer@crunchlabz.com" = fromAmo "wappalyzer@crunchlabz.com";
            # YouTube NonStop
            "{0d7cafdd-501c-49ca-8ebb-e3341caaa55e}" = fromAmo "{0d7cafdd-501c-49ca-8ebb-e3341caaa55e}";
            # YouTube Screenshot
            "{d8b32864-153d-47fb-93ea-c273c4d1ef17}" = fromAmo "{d8b32864-153d-47fb-93ea-c273c4d1ef17}";
            # LINE
            "LINEPorted@FoxRefire" = fromAmo "LINEPorted@FoxRefire";
            # Volume Control
            "{57e8684d-5ae8-47d6-93c9-f870ef0e40a3}" = fromAmo "{57e8684d-5ae8-47d6-93c9-f870ef0e40a3}";
            # weathercock-detector
            "weathercock-detector@kwdev" = fromAmo "weathercock-detector@kwdev";
            # MetaMask
            "webextension@metamask.io" = fromAmo "webextension@metamask.io";
          };
      };

      profiles.${osConfig.my.user.name} =
        let
          homeSpace = "584791db-f69b-40d0-a048-9023a9f98606";
          schoolSpace = "113f65ea-4930-4b92-b06a-d4ba2a80f5c4";
          devSpace = "15c09d3d-9c81-4945-988d-130f2bca1fd1";

          spaceRoutes = import (inputs.nix-config-private + "/zen/space-routes.nix");

          spaceTheme =
            accent: ratio:
            let
              hexDigit = {
                "0" = 0;
                "1" = 1;
                "2" = 2;
                "3" = 3;
                "4" = 4;
                "5" = 5;
                "6" = 6;
                "7" = 7;
                "8" = 8;
                "9" = 9;
                "a" = 10;
                "b" = 11;
                "c" = 12;
                "d" = 13;
                "e" = 14;
                "f" = 15;
              };
              hexByte =
                s:
                let
                  cs = lib.stringToCharacters (lib.toLower s);
                in
                hexDigit.${builtins.elemAt cs 0} * 16 + hexDigit.${builtins.elemAt cs 1};
              channels = hex: map hexByte (builtins.match "#(..)(..)(..)" hex);
              base = channels palette.bg2;
              target = channels accent;
              blended =
                i:
                let
                  b = builtins.elemAt base i;
                  t = builtins.elemAt target i;
                  v = b + ((t - b) * ratio);
                in
                lib.max 0 (lib.min 255 (builtins.floor (v + 0.5)));
            in
            {
              type = "gradient";
              colors = [
                {
                  red = blended 0;
                  green = blended 1;
                  blue = blended 2;
                  # isCustom = true expects a CSS string in color.c, while
                  # zen-browser-flake emits an [r g b] array.
                  custom = false;
                  algorithm = "floating";
                  primary = true;
                  lightness = 0;
                  type = "undefined";
                }
              ];
              opacity = 1.0;
              texture = 0.0;
            };
        in
        {
          isDefault = true;

          extensions.packages = config.my.home.desktop.browsers.userscripts.packages;

          # Chrome-only Vesper UI. There is no userContent on purpose: it would
          # restyle the pages themselves. The Noctalia zen template cannot be
          # used here because nix-managed Zen profiles are read-only.
          userChrome = ''
            /* Vesper dark UI for Zen (background stays owned by per-space themes). */
            @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
            :root {
              --zen-primary-color: ${palette.primary};
              --zen-secondary-color: ${palette.secondary};
              --zen-accent-color: ${palette.primary};
              --toolbar-color: ${palette.fg} !important;
              --lwt-text-color: ${palette.fg} !important;
            }
            #appcontent { background-color: ${palette.bg} !important; }
            #sidebar-box { background-color: ${palette.bg2} !important; }
            .tab-background[selected="true"] { background-color: ${palette.bg3} !important; }
            .tab-label, .tab-text { color: ${palette.fg} !important; }
            #urlbar-background { background-color: ${palette.bg2} !important; }
            #urlbar, #urlbar-input { color: ${palette.fg} !important; }
            /* Text selection inside the chrome (e.g. urlbar); without this
               Firefox uses the system (GTK) Highlight color. */
            ::selection {
              background-color: ${palette.primary} !important;
              color: #000000 !important;
            }
          '';

          search = {
            default = "google";
            force = true;
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "https://nixos.org/favicon.png";
                definedAliases = [ "@n" ];
              };
              "GitHub" = {
                urls = [ { template = "https://github.com/search?q={searchTerms}&type=repositories"; } ];
                icon = "https://github.com/favicon.ico";
                definedAliases = [ "@gh" ];
              };
              "Translate into ja" = {
                urls = [
                  { template = "https://translate.google.com/?sl=auto&tl=ja&text={searchTerms}&op=translate"; }
                ];
                icon = "https://www.gstatic.com/lamda/images/favicon_v2_78462ef77d0c794346ad.png";
                definedAliases = [ "@ja" ];
              };
              "Translate into en" = {
                urls = [
                  { template = "https://translate.google.com/?sl=auto&tl=en&text={searchTerms}&op=translate"; }
                ];
                icon = "https://www.gstatic.com/lamda/images/favicon_v2_78462ef77d0c794346ad.png";
                definedAliases = [ "@en" ];
              };
            };
          };

          # id = 2 preserves the existing School cookies and avoids colliding
          # with legacy id = 1 data.
          containers = {
            "School" = {
              id = 2;
              icon = "circle";
              color = "blue";
            };
          };

          containersForce = true;

          spacesForce = true;

          spaces = {
            "Home" = {
              id = homeSpace;
              position = 1000;
              icon = "🏠";
              theme = spaceTheme palette.bg2 0.0;
            };
            "School" = {
              id = schoolSpace;
              position = 2000;
              icon = "🎓";
              container = 2;
              routes = spaceRoutes.school;
              theme = spaceTheme palette.link 0.12;
            };
            "Dev" = {
              id = devSpace;
              position = 3000;
              icon = "💻";
              theme = spaceTheme palette.primary 0.12;
            };
          };

          # Links opened from outside Zen with no matching route land in Home.
          spaceRouting.defaultExternalRoute = homeSpace;

          pins = import (inputs.nix-config-private + "/zen/pins.nix") { };

          # Betterfox (BetterZen) adds privacy, telemetry and performance prefs with mkDefault
          presets.betterfox.enable = true;

          mods = [
            "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
            "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
            "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
            "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
          ];

          extensionButtons."nav-bar" = [
            "uBlock0@raymondhill.net" # uBlock Origin
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" # Bitwarden
          ];

          keyboardShortcuts = [
            {
              id = "key_quitApplication";
              disabled = true;
            }
          ];

          settings = {
            "extensions.autoDisableScopes" = 0;
            # Zen is a self-compiled fork, so this pref is honoured. Without it
            # the unsigned userscript xpis are silently ignored.
            "xpinstall.signatures.required" = false;
            "browser.aboutConfig.showWarning" = false;
            "browser.newtabpage.enabled" = false;
            "browser.startup.page" = 3; # resume last session
            "browser.bookmarks.addedImportButton" = false;

            "intl.accept_languages" = "ja-jp,ja,en-us,en";
            "intl.locale.requested" = "ja";

            "zen.view.compact.color-sidebar" = true;
            "zen.theme.content-element-separation" = 0;
            "zen.workspaces.show-workspace-indicator" = true;
            "zen.workspaces.continue-where-left-off" = true;
            # Home/Dev/Essentials share the default context 0 and School binds
            # to container 2, so Zen's per-container essentials would hide
            # every essential whose userContextId is 0.
            "zen.workspaces.separate-essentials" = false;
            # A container tab lands in the space bound to that container.
            "zen.workspaces.force-container-workspace" = true;
            # Sync only pinned/essential tabs between windows, so ordinary tabs
            # stay independent per window.
            "zen.window-sync.enabled" = true;
            "zen.window-sync.sync-only-pinned-tabs" = true;
            "zen.theme.essentials-favicon-bg" = true;
            "zen.urlbar.behavior" = "float";

            "zen.welcome-screen.seen" = true;
            "browser.aboutwelcome.enabled" = false;

            # default color theme of sites
            # 0=dark, 1=light, 2=system, 3=browser
            "layout.css.prefers-color-scheme.content-override" = 2;

            # Prevent Mozilla Sync from colliding with Nix-declared spaces.
            "services.sync.engine.spaces" = false;

            "gfx.webrender.all" = true;
          };
        };
    };
  };
}
