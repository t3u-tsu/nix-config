#!/usr/bin/env node

'use strict';
const { spawn } = require('node:child_process');
const readline = require('node:readline');

const ENV_BIN = process.env.CONOHA_MCP_ENV || '/run/current-system/sw/bin/env';
const MCP_CMD = process.env.CONOHA_MCP_CMD || 'npm';
const MCP_ARGS = (process.env.CONOHA_MCP_ARGS || 'exec --yes @gmo-internet/conoha-vps-mcp@latest').split(/\s+/);

const child = spawn(ENV_BIN, [MCP_CMD, ...MCP_ARGS], { stdio: ['pipe', 'pipe', 'inherit'] });

process.stdin.pipe(child.stdin);

function safePattern(original) {
  const m = original.match(/\{\s*(\d+)\s*(?:,\s*(\d+)\s*)?\}/);
  if (m) {
    return m[2] ? `^.{${m[1]},${m[2]}}$` : `^.{${m[1]}}$`;
  }
  return '^.{0,255}$';
}

function fixPatterns(schema) {
  if (!schema || typeof schema !== 'object') return;
  for (const [k, v] of Object.entries(schema)) {
    if (k === 'pattern' && typeof v === 'string' && v.includes('(?=')) {
      schema[k] = safePattern(v);
    } else if (typeof v === 'object') {
      fixPatterns(v);
    }
  }
}

const rl = readline.createInterface({ input: child.stdout });
rl.on('line', (line) => {
  try {
    const msg = JSON.parse(line);
    if (msg && msg.result && Array.isArray(msg.result.tools)) {
      for (const tool of msg.result.tools) {
        fixPatterns(tool.inputSchema);
        fixPatterns(tool.outputSchema);
      }
    }
    process.stdout.write(JSON.stringify(msg) + '\n');
  } catch {
    process.stdout.write(line + '\n');
  }
});

rl.on('close', () => {
  process.stdout.end();
  child.kill();
});
process.on('SIGINT', () => child.kill());
process.on('SIGTERM', () => child.kill());
