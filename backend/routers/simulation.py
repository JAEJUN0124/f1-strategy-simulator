# backend/routers/simulation.py

from fastapi import APIRouter
# 1. 이전 단계에서 만든 모델 임포트
from models.schemas import SimulationRequest, SimulationResponse, StrategyResult, Results
import uuid # reportId 생성을 위해 임포트

# APIRouter 인스턴스 생성
router = APIRouter()

# (v2).txt 1.3 - POST /api/simulate
@router.post("/api/simulate", response_model=SimulationResponse)
async def run_simulation(request: SimulationRequest):
    # Phase 2에서 실제 시뮬레이션 로직으로 대체됩니다.
    # 지금은 가짜(mock) 응답을 반환합니다.
    print(f"Received simulation request for: {request.driverId} in {request.year} {request.raceId}")

    # 가짜 StrategyResult 생성
    mock_strategy = StrategyResult(
        name="Mock Result",
        totalTime=5000.0,
        pitLaps=[15, 30],
        lapTimes=[1.5] * 50 # 50개의 랩타임 예시
    )

    # 가짜 Results 생성
    mock_results = Results(
        actual=mock_strategy,
        optimal=mock_strategy,
        scenarios=[mock_strategy]
    )
    
    # 최종 응답 반환
    return SimulationResponse(
        reportId=str(uuid.uuid4()), # 고유 ID 생성
        results=mock_results
    )