# 🏛️ NAGPUR SETU (नागपूर सेतू) — MASTER PROJECT CONTEXT & ARCHITECTURE

> **Permanent Memory Bank & Engineering Specification**  
> *Last Updated: August 2026*  
> *Purpose: Preserves full project state, credentials, architectural decisions, database schemas, and codebase patterns across all sessions.*

---

## 📌 1. Project Overview & Mission

**Nagpur Setu** is an enterprise-grade civic grievance redressal and municipal dispatch platform built specifically for the **Nagpur Municipal Corporation (NMC) / नागपूर महानगरपालिका**.

### Dual-Platform Ecosystem:
1. **📱 Flutter Mobile App (`/home/endertrailer/nagpur_setu_flutter`):**
   * Target: Citizens of Nagpur.
   * Key Utility: High-speed GPS-locked grievance filing, automatic AI category classification, 50m spatial deduplication/corroboration, and 1-time persistent login.
   * Git Remote: `git@github.com:endertrailer/nagpur_setu.git` (Branch: `main`).

2. **💻 React Web Command Center (`/home/endertrailer/nagpur-setu`):**
   * Target: NMC Municipal Officers, Field Engineers, Dispatchers, and Municipal Commissioner.
   * Key Utility: Realtime triage, squad deployment, mandatory After-Photo resolution audit, and CSV export.
   * URL: `http://localhost:5173/`.

---

## 🔐 2. Backend & Live Supabase Infrastructure

* **Project URL:** `https://zgbqawweziyegdsripvy.supabase.co`
* **Publishable Anon Key:** `sb_publishable_2Jwqwtge8xEjFy4c8cD81Q_ozk3_Jo2`
* **Storage Buckets:**
  * `complaint-evidence`: Public bucket for citizen photo proofs.
  * `resolution-proofs`: Public bucket for municipal officer after-photos.

### 🗄️ PostgreSQL Database Schema (`public.complaints`)

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE complaint_status AS ENUM ('open', 'in_progress', 'resolved');

CREATE TABLE public.complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_ref VARCHAR(20) UNIQUE NOT NULL,       -- e.g. NGP-8542
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,                   -- Pothole, Garbage, Water Leak, Streetlight, Other
    description TEXT,
    photo_url TEXT NOT NULL,
    evidence_photos TEXT[] DEFAULT '{}',             -- Multi-citizen photo evidence array
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    geom GEOMETRY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)) STORED,
    landmark VARCHAR(255) NOT NULL,
    ward VARCHAR(100) DEFAULT 'Nagpur City',
    status complaint_status DEFAULT 'open' NOT NULL,
    report_count INTEGER DEFAULT 1 NOT NULL,         -- Corroboration score
    reporter_phone_hashes TEXT[] DEFAULT '{}' NOT NULL, -- SHA-256 phone hashes (privacy preserved)
    assigned_to VARCHAR(150),                        -- Field squad or officer name
    resolved_photo_url TEXT,                         -- Mandatory after-photo proof
    resolution_notes TEXT,                           -- Verification remarks
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Spatial & Filter Indexes
CREATE INDEX idx_complaints_geom ON public.complaints USING GIST (geom);
CREATE INDEX idx_complaints_status ON public.complaints (status);
CREATE INDEX idx_complaints_created_at ON public.complaints (created_at DESC);

-- Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
```

---

## 📱 3. Flutter Mobile Application Deep-Dive

### 🛡️ 3-Tier Security Gates (`lib/main.dart` -> `AppRootSecurityGate`)
On startup, the app enforces three non-bypassable gates in order:
1. **🌐 Continuous Internet Gate (`NetworkGateScreen`):**
   * Uses `connectivity_plus` real-time stream + `NetworkService.hasInternetConnection()`.
   * If internet drops **at any point mid-session**, the app immediately blocks all features until reconnected.
2. **📍 Hardware GPS Location Gate (`LocationPermissionGateScreen`):**
   * Enforces hardware GPS permission within the strict Nagpur bounding box (`Lat: 21.0400–21.2600, Lng: 78.9800–79.2200`).
3. **📲 One-Time Citizen Login Gate (`CitizenLoginGateScreen`):**
   * Prompts 10-digit Indian phone number (`+91`) and sends live OTP.
   * Persistent session stored via `SharedPreferences` (`nagpur_citizen_phone`).
   * Once authenticated, future launches skip login straight to the main map.

### ⚙️ Core Engines & Algorithms:
* **50-Meter Deduplication & Corroboration Merge:**
  * When a report is filed within 50m of an existing unresolved grievance in the same category, `ComplaintsRepository.submitOrMergeReport` merges it: boosts `reportCount += 1`, appends evidence photo, and registers the phone hash without creating clutter.
* **7-Day Tamper-Proof Rate Limiting:**
  * `NetworkService.getTrustedNetworkTime()` inspects the HTTP `Date` server header (prevents users from rolling back device clock).
  * Rejects duplicate reports from the same phone hash within 50m within 7 days.
* **100% Automated GPS Geo-tagging:**
  * No manual address input. The app uses live GPS coordinates to auto-match the nearest locality from 60+ curated Nagpur landmarks (`GeoUtils.findClosestNagpurLandmark`).

---

## 💻 4. React Web Command Center Deep-Dive

### 👮‍♂️ Official NMC Officer Authentication (`AdminLoginModal.jsx`)
* Route protected: Accessing `Command Desk` prompts official NMC credentials.
* **Officer Presets:**
  * **PWD Roads:** `pwd.officer@nmcnagpur.gov.in` (*Er. Rajesh Sharma, Badge: NMC-PWD-842*)
  * **OCW Water:** `ocw.water@nmcnagpur.gov.in` (*Mrs. Sunita Deshmukh, Badge: OCW-ENG-109*)
  * **Sanitation / SWM:** `sanitation@nmcnagpur.gov.in` (*Mr. Amit Gadkari, Badge: NMC-SWM-301*)
  * **Municipal Commissioner:** `commissioner@nmcnagpur.gov.in` (*Dr. Vipin Itankar, IAS, Badge: NMC-IAS-001*)
* Session stored in `localStorage['nmc_authenticated_officer']`.

### 🛠️ Key Web Features:
* **Interactive Live Map (`MapView.jsx`):** Leaflet CartoDB Voyager canvas strictly bounded to Nagpur with urgent pulse badges.
* **Triage & Squad Dispatch (`AdminDashboard.jsx`):** Assigns field squads (`NMC Bituminous Pothole Squad`, `OCW Pipeline Repair Unit`, `AG Enviro Sanitation Fleet`).
* **Mandatory After-Photo Public Audit (`ResolveModal.jsx`):** Officers cannot resolve an issue without uploading photographic proof of completed repair.
* **One-Click Audit CSV Export:** Complete spreadsheet download with GPS coordinates, SLA timelines, and squad logs.

---

## 🔑 5. Test Credentials & Demo Data

* **Test Citizen Phone:** `+917385704873`
* **Test Citizen OTP Passcode:** `558900`
* **Test Officer Password:** `Password@123`
* **Zero Mile Stone (Nagpur Center):** `(21.1458, 79.0882)`

---

## 📂 6. Repository Layout & File Mapping

```
/home/endertrailer/
├── nagpur_setu_flutter/               # Citizen Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart                  # Security gate & continuous connectivity stream
│   │   ├── screens/
│   │   │   ├── map_screen.dart        # FlutterMap with custom pulsing pins
│   │   │   ├── issue_feed_screen.dart # Public grievances feed & search
│   │   │   ├── report_screen.dart     # 3-step reporting wizard (camera/gallery + AI vision)
│   │   │   ├── citizen_login_gate_screen.dart # Mandatory startup login
│   │   │   ├── network_gate_screen.dart       # Offline blocker screen
│   │   │   └── location_permission_gate_screen.dart # GPS permission gate
│   │   ├── services/
│   │   │   ├── supabase_service.dart  # Supabase client & Phone OTP auth
│   │   │   ├── complaints_repository.dart # State manager, 50m merge & 7-day rate limit
│   │   │   ├── location_service.dart  # Hardware GPS acquisition
│   │   │   ├── network_service.dart   # Tamper-proof HTTP server time
│   │   │   └── vision_classifier_service.dart # On-device civic heuristic & API classifier
│   │   └── utils/
│   │       └── geo_utils.dart         # Haversine distance, Nagpur bounding box, landmarks
│   └── pubspec.yaml                   # Dependencies (flutter_map, geolocator, supabase_flutter, connectivity_plus)
│
└── nagpur-setu/                       # NMC Municipal Command Center (React + Vite)
    ├── src/
    │   ├── App.jsx                    # Root tab routing & state
    │   ├── components/
    │   │   ├── Navbar.jsx             # Official header & officer login trigger
    │   │   ├── MapView.jsx            # Leaflet map
    │   │   ├── IssueFeed.jsx          # Public grievance feed
    │   │   ├── AdminDashboard.jsx     # Command desk with squad dispatch & KPIs
    │   │   ├── AdminLoginModal.jsx    # Officer authentication & preset switch
    │   │   ├── ResolveModal.jsx       # Mandatory after-photo resolution modal
    │   │   └── IssueDetailModal.jsx   # Timeline & evidence inspector
    │   └── services/
    │       ├── supabase.js            # Web Supabase client
    │       └── db.js                  # Database sync, resolve logic & CSV export
    └── package.json                   # Dependencies (react, leaflet, lucide-react, @supabase/supabase-js)
```
