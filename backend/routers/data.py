from fastapi import APIRouter, HTTPException
from typing import List
from models.simulation import RaceInfo, DriverInfo

router = APIRouter()

@router.get("/api/races/{year}", response_model=List[RaceInfo])
async def get_races(year: int):
    """ (v4) 1.3. 연도별 레이스 목록 반환 (임시 데이터) """
    if year == 2024:
        # 임시 목(Mock) 데이터
        return [
            RaceInfo(raceId="1", name="Bahrain Grand Prix", round=1),
            RaceInfo(raceId="2", name="Saudi Arabian Grand Prix", round=2),
            RaceInfo(raceId="3", name="Australian Grand Prix", round=3),
        ]
    raise HTTPException(status_code=404, detail="Data not found for the selected year")

@router.get("/api/drivers/{year}/{race_id}", response_model=List[DriverInfo])
async def get_drivers(year: int, race_id: str):
    """ (v4) 1.3. 특정 레이스의 드라이버 목록 반환 (임시 데이터) """
    if year == 2024 and race_id == "1":
        # 임시 목(Mock) 데이터
        return [
            DriverInfo(driverId="VER", name="VER"),
            DriverInfo(driverId="PER", name="PER"),
            DriverInfo(driverId="LEC", name="LEC"),
            DriverInfo(driverId="SAI", name="SAI"),
        ]
    raise HTTPException(status_code=404, detail="Data not found for the selected race")