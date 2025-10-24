from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, List, Tuple
import math
import random
from datetime import datetime, timedelta

from .models import (
    GraphInput, RouteResult, HealthStatus,
    TrafficPrediction, CongestionPrediction, FleetStatus, VehicleStatus,
    OptimalRouteInput, WeatherData, DeliverySearchResult
)
from .algorithms import hybrid_route


app = FastAPI(title="Traffica Backend", version="1.0")

# CORS for Flutter/Android/Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthStatus)
async def health() -> HealthStatus:
    return HealthStatus(status="ok")


@app.get("/")
async def root():
    return {
        "message": "Traffica Backend is running. See /docs for API docs, /health for status.",
        "docs": "/docs",
        "openapi": "/openapi.json",
    }


def normalize_edges(payload: GraphInput) -> List[Tuple[str, str, float]]:
    edges: List[Tuple[str, str, float]] = []
    if payload.edges:
        edges = [(e.source, e.target, float(e.weight)) for e in payload.edges]
    elif payload.adjacency:
        for u, neighbors in payload.adjacency.items():
            for v, w in neighbors:
                edges.append((u, v, float(w)))

    # scale weights using provided factors
    scale = payload.traffic_factor * payload.weather_factor * payload.priority_factor
    if not math.isclose(scale, 1.0):
        edges = [(u, v, w * scale) for (u, v, w) in edges]
    return edges


@app.post("/route", response_model=RouteResult)
async def compute_route(payload: GraphInput) -> RouteResult:
    edges = normalize_edges(payload)
    path, cost, _ = hybrid_route(
        edges=edges,
        start=payload.start,
        end=payload.end,
        heuristic_map=payload.heuristic or {},
    )

    # Simple ETA estimation: assume 40 units per hour => 1.5 min per unit cost
    # This is a placeholder; integrate speed limits and real-time factors later.
    eta_minutes = float(cost * 1.5) if math.isfinite(cost) else float("inf")

    return RouteResult(path=path, total_cost=float(cost), eta_minutes=eta_minutes)


@app.get("/predict_traffic", response_model=TrafficPrediction)
async def predict_traffic(location: str = "Mumbai") -> TrafficPrediction:
    # Mock congestion predictions for the next 6 hours (Indian traffic patterns)
    now = datetime.now()
    predictions = []
    for i in range(6):
        timestamp = now + timedelta(hours=i)
        # Higher congestion during peak hours (8-10 AM, 5-8 PM)
        hour = timestamp.hour
        if 8 <= hour <= 10 or 17 <= hour <= 20:
            level = random.uniform(0.6, 0.95)  # High congestion during peak
        else:
            level = random.uniform(0.2, 0.7)  # Moderate to low otherwise

        if level < 0.4:
            desc = "Low traffic"
        elif level < 0.75:
            desc = "Moderate traffic"
        else:
            desc = "High congestion"
        predictions.append(CongestionPrediction(timestamp=timestamp, level=level, description=desc))
    return TrafficPrediction(location=location, predictions=predictions)


@app.get("/fleet_status", response_model=FleetStatus)
async def get_fleet_status() -> FleetStatus:
    # Mock fleet data with source and destination for deliveries (Indian locations)
    vehicles = [
        VehicleStatus(id="V001", status="en_route", current_location="Mumbai", eta_minutes=45.0, source="Mumbai Warehouse", destination="Delhi Customer"),
        VehicleStatus(id="V002", status="idle", current_location="Delhi", eta_minutes=None, source=None, destination=None),
        VehicleStatus(id="V003", status="maintenance", current_location="Bangalore", eta_minutes=None, source=None, destination=None),
        VehicleStatus(id="V004", status="en_route", current_location="Chennai", eta_minutes=90.0, source="Chennai Warehouse", destination="Kolkata Customer"),
    ]
    return FleetStatus(vehicles=vehicles)


