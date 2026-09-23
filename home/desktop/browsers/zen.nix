{
  config,
  inputs,
  osConfig,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.browsers;
  palette = import ../../../lib/palette.nix;
in
{
  config = mkIf (cfg.enable && cfg.zen.enable) {
    programs.zen-browser = {
      enable = true;
      # Non-browser handlers stay in home/desktop/xdg.nix (handlr); this
      # claims the HTTP machinery and sets $BROWSER.
      setAsDefaultBrowser = true;

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "always";

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
        in
        {
          isDefault = true;

          extensions.packages = config.my.home.desktop.browsers.userscripts.packages;

          # Chrome-only Vesper UI. There is no userContent on purpose: it would
          # restyle the pages themselves. The Noctalia zen template cannot be
          # used here because nix-managed Zen profiles are read-only.
          userChrome = ''
            /* Vesper dark UI for Zen. */
            @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
            :root {
              --zen-primary-color: ${palette.primary};
              --zen-secondary-color: ${palette.secondary};
              --zen-accent-color: ${palette.primary};
              --toolbar-bgcolor: ${palette.bg} !important;
              --toolbar-color: ${palette.fg} !important;
              --lwt-accent-color: ${palette.bg} !important;
              --lwt-text-color: ${palette.fg} !important;
            }
            #browser, #appcontent { background-color: ${palette.bg} !important; }
            #zen-sidebar-content, #sidebar-box { background-color: ${palette.bg2} !important; }
            .tab-background[selected="true"] { background-color: ${palette.bg3} !important; }
            .tab-label, .tab-text { color: ${palette.fg} !important; }
            #nav-bar { background-color: ${palette.bg} !important; }
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

          containers = {
            "Personal" = {
              id = 1;
              icon = "fingerprint";
              color = "green";
            };
            "School" = {
              id = 2;
              icon = "circle";
              color = "blue";
            };
            "Dev" = {
              id = 3;
              icon = "briefcase";
              color = "purple";
            };
          };

          # Force-overwrite containers.json on activation.
          containersForce = true;

          spaces = {
            "Home" = {
              id = homeSpace;
              position = 1000;
              icon = "🏠";
              container = 1;
            };
            "School" = {
              id = schoolSpace;
              position = 2000;
              icon = "🎓";
              container = 2;
              routes = spaceRoutes.school;
            };
            "Dev" = {
              id = devSpace;
              position = 3000;
              icon = "💻";
              container = 3;
            };
          };

          # Links opened from outside Zen with no matching route land in Home.
          spaceRouting.defaultExternalRoute = homeSpace;

          pins = import (inputs.nix-config-private + "/zen/pins.nix") {
            inherit homeSpace schoolSpace devSpace;
          };

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

          settings = {
            "extensions.autoDisableScopes" = 0;
            # Zen is a self-compiled fork, so this pref is honoured. Without it
            # the unsigned userscript xpis are silently ignored.
            "xpinstall.signatures.required" = false;
            "browser.aboutConfig.showWarning" = false;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.newtabpage.enabled" = false;
            "browser.startup.page" = 3; # resume last session
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.bookmarks.addedImportButton" = false;

            # Disable the built-in password manager
            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;
            "signon.generation.enabled" = false;
            "signon.management.page.breach-alerts.enabled" = false;
            "signon.showAutoCompleteFooter" = false;

            "intl.accept_languages" = "ja-jp,ja,en-us,en";
            "intl.locale.requested" = "ja";

            "zen.view.compact.color-sidebar" = true;
            "zen.theme.content-element-separation" = 0;
            "zen.workspaces.show-workspace-indicator" = true;
            "zen.workspaces.continue-where-left-off" = true;
            # Spaces bind to containers below, so Zen's default per-container
            # essentials would hide every essential whose userContextId is 0.
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

            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "dom.security.https_only_mode" = true;

            "gfx.webrender.all" = true;
            "media.ffmpeg.vaapi.enabled" = true;
          };
        };
    };
  };
}
