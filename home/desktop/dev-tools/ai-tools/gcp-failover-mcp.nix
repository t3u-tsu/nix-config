{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
  username = config.home.username;

  gcpFailoverMcp = pkgs.writeYshApplication {
    name = "gcp-failover-mcp";
    runtimeInputs = [
      pkgs.google-cloud-sdk
      pkgs.coreutils
    ];
    text = ''
            func safe_str(v) {
              var t = type(v)
              if (t === "Null") {
                return ("null")
              }
              if (t === "Str") {
                return (v)
              }
              if (t === "Int" or t === "Float" or t === "Bool") {
                return ("$v")
              }
              return ("")
            }

            proc send_json(; resp) {
              var line = $(json write (resp) | tr '\n' ' ')
              echo "$line"
            }

            proc handle_initialize(; req_id) {
              var resp = {
                jsonrpc: "2.0",
                id: req_id,
                result: {
                  protocolVersion: "2024-11-05",
                  capabilities: {
                    tools: {}
                  },
                  serverInfo: {
                    name: "gcp-failover-mcp",
                    version: "0.1.0"
                  }
                }
              }
              send_json (resp)
            }

            proc handle_tools_list(; req_id) {
              var tools = [
                {
                  name: "gcp_failover_status",
                  description: "Query power status (RUNNING / TERMINATED), zone, external IP, and disk status of torii-chan-gcp in Google Cloud.",
                  inputSchema: {
                    type: "object",
                    properties: {
                      instance: {
                        type: "string",
                        description: "GCE instance name (defaults to torii-chan-gcp)"
                      },
                      zone: {
                        type: "string",
                        description: "GCP zone where instance is located (defaults to asia-northeast1-b)"
                      }
                    }
                  }
                },
                {
                  name: "gcp_failover_start",
                  description: "Start the GCP failover instance (torii-chan-gcp) in Google Cloud (IaaS power control only; does not switch Cloudflare DNS, use failover.ysh for full failover).",
                  inputSchema: {
                    type: "object",
                    properties: {
                      instance: {
                        type: "string",
                        description: "GCE instance name (defaults to torii-chan-gcp)"
                      },
                      zone: {
                        type: "string",
                        description: "GCP zone where instance is located (defaults to asia-northeast1-b)"
                      }
                    }
                  }
                },
                {
                  name: "gcp_failover_stop",
                  description: "Stop the GCP failover instance (torii-chan-gcp) in Google Cloud to halt compute and IP billing (IaaS power control only; does not restore Cloudflare DNS, use failover.ysh for full failback).",
                  inputSchema: {
                    type: "object",
                    properties: {
                      instance: {
                        type: "string",
                        description: "GCE instance name (defaults to torii-chan-gcp)"
                      },
                      zone: {
                        type: "string",
                        description: "GCP zone where instance is located (defaults to asia-northeast1-b)"
                      }
                    }
                  }
                }
              ]
              var resp = {
                jsonrpc: "2.0",
                id: req_id,
                result: {
                  tools: tools
                }
              }
              send_json (resp)
            }

            proc handle_tools_call(; req_id, params) {
              var tool_name = ""
              var args = {}
              if (type(params) === "Dict") {
                var raw_name = get(params, "name", null)
                setvar tool_name = safe_str(raw_name)
                var raw_args = get(params, "arguments", null)
                if (type(raw_args) === "Dict") {
                  setvar args = raw_args
                }
              }

              var instance_name = "torii-chan-gcp"
              var zone_name = "asia-northeast1-b"

              if (type(args) === "Dict") {
                var raw_inst = get(args, "instance", null)
                if (type(raw_inst) === "Str" and len(raw_inst) > 0) {
                  setvar instance_name = raw_inst
                }
                var raw_zone = get(args, "zone", null)
                if (type(raw_zone) === "Str" and len(raw_zone) > 0) {
                  setvar zone_name = raw_zone
                }
              }

              var tmp = $(mktemp)
              var cmd_failed = false

              case (tool_name) {
                ("gcp_failover_status") {
                  try {
                    gcloud compute instances describe "$instance_name" --zone="$zone_name" --format=json > $tmp 2>&1
                  }
                  if failed { setvar cmd_failed = true }
                }
                ("gcp_failover_start") {
                  try {
                    gcloud compute instances start "$instance_name" --zone="$zone_name" --format=json > $tmp 2>&1
                  }
                  if failed { setvar cmd_failed = true }
                }
                ("gcp_failover_stop") {
                  try {
                    gcloud compute instances stop "$instance_name" --zone="$zone_name" --format=json > $tmp 2>&1
                  }
                  if failed { setvar cmd_failed = true }
                }
                (else) {
                  rm -f $tmp
                  var err_resp = {
                    jsonrpc: "2.0",
                    id: req_id,
                    error: {
                      code: -32601,
                      message: "Unknown tool: $tool_name"
                    }
                  }
                  send_json (err_resp)
                  return
                }
              }

              var raw_out = ""
              read --all (&raw_out) < $tmp
              rm -f $tmp

              if (cmd_failed) {
                var fail_resp = {
                  jsonrpc: "2.0",
                  id: req_id,
                  result: {
                    content: [
                      {
                        type: "text",
                        text: """Execution failed for $tool_name ($instance_name in $zone_name):
      $raw_out"""
                      }
                    ],
                    isError: true
                  }
                }
                send_json (fail_resp)
                return
              }

              var result_text = raw_out
              if (tool_name === "gcp_failover_status") {
                var vm = null
                var parsed_ok = true
                try {
                  json read (&vm) <<< "$raw_out" 2> /dev/null
                }
                if failed { setvar parsed_ok = false }

                if (parsed_ok and type(vm) === "Dict") {
                  var raw_st = get(vm, "status", null)
                  var st = "UNKNOWN"
                  if (type(raw_st) === "Str" and len(raw_st) > 0) {
                    setvar st = raw_st
                  }

                  var ext_ip = "none (stopped)"
                  var ifaces = get(vm, "networkInterfaces", [])
                  if (type(ifaces) === "List" and len(ifaces) > 0 and type(ifaces[0]) === "Dict") {
                    var acs = get(ifaces[0], "accessConfigs", [])
                    if (type(acs) === "List" and len(acs) > 0 and type(acs[0]) === "Dict") {
                      var raw_ip = get(acs[0], "natIP", null)
                      if (type(raw_ip) === "Str" and len(raw_ip) > 0) {
                        setvar ext_ip = raw_ip
                      }
                    }
                  }

                  var disk_summary = "none"
                  var disks = get(vm, "disks", [])
                  if (type(disks) === "List" and len(disks) > 0 and type(disks[0]) === "Dict") {
                    var dname = "boot"
                    var raw_dname = get(disks[0], "deviceName", null)
                    if (type(raw_dname) === "Str" and len(raw_dname) > 0) {
                      setvar dname = raw_dname
                    }
                    var dsize = "10"
                    var raw_dsize = get(disks[0], "diskSizeGb", null)
                    if (type(raw_dsize) === "Str" or type(raw_dsize) === "Int") {
                      setvar dsize = "$raw_dsize"
                    }
                    setvar disk_summary = "$dname ($dsize GB)"
                  }

                  setvar result_text = """
      Instance: $instance_name
      Zone: $zone_name
      Status: $st
      External IP: $ext_ip
      Boot Disk: $disk_summary
      """
                }
              }

              var ok_resp = {
                jsonrpc: "2.0",
                id: req_id,
                result: {
                  content: [
                    {
                      type: "text",
                      text: result_text
                    }
                  ],
                  isError: false
                }
              }
              send_json (ok_resp)
            }

            proc main() {
              while read -r line {
                var trimmed = line.trim()
                if (len(trimmed) === 0) {
                  continue
                }

                var req = null
                try {
                  json read (&req) <<< "$trimmed" 2> /dev/null
                }
                if failed {
                  continue
                }

                if (type(req) !== "Dict") {
                  continue
                }

                var req_id = get(req, "id", null)
                var raw_method = get(req, "method", null)
                var method = safe_str(raw_method)
                var params = get(req, "params", {})

                if (type(req_id) === "Null") {
                  continue
                }

                case (method) {
                  ("initialize") {
                    handle_initialize (req_id)
                  }
                  ("tools/list") {
                    handle_tools_list (req_id)
                  }
                  ("tools/call") {
                    handle_tools_call (req_id, params)
                  }
                  ("ping") {
                    var ping_resp = {
                      jsonrpc: "2.0",
                      id: req_id,
                      result: {}
                    }
                    send_json (ping_resp)
                  }
                  (else) {
                    var err_resp = {
                      jsonrpc: "2.0",
                      id: req_id,
                      error: {
                        code: -32601,
                        message: "Method not found: $method"
                      }
                    }
                    send_json (err_resp)
                  }
                }
              }
            }

            main
    '';
  };

  mcpConfig = pkgs.writeText "codewhale-mcp.json" ''
    {
      "timeouts": {
        "connect_timeout": 10,
        "execute_timeout": 60,
        "read_timeout": 120
      },
      "servers": {
        "gcp-failover-mcp": {
          "command": "gcp-failover-mcp",
          "args": [],
          "env": {
            "PATH": "/etc/profiles/per-user/${username}/bin:${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
          },
          "disabled": false,
          "enabled": true,
          "required": false,
          "enabled_tools": [],
          "disabled_tools": []
        }
      }
    }
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      gcpFailoverMcp
    ];

    home.activation.codewhaleMcpConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${config.home.homeDirectory}/.codewhale
      install -m 600 ${mcpConfig} ${config.home.homeDirectory}/.codewhale/mcp.json
    '';
  };
}
