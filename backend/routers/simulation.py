import logging
from fastapi import APIRouter, HTTPException
from models.simulation import SimulationRequest, SimulationResponse
from services import simulation_service

router = APIRouter()


@router.post("/api/simulate", response_model=SimulationResponse)
async def run_simulation(request: SimulationRequest):
    """
    [시뮬레이션 실행] POST /api/simulate
    프론트엔드에서 보낸 설정값(연도, 레이스, 드라이버, 타이어 전략 등)을 받아 시뮬레이션을 수행합니다.
    
    반환값:
    - actual: 실제 해당 경기에서 드라이버가 수행한 기록
    - optimal: AI가 계산한 해당 경기의 최적 전략
    - scenarios: 사용자가 직접 구성한 커스텀 전략들의 예측 결과
    - raceEvents: 경기 중 발생한 SC(세이프티카) 등의 이벤트 정보
    """

    try:
        # --- (정상 실행) ---
        # 핵심 기능인 시뮬레이션을 실행하고 결과를 반환하려 시도
        response = simulation_service.run_simulation(request)
        return response

    except HTTPException as e:
        # --- (예상된 오류 처리) ---
        # 서비스가 의도적으로 발생시킨 HTTP 오류(예: 4xx)는 그대로 클라이언트에 전달
        raise e
    except Exception as e:
        # --- (서버 다운 방지) ---
        # 위에서 잡지 못한 모든 예상치 못한 오류(버그 등)를 처리

        # 1. 오류 내용을 서버 로그에 기록 (개발자 디버깅용)
        logging.error(f"시뮬레이션 중 알 수 없는 오류 발생: {e}", exc_info=True)

        # 2. "서버 내부 오류(500)"가 발생했음을 클라이언트에게 알림
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")