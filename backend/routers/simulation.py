import uuid
from fastapi import APIRouter, HTTPException
from models.simulation import SimulationRequest, SimulationResponse, StrategyResult, RaceEvent

router = APIRouter()

@router.post("/api/simulate", response_model=SimulationResponse)
async def run_simulation(request: SimulationRequest):
    """ (v4) 1.3. 시뮬레이션 요청 처리 및 결과 반환 (임시 데이터) """
    
    # 임시 'Actual' (실제) 결과
    actual_result = StrategyResult(
        name="Actual",
        totalTime=5430.123,
        pitLaps=[18, 35],
        lapTimes=[95.1, 95.2, 95.3] * 19 # (단순화된 랩 타임)
    )
    
    # 임시 'Optimal' (최적) 결과
    optimal_result = StrategyResult(
        name="Optimal",
        totalTime=5420.456,
        pitLaps=[20, 38],
        lapTimes=[94.8, 94.9, 95.0] * 19
    )

    # (v4) 신규: 임시 레이스 이벤트
    events = [
        RaceEvent(type="SC", startLap=5, endLap=8),
        RaceEvent(type="VSC", startLap=22, endLap=23),
    ]

    # 임시 응답 생성
    response = SimulationResponse(
        reportId=str(uuid.uuid4()),
        results={
            "actual": actual_result,
            "optimal": optimal_result,
            "scenarios": [optimal_result] # 요청받은 시나리오 대신 임시로 최적값을 반환
        },
        raceEvents=events
    )
    
    return response