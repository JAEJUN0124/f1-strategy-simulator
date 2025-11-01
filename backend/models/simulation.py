# backend/models/simulation.py

from pydantic import BaseModel
from typing import List, Optional

# --- 기본 데이터 구조 ---

class RaceInfo(BaseModel):
    """ (v4) 1.3. API: GET /api/races/{year} 응답 """
    raceId: str
    name: str
    round: int

class DriverInfo(BaseModel):
    """ (v4) 1.3. API: GET /api/drivers/{year}/{race_id} 응답 """
    driverId: str
    name: str # 예: "VER"

# --- 시뮬레이션 요청 모델 (Request) ---

class StintRequest(BaseModel):
    """ (v4) 1.3. 단일 스틴트 요청 """
    compound: str # "SOFT", "MEDIUM", "HARD"
    startLap: Optional[int] = None # 자동 최적화 시 None
    endLap: Optional[int] = None   # 자동 최적화 시 None

class Scenario(BaseModel):
    """ (v4) 1.3. 단일 전략 시나리오 요청 """
    name: str # 예: "S-M-H"
    stints: List[StintRequest]

class SimulationRequest(BaseModel):
    """ (v4) 1.3. API: POST /api/simulate 요청 본문 """
    year: int
    raceId: str
    driverId: str
    pitLossSeconds: float
    scenarios: List[Scenario]

# --- 시뮬레이션 응답 모델 (Response) ---

class StrategyResult(BaseModel):
    """ (v4) 1.3. 단일 전략(실제, 최적, 시나리오)의 결과 """
    name: str # "Actual", "Optimal", "S-M-H" 등
    totalTime: float # 초 (seconds)
    pitLaps: List[int]
    lapTimes: List[float]

class RaceEvent(BaseModel):
    """ (v4) 1.3. 레이스 이벤트 (SC, VSC, Red Flag) """
    type: str # 'SC', 'VSC', 'RedFlag'
    startLap: int
    endLap: int

class SimulationResponse(BaseModel):
    """ (v4) 1.3. API: POST /api/simulate 응답 본문 """
    reportId: str # UUID
    results: dict[str, StrategyResult | List[StrategyResult]] # {"actual": ..., "optimal": ..., "scenarios": [...]}
    raceEvents: List[RaceEvent] # (v4) 신규 추가 [cite: 389]