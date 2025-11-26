from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Union
from datetime import datetime

# --- 기본 데이터 구조 ---

class RaceInfo(BaseModel):
    """  API: GET /api/races/{year} 응답 """
    # Field(..., description="...") 형식을 사용하세요
    raceId: str = Field(..., description="레이스 고유 ID (예: '1')")
    name: str = Field(..., description="그랑프리 대회 이름 (예: 'Bahrain Grand Prix')")
    round: int = Field(..., description="시즌 몇 번째 경기인지 (라운드)")

    # 상세 정보 필드
    date: datetime = Field(..., description="레이스 결승 날짜 및 시간")
    location: str = Field(..., description="개최지 (예: 'Sakhir')")
    officialName: str = Field(..., description="공식 대회 전체 명칭")

class DriverInfo(BaseModel):
    """ API: GET /api/drivers/{year}/{race_id} 응답 """
    driverId: str = Field(..., description="드라이버 식별자 (예: 'VER', 'HAM')")
    name: str = Field(..., description="드라이버 이름 (예: 'Max Verstappen')")

# --- 시뮬레이션 요청 모델 (Request) ---

class StintRequest(BaseModel):
    """ 단일 스틴트 요청 """
    compound: str = Field(..., description="타이어 종류 (SOFT, MEDIUM, HARD)")
    startLap: Optional[int] = Field(None, description="스틴트 시작 랩 (자동 최적화 시 생략 가능)")
    endLap: Optional[int] = Field(None, description="스틴트 종료 랩 (자동 최적화 시 생략 가능)")

class Scenario(BaseModel):
    """ 단일 전략 시나리오 요청 """
    name: str = Field(..., description="전략 시나리오 이름 (예: 'S-M-H')")
    stints: List[StintRequest] = Field(..., description="해당 시나리오에 포함된 타이어 스틴트 목록")

class SimulationRequest(BaseModel):
    """ API: POST /api/simulate 요청 본문 """
    year: int = Field(..., description="시즌 연도 (예: 2024)")
    raceId: str = Field(..., description="대상 레이스 ID")
    driverId: str = Field(..., description="시뮬레이션할 드라이버 ID")
    pitLossSeconds: float = Field(..., description="피트 스톱 시 예상 손실 시간 (초 단위)")
    scenarios: List[Scenario] = Field(..., description="비교 분석할 전략 시나리오 리스트")

# --- 시뮬레이션 응답 모델 (Response) ---

class TireStint(BaseModel):
    """ 결과에 포함될 타이어 스틴트 상세 정보 """
    compound: str = Field(..., description="사용한 타이어 컴파운드")
    startLap: int = Field(..., description="해당 타이어 사용 시작 랩")
    endLap: int = Field(..., description="해당 타이어 사용 종료 랩")

class StrategyResult(BaseModel):
    """ 단일 전략(실제, 최적, 시나리오)의 결과 데이터 """
    name: str = Field(..., description="전략 구분 이름 (Actual, Optimal 등)")
    totalTime: float = Field(..., description="레이스 완주 총 소요 시간 (초)")
    pitLaps: List[int] = Field(..., description="피트 스톱을 수행한 랩 번호 목록")
    lapTimes: List[float] = Field(..., description="각 랩당 소요 시간 리스트")
    tireStints: List[TireStint] = Field([], description="타이어 교체 이력 상세 정보")

class RaceEvent(BaseModel):
    """ 레이스 이벤트 (SC, VSC, Red Flag) """
    type: str = Field(..., description="이벤트 유형 ('SC', 'VSC', 'RedFlag')")
    startLap: int = Field(..., description="이벤트 발생 시작 랩")
    endLap: int = Field(..., description="이벤트 종료 랩")

class SimulationResponse(BaseModel):
    """ API: POST /api/simulate 응답 본문 """
    reportId: str = Field(..., description="리포트 고유 ID (UUID)")
    results: Dict[str, Union[StrategyResult, List[StrategyResult]]] = Field(..., description="시뮬레이션 결과 모음 (실제, 최적, 사용자 정의 시나리오)")
    raceEvents: List[RaceEvent] = Field(..., description="경기 중 발생한 특이사항(SC 등) 목록")