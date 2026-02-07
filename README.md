# OpenClaw Railway Template

One-click Railway deployment for OpenClaw with advanced setup wizard, backup import/export, and debug console.

## ✨ Features

- **🚀 One-Click Deploy**: Deploy OpenClaw to Railway in seconds
- **📦 Backup Import/Export**: Import existing backups or export your config
- **🔧 Debug Console**: Web-based debugging tools with safe allowlisted commands
- **⚙️ Config Editor**: Edit `openclaw.json` directly from the browser
- **🔐 Password Protected Setup**: Secure setup wizard with HTTP Basic Auth
- **📱 Channel Setup**: Configure Telegram, Discord, and Slack during onboarding
- **🔄 Gateway Management**: Start, stop, and restart the gateway from the UI

## 🚀 Quick Deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/your-template-code)

## 📋 Setup Steps

1. **Deploy to Railway** - Click the button above
2. **Set SETUP_PASSWORD** - Add this variable in Railway dashboard
3. **Wait for build** - First build takes ~5-10 minutes
4. **Access /setup** - Open your Railway URL + `/setup`
5. **Run Setup** - Choose your auth provider and complete onboarding

## 🔐 Environment Variables

### Required

- `SETUP_PASSWORD` - Password for /setup (use a strong password!)

### Optional

- `OPENCLAW_STATE_DIR` - Where config/data is stored (default: `~/.openclaw`)
- `OPENCLAW_WORKSPACE_DIR` - Where workspace files are stored (default: `~/.openclaw/workspace`)
- `OPENCLAW_GATEWAY_TOKEN` - Gateway auth token (auto-generated if not set)
- `OPENCLAW_PUBLIC_PORT` - External port (default: `8080`)

## 📦 Backup Import/Export

### Export Backup

1. Go to `/setup`
2. Click "Download backup (.tar.gz)"
3. Save the `.tar.gz` file

### Import Backup

1. Go to `/setup`
2. Under "Import backup", click "Choose File"
3. Select your `.tar.gz` backup
4. Click "Import"
5. Wait for automatic restart

**⚠️ Important**: Import restores into `/data` and restarts the gateway. Only use backups created by this template.

## 🔧 Debug Console

The debug console lets you run safe commands without SSH access:

### Available Commands

**Gateway Control (Wrapper-Managed):**
- `gateway.restart` - Restart the gateway process
- `gateway.stop` - Stop the gateway
- `gateway.start` - Start the gateway

**OpenClaw CLI:**
- `openclaw.version` - Show OpenClaw version
- `openclaw.status` - Check gateway status
- `openclaw.health` - Run health check
- `openclaw.doctor` - Run diagnostic checks
- `openclaw.logs.tail` - Show last N log lines (arg: number of lines)
- `openclaw.config.get` - Get config value (arg: config path)

### Usage

1. Go to `/setup`
2. Find "Debug console" section
3. Select a command from dropdown
4. Add optional argument if needed
5. Click "Run"

## ⚙️ Config Editor

Edit `openclaw.json` directly from the browser:

1. Go to `/setup`
2. Find "Config editor" section
3. Click "Reload" to load current config
4. Edit the JSON
5. Click "Save" (creates timestamped `.bak` backup)

**⚠️ Warning**: Invalid JSON will break your config. Use with caution.

## 🔄 Railway Volume

For persistent storage, mount a Railway volume at `/data`:

1. In Railway dashboard, go to your service
2. Click "Variables" → "Add Variable"
3. Add: `OPENCLAW_STATE_DIR=/data/.openclaw`
4. Add: `OPENCLAW_WORKSPACE_DIR=/data/workspace`
5. Go to "Settings" → "Volumes"
6. Add volume mounted at `/data`

## 🐛 Troubleshooting

### Setup page returns 500

- Check that `SETUP_PASSWORD` is set in Railway variables
- Restart the service

### Gateway won't start

- Check logs: Use debug console → `openclaw.logs.tail`
- Run diagnostics: Use debug console → `openclaw.doctor`
- Check config: Use config editor to verify `openclaw.json`

### Import backup fails

- Ensure backup was created by this template
- Check that `/data` volume is mounted
- Verify backup is under 250MB

### Can't access /openclaw UI

- Check gateway status: Debug console → `openclaw.status`
- Restart gateway: Debug console → `gateway.restart`
- Check logs: Debug console → `openclaw.logs.tail`

## 🔧 Advanced Configuration

### Manual Gateway Token

If you want to set a specific gateway token:

```bash
OPENCLAW_GATEWAY_TOKEN=your-secret-token-here
```

### Change Internal Gateway Port

```bash
INTERNAL_GATEWAY_PORT=18789  # default
```

### Build from specific OpenClaw version

In Dockerfile, change:

```dockerfile
ARG OPENCLAW_GIT_REF=main
```

to:

```dockerfile
ARG OPENCLAW_GIT_REF=v1.2.3  # or any tag/branch
```

## 📝 How It Works

1. **Dockerfile** builds OpenClaw from source
2. **Wrapper server** (`src/server.js`) provides:
   - Setup wizard at `/setup`
   - Backup import/export
   - Debug console
   - Config editor
   - Reverse proxy to OpenClaw gateway
3. **Gateway** runs on internal port (18789 by default)
4. **Wrapper** handles external traffic on port 8080

## 🆚 Differences from Official OpenClaw

This template adds:
- Web-based setup wizard (no terminal required)
- Backup import/export functionality
- Debug console for troubleshooting
- Config editor with backup
- Automatic gateway token generation
- Railway-optimized configuration

## 🤝 Contributing

Found a bug or want to add a feature? Open an issue or PR!

## 📄 License

MIT - See LICENSE file

## 🙏 Credits

Built on [OpenClaw](https://github.com/openclaw/openclaw) by the OpenClaw team.
