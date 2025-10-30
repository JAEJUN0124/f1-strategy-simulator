# backend/routers/data.py

from fastapi import APIRouter
from typing import List
from models.schemas import RaceInfo, DriverInfo # 1. 이전 단계에서 만든 모델 임포트

# APIRouter 인스턴스 생성
router = APIRouter()

# (v2).txt 1.3 - GET /api/races/{year}
@router.get("/api/races/{year}", response_model=List[RaceInfo])
async def get_races(year: int):
    # Phase 2에서 실제 fastf1 로직으로 대체됩니다.
    # 지금은 가짜(mock) 데이터를 반환합니다.
    print(f"Received request for races in year: {year}")
    return [
        RaceInfo(raceId="1", name="Bahrain Grand Prix", round=1),
        RaceInfo(raceId="2", name="Saudi Arabian Grand Prix", round=2),
    ]

# (v2).txt 1.3 - GET /api/drivers/{year}/{race_id}
@router.get("/api/drivers/{year}/{race_id}", response_model=List[DriverInfo])
async def get_drivers(year: int, race_id: str):
    # Phase 2에서 실제 fastf1 로직으로 대체됩니다.
    # 지금은 가짜(mock) 데이터를 반환합니다.
    print(f"Received request for drivers in year: {year}, race: {race_id}")
    return [
        DriverInfo(driverId="VER", name="Max Verstappen"),
        DriverInfo(driverId="HAM", name="Lewis Hamilton"),
    ]