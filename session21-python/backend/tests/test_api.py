import os
os.environ["DATABASE_URL"] = "sqlite:///./test.db"

from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from app.main import app, est_1rm


@pytest.fixture(scope="module")
def client():
    # Fresh SQLite database for every test run; never the real Postgres database
    if os.path.exists("test.db"):
        os.remove("test.db")
    # The context manager runs the app lifespan, which creates the tables
    with TestClient(app) as c:
        yield c


def exercise(client, name, group="CHEST", equipment="BARBELL"):
    response = client.post("/api/exercises", json={"name": name, "muscle_group": group, "equipment": equipment})
    assert response.status_code == 201, response.text
    return response.json()


def workout(client, sets, title="Push Day", days_ago=0):
    performed_at = (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat()
    response = client.post("/api/workouts", json={"title": title, "performed_at": performed_at, "duration_min": 55, "sets": sets})
    assert response.status_code == 201, response.text
    return response.json()


# ---- service -----------------------------------------------------------------
def test_health(client):
    assert client.get("/health").json() == {"status": "UP"}

def test_root(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "LiftLog API"

def test_ready_checks_database(client):
    assert client.get("/ready").json() == {"status": "READY"}


# ---- exercises ---------------------------------------------------------------
def test_create_list_update_exercise(client):
    ex = exercise(client, "Test Bench Press")
    assert ex["muscle_group"] == "CHEST"
    assert ex["id"] in [e["id"] for e in client.get("/api/exercises").json()]
    updated = client.put(f"/api/exercises/{ex['id']}", json={"equipment": "DUMBBELL"}).json()
    assert updated["equipment"] == "DUMBBELL" and updated["name"] == "Test Bench Press"

def test_exercise_validation_and_duplicates(client):
    assert client.post("/api/exercises", json={"name": "", "muscle_group": "CHEST"}).status_code == 422
    assert client.post("/api/exercises", json={"name": "Neck Curl", "muscle_group": "NECK"}).status_code == 422
    exercise(client, "Unique Squat", "QUADS")
    assert client.post("/api/exercises", json={"name": "Unique Squat", "muscle_group": "QUADS"}).status_code == 409


# ---- workouts ----------------------------------------------------------------
def test_log_workout_with_sets(client):
    bench = exercise(client, "Workout Bench", "CHEST")
    w = workout(client, [
        {"exercise_id": bench["id"], "reps": 5, "weight_kg": 100},
        {"exercise_id": bench["id"], "reps": 8, "weight_kg": 90, "rpe": 8.5},
    ])
    assert w["total_sets"] == 2
    assert w["volume_kg"] == 5 * 100 + 8 * 90
    assert [s["position"] for s in w["sets"]] == [1, 2]
    assert w["sets"][0]["exercise_name"] == "Workout Bench"
    assert client.get(f"/api/workouts/{w['id']}").json()["title"] == "Push Day"

def test_update_workout_replaces_sets(client):
    row = exercise(client, "Update Row", "BACK")
    w = workout(client, [{"exercise_id": row["id"], "reps": 10, "weight_kg": 60}], title="Pull Day")
    updated = client.put(f"/api/workouts/{w['id']}", json={"notes": "felt strong", "sets": [
        {"exercise_id": row["id"], "reps": 8, "weight_kg": 70},
        {"exercise_id": row["id"], "reps": 8, "weight_kg": 70},
    ]}).json()
    assert updated["notes"] == "felt strong" and updated["title"] == "Pull Day"
    assert updated["total_sets"] == 2 and updated["volume_kg"] == 2 * 8 * 70

def test_delete_workout(client):
    curl = exercise(client, "Delete Curl", "BICEPS", "DUMBBELL")
    w = workout(client, [{"exercise_id": curl["id"], "reps": 12, "weight_kg": 15}], title="Arms")
    assert client.delete(f"/api/workouts/{w['id']}").status_code == 204
    assert client.get(f"/api/workouts/{w['id']}").status_code == 404

def test_workout_validation(client):
    assert client.post("/api/workouts", json={"title": "Empty", "sets": []}).status_code == 422
    assert client.post("/api/workouts", json={"title": "Bad reps", "sets": [{"exercise_id": 1, "reps": 0}]}).status_code == 422
    unknown = client.post("/api/workouts", json={"title": "Ghost", "sets": [{"exercise_id": 999999, "reps": 5, "weight_kg": 50}]})
    assert unknown.status_code == 422 and "999999" in unknown.json()["detail"]

def test_cannot_delete_exercise_used_in_a_workout(client):
    dl = exercise(client, "Guarded Deadlift", "BACK")
    workout(client, [{"exercise_id": dl["id"], "reps": 3, "weight_kg": 180}], title="Deadlift Day")
    assert client.delete(f"/api/exercises/{dl['id']}").status_code == 409
    spare = exercise(client, "Spare Exercise", "CORE", "BODYWEIGHT")
    assert client.delete(f"/api/exercises/{spare['id']}").status_code == 204

def test_missing_resources_return_404(client):
    assert client.get("/api/workouts/999999").status_code == 404
    assert client.put("/api/workouts/999999", json={"title": "x"}).status_code == 404
    assert client.delete("/api/workouts/999999").status_code == 404
    assert client.put("/api/exercises/999999", json={"name": "x"}).status_code == 404
    assert client.get("/api/exercises/999999/progress").status_code == 404


# ---- analytics ---------------------------------------------------------------
def test_epley_one_rep_max():
    assert est_1rm(100, 1) == 100
    assert est_1rm(100, 5) == 116.7
    assert est_1rm(60, 10) == 80.0

def test_personal_records_and_progress(client):
    squat = exercise(client, "PR Squat", "QUADS")
    workout(client, [{"exercise_id": squat["id"], "reps": 5, "weight_kg": 120}], title="Legs 1", days_ago=14)
    workout(client, [{"exercise_id": squat["id"], "reps": 3, "weight_kg": 140}], title="Legs 2", days_ago=2)
    pr = next(r for r in client.get("/api/stats").json()["personal_records"] if r["exercise_id"] == squat["id"])
    assert pr["best_weight_kg"] == 140 and pr["best_set"] == "140 kg x 3" and pr["est_1rm_kg"] == 154.0
    progress = client.get(f"/api/exercises/{squat['id']}/progress").json()
    assert [p["top_weight_kg"] for p in progress] == [120, 140]  # oldest first
    assert progress[1]["best_est_1rm_kg"] > progress[0]["best_est_1rm_kg"]

def test_weekly_and_muscle_group_stats(client):
    before = client.get("/api/stats").json()
    calf = exercise(client, "Stats Calf Raise", "CALVES", "MACHINE")
    workout(client, [{"exercise_id": calf["id"], "reps": 15, "weight_kg": 80}], title="Calves")
    workout(client, [{"exercise_id": calf["id"], "reps": 15, "weight_kg": 80}], title="Old calves", days_ago=20)
    after = client.get("/api/stats").json()
    assert after["total_workouts"] == before["total_workouts"] + 2
    assert after["workouts_last_7_days"] == before["workouts_last_7_days"] + 1
    assert after["volume_last_7_days_kg"] == before["volume_last_7_days_kg"] + 15 * 80
    assert after["volume_by_muscle_group_30d"]["CALVES"] == before["volume_by_muscle_group_30d"].get("CALVES", 0) + 2 * 15 * 80
