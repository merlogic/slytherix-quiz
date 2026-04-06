# Slytherix Quiz
**Where your brain grows as fast as your snake.**

Slytherix is a fast-paced trivia game built with **Flutter**. Unlike the classic Nokia snake, you can't just eat everything in sight. You have to think. Every "food" on the board is a letter representing an answer. Hit the right one to grow; hit the wrong one, and it's game over.

---

##  Gameplay Mechanics
* **The Grid:** A 16x16 arena where precision matters.
* **Timed Pressure:** You have **12 seconds** per question. No time for Googling!
* **The Legend:** Check the UI header. It maps the first letter of each answer to a tile on the board.
* **Difficulty Scaling:**
    * **0-40 Score:** General knowledge (Easy).
    * **40-100 Score:** Deep dives (Medium).
    * **100+ Score:** Expert level (Hard).

##  Tech Highlights
* **State Management:** Built using specialized `Timers` and `StatefulWidgets` for smooth 180ms game loops.
* **Adaptive Input:** Full support for **Keyboard (WASD/Arrows)** and a custom **On-screen D-Pad** for mobile users.
* **Haptics:** Integrated `HapticFeedback` for a tactile feel on every correct answer.

### 🎮 In-Game Action
| Easy Mode | Hard Mode |
| :---: | :---: |
| ![Easy Mode Gameplay](screenshots/screenshot_01.PNG) | ![Hard Mode Gameplay](screenshots/screenshot_02.PNG) |

---


