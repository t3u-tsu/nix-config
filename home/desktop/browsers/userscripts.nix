{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.browsers.userscripts;

  sources = import ../../../_sources/generated.nix {
    inherit (pkgs)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  # Gecko application id directory Firefox reads profile extensions from.
  extensionDir = "share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

  # Wraps an upstream .user.js in the minimum extension a userscript manager
  # would otherwise provide: a content script plus a shim for the GM APIs.
  mkUserscriptXpi =
    {
      pname,
      geckoId,
      src,
      userScriptPath,
      matches,
      runAt ? "document_idle",
      shim,
    }:
    pkgs.runCommand "${pname}.xpi"
      {
        nativeBuildInputs = [
          pkgs.gawk
          pkgs.zip
        ];
      }
      ''
        version=$(awk '/@version[[:space:]]/ { print $3; exit }' ${src}/${userScriptPath})
        if [ -z "$version" ]; then
          echo "cannot extract @version from ${userScriptPath}" >&2
          exit 1
        fi

        mkdir -p pkg/userscripts
        cp ${src}/${userScriptPath} pkg/userscripts/main.js

        cat > pkg/userscripts/shim.js <<SHIM
        ${shim}
        SHIM

        cat > pkg/manifest.json <<EOF
        {
          "manifest_version": 2,
          "name": "${pname}",
          "version": "$version",
          "browser_specific_settings": { "gecko": { "id": "${geckoId}" } },
          "permissions": ["storage"],
          "content_scripts": [
            {
              "matches": ${builtins.toJSON matches},
              "js": ["userscripts/shim.js", "userscripts/main.js"],
              "run_at": "${runAt}"
            }
          ]
        }
        EOF

        # Info-ZIP's zip ignores SOURCE_DATE_EPOCH and writes non-deterministic
        # extra fields, so pin the entry timestamps and drop the extra fields.
        find pkg -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

        mkdir -p "$out/${extensionDir}"
        (cd pkg && zip -qrX "$out/${extensionDir}/${geckoId}.xpi" .)
      '';

  akiShim = ''
    // GM.* shim: the userscript runs unmodified as a content script.
    (() => {
      const store = {};
      const ready = browser.storage.local.get().then((v) => Object.assign(store, v));

      globalThis.GM = {
        getValue: async (key, fallback) => {
          await ready;
          return key in store ? store[key] : fallback;
        },
        setValue: (key, value) => {
          store[key] = value;
          return browser.storage.local.set({ [key]: value });
        },
      };

      globalThis.GM_info = {
        script: {
          version: "$version",
          supportURL: "https://github.com/shapoco/aki-boost",
        },
      };
    })();
  '';

  danimeShim = ''
    // Legacy GM_* shim. Menu commands are dropped; the toggles are fixed here
    // because the extension is managed declaratively.
    (() => {
      const store = {};
      const fixed = {
        menu: true,
        addProductionYear: false,
        seekbarTitle: true,
        hideDetail: false,
      };
      browser.storage.local.get().then((v) => Object.assign(store, v));

      globalThis.GM_getValue = (key, fallback) => {
        if (key in store) return store[key];
        if (key in fixed) return fixed[key];
        return fallback;
      };
      globalThis.GM_setValue = (key, value) => {
        store[key] = value;
        browser.storage.local.set({ [key]: value });
      };
      globalThis.GM_registerMenuCommand = () => {};
    })();
  '';
in
{
  options.my.home.desktop.browsers.userscripts = {
    enable = mkEnableOption "Zen userscripts packaged as declarative extensions";
    packages = mkOption {
      type = types.listOf types.package;
      readOnly = true;
      description = "Userscript-backed extensions to install into the Zen profile.";
    };
  };

  config = {
    my.home.desktop.browsers.userscripts.packages = optionals cfg.enable [
      (mkUserscriptXpi {
        pname = "aki-boost";
        geckoId = "aki-boost@t3u.internal";
        src = sources.aki-boost.src;
        userScriptPath = "dist/aki-boost.user.js";
        matches = [
          "https://akizukidenshi.com/*"
          "https://www.akizukidenshi.com/*"
        ];
        runAt = "document_start";
        shim = akiShim;
      })
      (mkUserscriptXpi {
        pname = "danime-plus";
        geckoId = "danime-plus@t3u.internal";
        src = sources.danime-plus.src;
        userScriptPath = "script/danimeplus.user.js";
        matches = [ "https://animestore.docomo.ne.jp/animestore/*" ];
        shim = danimeShim;
      })
    ];
  };
}
