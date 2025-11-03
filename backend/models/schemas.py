from pydantic import BaseModel
from typing import List, Optional

# --- API 응답 모델 ---

# GET /api/races/{year} 응답용
class RaceInfo(BaseModel):
    raceId: str  # [cite: 182]
    name: str    # [cite: 182]
    round: int   # [cite: 182]

# GET /api/drivers/{year}/{race_id} 응답용
class DriverInfo(BaseModel):
    driverId: str # [cite: 183]
    name: str     # [cite: 183]


# --- 시뮬레이션 요청 모델 (POST /api/simulate) ---

# - StintRequest 모델
class StintRequest(BaseModel):
    compound: str                # [cite: 180]
    startLap: Optional[int] = None # [cite: 180]
    endLap: Optional[int] = None   # [cite: 180]

# - Scenario 모델
class Scenario(BaseModel):
    name: str            # [cite: 180]
    stints: List[StintRequest] # [cite: 180]

# - SimulationRequest 모델
class SimulationRequest(BaseModel):
    year: int              # 
    raceId: str            # 
    driverId: str          # 
    pitLossSeconds: float  # 
    scenarios: List[Scenario] # 


# --- 시뮬레이션 응답 모델 (POST /api/simulate) ---

# - StrategyResult 모델
class StrategyResult(BaseModel):
    name: str           # [cite: 182]
    totalTime: float    # [cite: 182]
    pitLaps: List[int]  # [cite: 182]
    lapTimes: List[float] # [cite: 182]

# - Results 모델
class Results(BaseModel):
    actual: StrategyResult        # [cite: 181]
    optimal: StrategyResult       # [cite: 181]
    scenarios: List[StrategyResult] # [cite: 181]

# - SimulationResponse 모델
class SimulationResponse(BaseModel):
    reportId: str # [cite: 181]
    results: Results  # [cite: 181]