@app.post("/optimal_route", response_model=RouteResult)
async def get_optimal_route(payload: OptimalRouteInput) -> RouteResult:
    # If coordinates provided, use real coordinate-based routing
    if payload.start_lat is not None and payload.start_lng is not None and payload.end_lat is not None and payload.end_lng is not None:
        # Simulate routing with coordinates (use predefined cities with closest match)
        cities = {
            "Mumbai": (19.0760, 72.8777),
            "Delhi": (28.7041, 77.1025),
            "Kolkata": (22.5726, 88.3639),
            "Chennai": (13.0827, 80.2707),
            "Bangalore": (12.9716, 77.5946),
        }
        # Find closest start and end cities
        start_city = min(cities.keys(), key=lambda c: (cities[c][0] - payload.start_lat)**2 + (cities[c][1] - payload.start_lng)**2)
        end_city = min(cities.keys(), key=lambda c: (cities[c][0] - payload.end_lat)**2 + (cities[c][1] - payload.end_lng)**2)
        payload.from_location = start_city
        payload.to_location = end_city

    # Mock graph for Indian cities demonstration
    edges = [
        ("Mumbai", "Delhi", 15.0),
        ("Delhi", "Kolkata", 12.0),
        ("Mumbai", "Kolkata", 20.0),
        ("Kolkata", "Chennai", 18.0),
        ("Delhi", "Chennai", 22.0),
        ("Mumbai", "Chennai", 14.0),
        ("Delhi", "Bangalore", 18.0),
        ("Bangalore", "Chennai", 4.0),
        ("Mumbai", "Bangalore", 10.0),
    ]
    # Make graph undirected by adding reverse edges
    edges += [(v, u, w) for u, v, w in edges]
    # Apply factors based on time/weather (Indian traffic patterns)
    traffic_factor = 1.3 if payload.time and payload.time.hour in [8, 9, 10, 17, 18, 19, 20] else 1.0  # Indian rush hours
    weather_factor = 1.4 if payload.weather_condition == "rain" else 1.0  # Rain affects traffic more in India
    scale = traffic_factor * weather_factor
    edges = [(u, v, w * scale) for u, v, w in edges]

    path, cost, _ = hybrid_route(
        edges=edges,
        start=payload.from_location,
        end=payload.to_location,
        heuristic_map={"Mumbai": 25, "Delhi": 20, "Kolkata": 15, "Chennai": 10, "Bangalore": 5},
    )
    eta_minutes = float(cost * 60) if math.isfinite(cost) else float("inf")  # Convert hours to minutes
    return RouteResult(path=path, total_cost=float(cost), eta_minutes=eta_minutes)


@app.get("/weather", response_model=WeatherData)
async def get_weather(location: str = "Mumbai") -> WeatherData:
    # Mock weather data for India
    conditions = ["clear", "rain", "cloudy", "sunny"]
    temp = random.uniform(25, 35)  # Typical Indian temperatures
    condition = random.choice(conditions)
    humidity = random.uniform(50, 90)  # Higher humidity in India
    wind_speed = random.uniform(5, 25)
    return WeatherData(
        location=location,
        temperature=temp,
        condition=condition,
        humidity=humidity,
        wind_speed=wind_speed,
    )


@app.get("/search_address", response_model=List[DeliverySearchResult])
async def search_address(query: str = "") -> List[DeliverySearchResult]:
    # Mock delivery search results for Indian cities
    mock_results = [
        DeliverySearchResult(
            address="Connaught Place, New Delhi",
            city="New Delhi",
            state="Delhi",
            pincode="110001",
            latitude=28.6139,
            longitude=77.2090,
            delivery_type="standard",
            delivery_fee=50.0,
            estimated_time_minutes=120,
        ),
        DeliverySearchResult(
            address="Marine Drive, Mumbai",
            city="Mumbai",
            state="Maharashtra",
            pincode="400020",
            latitude=18.9440,
            longitude=72.8236,
            delivery_type="express",
            delivery_fee=75.0,
            estimated_time_minutes=90,
        ),
        DeliverySearchResult(
            address="Banjara Hills, Hyderabad",
            city="Hyderabad",
            state="Telangana",
            pincode="500034",
            latitude=17.3850,
            longitude=78.4867,
            delivery_type="same_day",
            delivery_fee=100.0,
            estimated_time_minutes=60,
        ),
        DeliverySearchResult(
            address="MG Road, Bangalore",
            city="Bangalore",
            state="Karnataka",
            pincode="560001",
            latitude=12.9716,
            longitude=77.5946,
            delivery_type="standard",
            delivery_fee=60.0,
            estimated_time_minutes=100,
        ),
        DeliverySearchResult(
            address="T. Nagar, Chennai",
            city="Chennai",
            state="Tamil Nadu",
            pincode="600017",
            latitude=13.0827,
            longitude=80.2707,
            delivery_type="express",
            delivery_fee=70.0,
            estimated_time_minutes=80,
        ),
    ]

    if not query:
        return mock_results

    # Filter results based on query
    filtered_results = []
    search_term = query.lower()
    for result in mock_results:
        if (search_term in result.address.lower() or
            search_term in result.city.lower() or
            search_term in result.state.lower() or
            search_term in result.pincode):
            filtered_results.append(result)

    return filtered_results


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)


