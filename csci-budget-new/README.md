# Budget - Local Development Setup

Simple guide to run the Budget app with local Supabase instance.

## Prerequisites

- Xcode 16.1
- [OrbStack](https://orbstack.dev) (Recommended) or Docker Desktop
- [Supabase CLI](https://supabase.com/docs/guides/cli)

## Quick Start

### 1. Install Supabase CLI
```bash
brew install supabase/tap/supabase
```

### 2. Start Local Environment
```bash
# Initialize Supabase
supabase init

# Start local Supabase
supabase start
```

### 3. Edge Functions
```bash
# Serve edge functions locally
supabase functions serve
```

## Common Commands

```bash
# Start/Stop Supabase
supabase start
supabase stop

# Reset database
supabase db reset

# Check status
supabase status
```
