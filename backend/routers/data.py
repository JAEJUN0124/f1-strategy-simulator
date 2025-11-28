from fastapi import APIRouter, HTTPException
from typing import List
from models.simulation import RaceInfo, DriverInfo
# --- services 임포트 ---
from services import data_service 

router = APIRouter()

@router.get("/api/races/{year}", response_model=List[RaceInfo])
async def get_races(year: int):
    """
    [레이스 목록 조회] GET /api/races/{year}
    특정 연도(예: 2024)의 모든 F1 그랑프리 일정과 라운드 정보를 반환합니다.
    프론트엔드의 '경기 데이터 선택' 드롭다운을 구성하는 데 사용됩니다.
    """
    
    races = data_service.get_races_for_year(year)
    
    if not races:
        raise HTTPException(status_code=404, detail="Data not found for the selected year")
    return races

@router.get("/api/drivers/{year}/{race_id}", response_model=List[DriverInfo])
async def get_drivers(year: int, race_id: str):
    """
    [드라이버 목록 조회] GET /api/drivers/{year}/{race_id}
    선택한 연도와 레이스(라운드)에 참가한 드라이버들의 목록을 반환합니다.
    프론트엔드의 '드라이버 선택' 드롭다운을 구성하는 데 사용됩니다.
    """
    
    drivers = data_service.get_drivers_for_race(year, race_id)
    
    if not drivers:
        raise HTTPException(status_code=404, detail="Data not found for the selected race")
    return drivers