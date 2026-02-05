
# 🏥 Heidi Intelligent Triage

**Turning noisy voicemails into structured, safe clinical workflows.**

A "Forward Deployed" engineering challenge submission for **Heidi Health**. This prototype demonstrates how AI can transform an overflow of unstructured patient voicemails into a prioritized, safe, and actionable dashboard for clinic staff.

<div align="center">

[![Live Demo](https://img.shields.io/badge/🚀_Live_Demo-Vercel-black?style=for-the-badge&logo=vercel)](https://heidi-triage-challange.vercel.app/)
[![Video Walkthrough](https://img.shields.io/badge/📹_Video_Pitch-Loom-blue?style=for-the-badge&logo=loom)](YOUR_VIDEO_LINK_HERE)

</div>

## ⚡ The Challenge
**Context:** "Harbour to Sunset GP" is drowning in missed calls. Receptionists start their day listening to 30+ unstructured voicemails, ranging from routine prescription requests to potential medical emergencies.
**The Problem:** The current workflow is First-In-First-Out (FIFO). A life-threatening emergency at 8:05 AM might be heard *after* a routine admin query at 8:00 AM.
**The Goal:** Build a system that extracts intent, prioritizes safety, and reduces manual triage time.

## 🛠 Tech Stack
* **Frontend:** Flutter Web (Minimalist, Responsive UI).
* **Data Pipeline:** Python (Synthetic Data Generation & NLP Simulation).
* **Architecture:** JSON-based data injection mimicking a REST API response.
* **Deployment:** Vercel.

## ✨ Key Features (Engineering Decisions)

### 1. Safety-First Sorting Algorithm
I implemented a **non-chronological** sorting logic.
* **Standard Inbox:** Sorts by `Time Received`.
* **Heidi Triage:** Sorts by `Urgency Score` (Critical → High → Medium → Low).
* *Result:* A patient mentioning "chest pain" will always appear at the top, even if they called seconds ago.

### 2. "Explainable AI" Trust Signals
Clinicians need to trust the "Black Box." I implemented **Evidence Tags** that highlight exactly *why* a voicemail was flagged.
* *UI:* Displays specific detected keywords (e.g., `"chest heaviness"`, `"sweating"`) next to the urgency badge.

### 3. Human-in-the-Loop Workflows
AI should draft, not decide.
* **SMS Previews:** The system generates a draft SMS based on intent (e.g., "Script Ready"), but forces a **Preview Dialog** so the admin can review/edit before sending.
* **Manual Escalation:** A "Break Glass" feature allows staff to manually escalate *any* call to a doctor, overriding the AI's classification.

---

## 🏗 Architecture & Data Flow

To demonstrate scalability, I avoided hardcoding the UI data. Instead, I built a Python pipeline (`generate_data.py`) to simulate a real backend.

1.  **Ingest:** Python script takes raw text templates.
2.  **Process:** Simulates an LLM pass to extract:
    * `Intent` (e.g., Prescription, Emergency)
    * `Urgency Score` (0-10)
    * `Keywords` (Evidence)
3.  **Output:** Generates a `mock_voicemails.json` payload.
4.  **Frontend:** Flutter app consumes this JSON asynchronously, modeling a real API call.


## 🚀 How to Run Locally

### Prerequisites
* Flutter SDK installed.
* Python 3.x (optional, for regenerating data).

### 1. Clone & Install
```bash
git clone [https://github.com/hasibullah1811/heidi-triage-challange.git](https://github.com/hasibullah1811/heidi-triage-challange.git)
cd heidi-triage-prototype
flutter pub get

```

### 2. Run the App

```bash
flutter run -d chrome

```

### 3. (Optional) Regenerate Synthetic Data

Want to test different scenarios? Run the generator script:

```bash
python generate_data.py
# This updates assets/mock_voicemails.json with new random patient data.
# Hot Restart the Flutter app to see changes.

```

---

## 📂 Project Structure

```
lib/
├── main.dart             # Core application logic & UI (Single file for portability)
assets/
├── mock_voicemails.json  # Generated data source
generate_data.py          # Python script for synthetic data generation

```

---

## 🛡 License

This project is a submission for the Heidi Health Entry Program.

```
