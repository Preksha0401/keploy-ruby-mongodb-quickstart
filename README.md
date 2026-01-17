# Keploy Ruby + MongoDB Quickstart

A simple CRUD Todo API built using Ruby (Sinatra) and MongoDB, integrated with Keploy for API testing using record and replay. Keploy automatically captures your real API calls (no code changes needed) and replays them to verify behavior - perfect for beginners who want powerful testing without writing test cases manually.

This quickstart is created for Keploy GitHub Issue #3521 - adding Ruby support.

---

## Features

- Full CRUD Todo REST API
- Ruby + Sinatra backend
- MongoDB as database
- Local setup (no Docker)
- Docker Compose (app + MongoDB)
- Keploy record and replay working end-to-end
- Noise filter for dynamic MongoDB `_id` fields
- Super beginner-friendly step-by-step guide
- Screenshots for every important step

---

## API Endpoints

| Method | Endpoint | Description | Example Request Body (if any) |
|----------|------------------|--------------------------------------------------|-----------------------------------------------|
| GET | `/health` | Check if server is alive | - |
| POST | `/todos` | Create a new todo | `{"title": "Buy groceries"}` |
| GET | `/todos` | Get list of all todos | - |
| GET | `/todos/:id` | Get single todo by ID | - |
| PUT | `/todos/:id` | Update todo title or done status | `{"title": "New title", "done": true}` |
| DELETE | `/todos/:id` | Delete a todo by ID | - |

All responses are in JSON format.

---

## Tech Stack

- **Ruby** 3.2+
- **Sinatra** (lightweight web framework)
- **MongoDB** (NoSQL database)
- **Docker & Docker Compose** (containerization)
- **Keploy** v3.2.2 (API testing tool)
- **Puma** (web server used by Sinatra)

---

## 1. Local Setup (Without Docker) - Super Easy for Beginners

### Prerequisites

- Ubuntu / WSL on Windows (Keploy needs Linux kernel)
- Ruby installed (`ruby -v` should show 3.2+)
- MongoDB installed and running
- Git installed

### Step-by-step

**1. Start MongoDB** (most important!)

```bash
sudo systemctl start mongod
sudo systemctl enable mongod # auto-start on boot
sudo systemctl status mongod # should say "active (running)"
```

If not installed yet:

```bash
sudo apt update
sudo apt install -y mongodb-org
```

**2. Install Ruby dependencies**

```bash
bundle install
```

**3. Run the application**

```bash
bundle exec ruby app.rb
```

You will see:

```
== Sinatra (v4.2.1) has taken the stage on 4567
...
Puma starting in single mode...
* Listening on http://0.0.0.0:4567
```

**4. Test it works**

Open new terminal:

```bash
curl http://localhost:4567/health
```

Expected:

```json
{"status":"ok"}
```

If you get error, check Mongo is running, app is not crashed, port 4567 free.

---

## 2. Docker Compose Setup (App + MongoDB in Containers)

**Build and start everything**

```bash
docker compose up --build
```

Wait 30-60 seconds. Look for:

- MongoDB: "waiting for connections on port 27017"
- Ruby app: "Listening on http://0.0.0.0:4567"

**Test from host**

New terminal:

```bash
curl http://localhost:4567/health # should return {"status":"ok"}
```

**Stop containers**

Ctrl + C in the docker terminal OR run in another terminal:

```bash
docker compose down
```

---

## 3. Install Keploy (Only on Linux/WSL)

Keploy uses eBPF - works only on Linux kernel (not native Windows/Mac).

Run:

```bash
curl --silent -O -L https://keploy.io/install.sh && source install.sh
```

Check:

```bash
keploy version # Should show v3.2.2 or similar
```

If fails, search error + "Keploy install Ubuntu" or ask in chat.

---

## 4. Keploy Record Mode - Capture Real Traffic

Start recording:

```bash
keploy record -c "docker compose up --build" \
  --container-name ruby-app \
  --buildDelay 45
```

What happens:

- Keploy starts its agent
- Runs your Docker Compose automatically
- Waits for app to start (you'll see Puma logs)

**In a second terminal (very important):**

Generate traffic (do 5-10 requests):

```bash
curl http://localhost:4567/health

curl -X POST http://localhost:4567/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Keploy with MongoDB"}'

curl http://localhost:4567/todos

# Repeat POST and GET a few times
```

**Stop recording:**

Go back to Keploy terminal and press Ctrl + C

**Success check:**

```bash
ls keploy/ # Should show test-set-0/ or similar + .yaml files
```

![Keploy Record Output](assets/record.png)

![Keploy Generated Folder](assets/folder.png)

---

## 5. Keploy Replay / Test Mode - Verify Everything

Run tests:

```bash
keploy test -c "docker compose up" \
  --container-name ruby-app \
  --delay 15 \
  --buildDelay 45
```

What you will see:

- Docker starts again
- Keploy replays your captured requests
- Compares responses (status, headers, body)

Your results (first run):

- Total tests: 14
- Passed: 10
- Failed: 4 (due to dynamic MongoDB _id fields - normal!)

![Keploy Replay Output](assets/test-output.png)

---

## 6. Fixing Failed Tests (Dynamic MongoDB IDs)

MongoDB creates new unique `_id` every time you insert. So replay gets different ID and fails.

**Solution: Noise Filter in keploy.yml**

We already added this file:

```yaml
version: api.keploy.io/v1beta1
kind: Config
metadata:
  name: keploy-ruby-mongodb
noise:
  - path: "/todos"
    method: "POST"
    ignore:
      - body.id
  - path: "/todos"
    method: "GET"
    ignore:
      - body.todos[*].id
  - path: "/todos/*"
    method: "GET"
    ignore:
      - body.id
```

This tells Keploy: "Don't compare the id fields - they change every run!"

Re-run test after adding this and expect near 100% pass.

![Keploy Replay Output (After Noise Filter)](assets/test-final.png)

---

## Project Structure (Explained for Beginners)

```
.
├── app.rb                 # All API logic + MongoDB connection
├── Gemfile                # Ruby gems list
├── config.ru              # Tells Puma how to run Sinatra
├── Dockerfile             # Builds Ruby app container
├── docker-compose.yml     # Runs app + MongoDB together
├── keploy.yml             # Ignores dynamic IDs in tests
├── README.md              # This file - you're reading it!
├── assets/                # Put your screenshots here
│   ├── record.png         # Keploy record terminal screenshot
│   ├── folder.png         # ls keploy/ output screenshot
│   └── test-final.png     # Keploy test/replay result screenshot
└── keploy/                # Auto-created by Keploy
    └── test-set-0/        # Contains .yaml files for each test case
```

**How to take screenshots:**

- Ubuntu: Press PrtSc, select area, save in assets/
- Windows: Snipping Tool (Win + Shift + S), save as PNG

---

## Summary for Beginners

✅ Built CRUD Todo API with Ruby + Sinatra + MongoDB  
✅ Ran it locally and in Docker  
✅ Installed Keploy  
✅ Recorded 14 real API calls  
✅ Replayed them - 10/14 passed (fixed dynamic IDs with noise filter)  
✅ Documented everything step-by-step

You now have a complete, production-like quickstart ready to share!

---

Made with ❤️ by Preksha in Mumbai  
Tested on WSL + Ubuntu + Docker + Keploy v3.2.2  
For Keploy Issue #3521
