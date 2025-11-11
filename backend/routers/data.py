from fastapi import APIRouter, HTTPException
from typing import List
from models.simulation import RaceInfo, DriverInfo
# --- services 임포트 ---
from services import data_service 

router = APIRouter()

@router.get("/api/races/{year}", response_model=List[RaceInfo])
async def get_races(year: int):
    """ data_service를 호출하여 실제 연도별 레이스 목록 반환 """
    
    races = data_service.get_races_for_year(year)
    
    if not races:
        raise HTTPException(status_code=404, detail="Data not found for the selected year")
    return races

@router.get("/api/drivers/{year}/{race_id}", response_model=List[DriverInfo])
async def get_drivers(year: int, race_id: str):
    """ data_service를 호출하여 실제 드라이버 목록 반환 """
    
    drivers = data_service.get_drivers_for_race(year, race_id)
    
    if not drivers:
        raise HTTPException(status_code=404, detail="Data not found for the selected race")
    return drivers