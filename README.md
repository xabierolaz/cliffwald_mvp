# 🏰 Cliffwald MVP (C# MonoGame Edition)

> **Current Status:** 🏗️ Pre-Alpha (Architecture Phase)
> **Engine:** MonoGame / FNA (.NET 6)
> **Architecture:** Authoritative Server (LiteNetLib) + Client (Code-Only Rendering)

## 🎯 Project Vision
A Social MMO RPG combining the life-sim mechanics of a Magic Academy with the visual style of *Eastward* (32x48px Pixel Art + Dynamic Lighting).

---

## 🚦 Live Feature Tracker
*Since this project evolves rapidly, this list represents the ACTUAL state of the codebase, not just the plan.*

### ✅ Implemented (Working in Code)
* [ ] **Core:** Solution Structure (.sln with Client/Server/Shared).
* [ ] **Networking:** Basic UDP Connection loop.
* [ ] **Graphics:** Window creation and basic rendering.

### 🚧 In Progress (Current Sprint)
* [ ] Loading the first "Student" sprite (32x48px).
* [ ] Basic movement synchronization (Client sends input -> Server updates pos -> Client renders).

### 🔮 Backlog (Next Steps)
* [ ] $1 Unistroke Gesture System (Mouse Magic).
* [ ] Lighting Shader (Normal Maps).
* [ ] NPC AI Schedules (The "Echoes").

---

## 🛠️ Developer Guide (Human & AI)

### Prerequisites
* .NET 6.0 SDK or newer.
* Visual Studio 2022 (or VS Code with C# Dev Kit).

### How to Run
1.  **Server:** Navigate to `Cliffwald.Server` and run `dotnet run`.
2.  **Client:** Navigate to `Cliffwald.Client` and run `dotnet run`.

---

## 📜 Update Log
* **[DATE]:** Repository initialized.
