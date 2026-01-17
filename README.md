# Keploy Ruby + MongoDB Quickstart

A simple CRUD Todo app built with Ruby using Sinatra and MongoDB. I've hooked it up with Keploy so you can record real API calls and replay them as tests - no need to write test cases by hand.
---

## Features

- Full create, read, update, delete operations for todos
- Ruby with Sinatra for the backend
- MongoDB to store the data
- Works locally without containers
- Also runs with Docker Compose (app + MongoDB together)
- Keploy records and replays everything end-to-end
- Handles noisy dynamic fields like MongoDB's _id using filters
- Really beginner-friendly with clear steps and screenshots

---

## API Endpoints

| Method | Endpoint | What it does | Example body (if needed) |
|------|---------|-------------|--------------------------|
| GET | `/health` | Checks if server is running | - |
| POST | `/todos` | Creates a new todo | `{"title": "Buy milk"}` |
| GET | `/todos` | Gets all todos | - |
| GET | `/todos/:id` | Gets one todo by id | - |
| PUT | `/todos/:id` | Updates a todo | `{"title": "New title", "done": true}` |
| DELETE | `/todos/:id` | Deletes a todo | - |

Everything returns JSON.

---

## Tech Stack

- Ruby 3.2 or newer
- Sinatra (super lightweight framework)
- MongoDB
- Docker and Docker Compose
- Keploy v3.2.2
- Puma server (comes with Sinatra)

---

## 1. Running Locally (No Docker - Great for Beginners)

### What you need first

- Ubuntu or WSL on Windows (Keploy only works on Linux kernel)
- Ruby 3.2+ installed (check with `ruby -v`)
- MongoDB installed and running
- Git

### Steps

**Start MongoDB (this is the most important part)**

```bash
sudo systemctl start mongod
sudo systemctl enable mongod    # makes it start automatically on boot
sudo systemctl status mongod    # should show "active (running)" in green
```

If MongoDB isn't installed yet:

```bash
sudo apt update
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org-8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
```

**Install Ruby gems**

```bash
bundle install
```

**Start the app**

```bash
bundle exec ruby app.rb
```

You should see something like:

```
== Sinatra (v4.2.1) has taken the stage on 4567 ...
Puma starting in single mode...
* Listening on http://0.0.0.0:4567
```

**Test it (open a new terminal, don't stop the app)**

```bash
curl http://localhost:4567/health
```

You should get:

```json
{"status":"ok"}
```

If not, check MongoDB status, look at app logs for errors, or free port 4567 with:

```bash
sudo fuser -k 4567/tcp
```

---

## 2. Running with Docker Compose (App + MongoDB in containers)

### What you need

Docker Desktop running (on Windows make sure WSL is enabled in Docker settings)

### Steps

**Build and start everything**

```bash
docker compose up --build
```

Wait a bit. Look for:

- MongoDB saying "waiting for connections on port 27017"
- App saying "Listening on http://0.0.0.0:4567"

**Test it (new terminal)**

```bash
curl http://localhost:4567/health
```

Should return:

```json
{"status":"ok"}
```

To stop: Ctrl+C or in another terminal:

```bash
docker compose down
```

---

## 3. Installing Keploy

Keploy only works on Linux/WSL because of eBPF.

```bash
curl --silent -O -L https://keploy.io/install.sh && source install.sh
```

Check it worked:

```bash
keploy version
```

Should show v3.2.2 or similar.

---

## 4. Recording Tests with Keploy

```bash
keploy record -c "docker compose up --build" \
  --container-name ruby-app \
  --buildDelay 45
```

Keploy will start the containers and wait for the app to be ready.

In a second terminal, make some requests:

```bash
curl http://localhost:4567/health

curl -X POST http://localhost:4567/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Keploy with Ruby"}'

curl http://localhost:4567/todos
```

Do a few more POSTs, GETs, etc. to get good coverage.

Go back to the Keploy terminal and press Ctrl+C to stop recording.

**Check that tests were saved**

```bash
ls keploy/
ls keploy/test-set-0/
```

You should see some yaml files.

<img width="1115" height="153" alt="image" src="https://github.com/user-attachments/assets/fe8119a1-5498-41e6-8ae4-7e396c2bda96" />


---

## 5. Running Tests (Replay Mode)

```bash
keploy test -c "docker compose up" \
  --container-name ruby-app \
  --delay 15 \
  --buildDelay 45
```
<img width="1716" height="772" alt="image" src="https://github.com/user-attachments/assets/b40777c8-69f4-44dc-8d7b-89754774bd42" />
<img width="1573" height="972" alt="image" src="https://github.com/user-attachments/assets/5f2dace6-9c82-48c7-8056-511859129e28" />

First time you'll probably see around 14 tests, 10 pass, 4 fail because MongoDB creates new _id values each time.

That's totally normal.

---

## 6. Fixing the Failing Tests (Handling Dynamic IDs)

MongoDB generates fresh _id fields every run, so the replay sees different values.

I've added a keploy.yml file that tells Keploy to ignore those changing parts.

Here's what's in keploy.yml:

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

Run the test command again - now almost everything should pass.
<img width="1920" height="840" alt="image" src="https://github.com/user-attachments/assets/3de86856-3370-4d65-8887-6416627ed253" />

---

## Project Structure

```
.
├── app.rb               # main API code and MongoDB connection
├── Gemfile              # list of Ruby dependencies
├── Gemfile.lock
├── config.ru            # tells Puma how to run the app
├── Dockerfile
├── docker-compose.yml   # runs app and mongo together
├── keploy.yml           # noise config to ignore changing IDs
├── README.md            # this file
├── assets/              # screenshots go here
│   ├── record.png
│   ├── folder.png
│   └── test-final.png
└── keploy/              # created automatically by Keploy
    └── test-set-0/      # yaml test files
```

---

## Summary

You now have a working Ruby + Sinatra + MongoDB todo app that runs both locally and in Docker. Keploy can record real API traffic and replay it as tests, and we've handled the tricky dynamic MongoDB IDs with a simple noise filter.

Everything is documented with clear steps and screenshots - perfect for anyone starting out.

---

Created by Preksha  
Tested on WSL, Ubuntu, Docker, and Keploy v3.2.2  
Created for Keploy GitHub Issue #3521

