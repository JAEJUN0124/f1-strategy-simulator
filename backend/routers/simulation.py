import logging
from fastapi import APIRouter, HTTPException
from models.simulation import SimulationRequest, SimulationResponse
from services import simulation_service

router = APIRouter()


@router.post("/api/simulate", response_model=SimulationResponse)
async def run_simulation(request: SimulationRequest):
    """ simulation_service를 호출하여 실제 시뮬레이션 결과 반환 """

    try:
        # 메인 서비스 함수 호출
        response = simulation_service.run_simulation(request)
        return response

    except HTTPException as e:
        # 서비스에서 발생한 HTTP 예외는 그대로 전달
        raise e
    except Exception as e:
        # 그 외 서버 오류
        logging.error(f"시뮬레이션 중 알 수 없는 오류 발생: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")