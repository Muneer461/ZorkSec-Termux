# ZorkSec-Termux

<div align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Platform-Android%20(Termux)-brightgreen.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Author-Muneer461-red.svg" alt="Author">
</div>

<br>

**ZorkSec-Termux** is a professional open-source cybersecurity platform built specifically for **Android (Termux)**. It transforms your Android phone into a powerful penetration testing workstation with **200+ ethical hacking tools** — all accessible directly from your Termux terminal.

> Part of the ZorkSec ecosystem — the official Android companion to the ZorkSec Linux Platform.

---

## 📱 What This Does

- **Installs 200+ cybersecurity tools** in Termux automatically
- **Categorizes** them into logical sections (Information Gathering, OSINT, Web Security, Exploitation, etc.)
- **Submenus** let you choose **Install All** in a category or **individual tools** one by one
- Auto-detects dependencies (`requirements.txt`, `go.mod`, `Cargo.toml`, `package.json`, `Gemfile`, `Makefile`, etc.)
- Auto-installs package managers (Go, Rust, Node.js, Ruby, Python pip)
- Verifies every tool after installation with `--version`/`--help`
- Automatically creates **symlinks** so every tool is available directly from your terminal
- Full logging, health checks, backup/restore, repository management
- **Never stops** if one tool fails — continues with the rest

---

## 🚀 Quick Start

### 1. Install Termux (F-Droid Version)

⚠️ **IMPORTANT:** Install Termux from **F-Droid**, NOT Google Play (Play Store version is outdated).

[Download Termux from F-Droid](https://f-droid.org/packages/com.termux/)

### 2. Setup Storage

```bash
termux-setup-storage
pkg update && pkg upgrade -y