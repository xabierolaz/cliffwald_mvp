# 🏭 CLIFFWALD STUDIO - AUTONOMOUS AGENT PROTOCOL (V9.0)

> **FRAMEWORK:** MonoGame (.NET 6+).
> **ARCHITECTURE:** Pure Code-First (No visual editors).
> **PLATFORM:** PC (Dev) -> Nintendo Switch (Production).
> **VISUAL TARGET:** "Eastward" Aesthetic (High-Res Pixel Art + Normal Map Lighting).
> **FEEDBACK SYSTEM:** Headless rendering to PNG/GIF via `SixLabors.ImageSharp`.

---

## 1. THE GOLDEN RULES (SYSTEM DOCTRINE)
1.  **Code is Truth:** We do not rely on `.mgcb` GUI tools manually. Assets are loaded via strict file paths in code.
2.  **Visual Verification (Anti-Hallucination):**
    * The User cannot always run the game.
    * **MANDATORY:** Every visual feature (sprite movement, lighting, UI) must have a "Render Test".
    * The [RENDER_ENGINEER] must implement a system to render frames to an off-screen buffer and save them as `.png` or animated `.gif` to the `Output/Previews/` folder using `SixLabors.ImageSharp`.
3.  **Strict Isolation:**
    * `Cliffwald.Server`: Headless. No GraphicsDevice. Logic only.
    * `Cliffwald.Client`: Visuals only. Interpolates state.
    * `Cliffwald.Shared`: Pure Data (Packets, Physics Structs).

---

## 2. AGENT SQUADS & ROLES

### 🧠 SQUAD A: SYSTEM ARCHITECTURE (The Brains)
*Responsible for the invisible backbone and project health.*

#### [ROLE: LEAD_ARCHITECT]
* **Mission:** Solution Integrity.
* **Directives:**
    * Manage `Cliffwald.sln`.
    * **Crucial:** Add NuGet package `SixLabors.ImageSharp` to the Client project for screenshot generation.
    * Ensure strict dependency flow: `Client -> Shared <- Server`.

#### [ROLE: NET_ENGINEER]
* **Mission:** The MMO Heartbeat.
* **Directives:**
    * Implement `LiteNetLib` (UDP).
    * Manage the "Game Loop": 60 Ticks/Sec on Server.
    * **Lag Compensation:** Implement Client-Side Prediction for the Player and Snapshot Interpolation for other entities.

---

### 🎨 SQUAD B: VISUAL ENGINE (The Eyes)
*Responsible for the Art and the "Eastward" look.*

#### [ROLE: RENDER_ENGINEER] (High Priority)
* **Mission:** The Lighting Pipeline & Export.
* **Directives:**
    * **Lighting:** Implement a custom `SpriteBatch` extension that accepts `Texture2D albedo` and `Texture2D normalMap`.
    * **The GIF Generator:** Create a helper class `VisualTester.cs`.
        * Function: `RecordAnimation(string animationName, int frames)` -> Saves `Output/Previews/{name}.gif`.
        * Use this to prove to the User that animations are working.

#### [ROLE: ANIMATION_CODER]
* **Mission:** Sprite Logic.
* **Directives:**
    * Define animations in C# Code (`StudentAnimations.cs`).
    * Structure: 32x48px grid.
    * State Machine: Idle -> Walk -> Cast -> Stunned.

---

### 🔨 SQUAD C: GAMEPLAY & WORLD (The Soul)

#### [ROLE: INPUT_MASTER]
* **Mission:** Controls.
* **Directives:**
    * Abstract Input: `InputState.Left`, `InputState.Cast`.
    * **Mouse Magic:** Implement the **$1 Unistroke Recognizer** algorithm in C# to detect shapes drawn with the mouse (or right stick on Switch).

#### [ROLE: SERVER_BRAIN]
* **Mission:** The Population (84 Students).
* **Directives:**
    * Manage the AI States for the 84 agents.
    * Logic: If no player is near an AI, run simplified logic (Sleep Mode) to save CPU.

---

### 🛡️ SQUAD D: SUPPORT (The Shield)

#### [ROLE: SCRIBE]
* **Mission:** Documentation & Logs.
* **Directives:**
    * After every visual update, update `README.md` and link the generated GIF from `Output/Previews/`.
    * Keep track of "Implemented Features" vs "Backlog".

---

## 3. DIRECTORY STRUCTURE (MANDATORY)
* `Cliffwald.sln`
* `Source/`
    * `Cliffwald.Client/` (MonoGame)
    * `Cliffwald.Server/` (Console App)
    * `Cliffwald.Shared/` (Class Library)
* `Assets/`
    * `Textures/` (Raw PNGs)
    * `Shaders/` (.fx files)
* `References/` (User uploads inspiration images here).
* `Output/Previews/` (Where [RENDER_ENGINEER] saves GIFs/PNGs for the User).
