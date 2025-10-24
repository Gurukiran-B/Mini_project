# Mini_project

## Overview

This project is a comprehensive logistics and routing application consisting of two main components:

### Backend (FastAPI)
- **Location**: `backend/`
- **Purpose**: Provides RESTful API endpoints for route optimization, traffic prediction, and delivery management
- **Key Features**:
  - Optimal route calculation using hybrid algorithms (Dijkstra + A*)
  - Traffic prediction based on historical data
  - Fleet status monitoring
  - Weather data integration
- **Tech Stack**: Python, FastAPI, Pydantic, NumPy, PyTorch, Uvicorn
- **Endpoints**:
  - `POST /route`: Calculate optimal route
  - `GET /traffic`: Get traffic predictions
  - `GET /fleet`: Get fleet status
  - `GET /weather`: Get weather data

### Frontend (Flutter)
- **Location**: `traffica/`
- **Purpose**: Mobile application for users and delivery personnel
- **Key Features**:
  - Interactive map with route visualization
  - Delivery search and tracking
  - Real-time location services
  - Fleet management dashboard
  - Traffic and weather predictions
- **Tech Stack**: Dart, Flutter, Flutter Map, Geolocator
- **Screens**:
  - Login/Dashboard
  - Map with routing
  - Delivery search
  - Fleet status
  - Notifications
  - Profile

## Setup Instructions

### Prerequisites
- Python 3.8+
- Flutter SDK
- Git

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate virtual environment:
   ```bash
   python -m venv .venv
   .venv\Scripts\activate  # On Windows
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the server:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

### Frontend Setup
1. Navigate to the traffica directory:
   ```bash
   cd traffica
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Testing
- Backend API can be tested using the provided `client.py` script
- Flutter app can be run on connected devices or emulators

## Project Structure
```
Mini_project/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── main.py         # Main FastAPI app
│   │   ├── models.py       # Pydantic models
│   │   └── algorithms.py   # Routing algorithms
│   ├── client.py           # Test client
│   └── requirements.txt    # Python dependencies
├── traffica/               # Flutter frontend
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── services/       # API and location services
│   │   ├── screens/        # UI screens
│   │   └── widgets/        # Reusable widgets
│   └── pubspec.yaml        # Flutter dependencies
├── README.md               # This file
└── TODO.md                 # Development tasks
```

## Contributing
1. Clone the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request

## License
This project is licensed under the MIT License.
