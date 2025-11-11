import fastf1 as ff1
import logging
from typing import List
from models.simulation import RaceInfo, DriverInfo
from functools import lru_cache

@lru_cache(maxsize=10) 
def load_race_data(year: int, race_id: str):
    """
    (수정됨) FastF1 세션 데이터를 로드합니다 (캐시 활용).
    """
    try:
        # --- 수정된 부분 1 ---
        # race_id (str)를 int로 변환하여 fastf1이 정확한 라운드를 찾도록 함
        session = ff1.get_session(year, int(race_id), 'R')
        # --------------------
        
        # --- 수정된 부분 2 ---
        # session.load_laps(with_telemetry=True) -> session.load()
        session.load(laps=True, telemetry=True)
        # --------------------
        
        return session
    
    # --- 수정된 부분 3 ---
    # except ff1.api.SessionNotAvailableError -> ff1.errors.SessionNotAvailableError
    except ff1.errors.SessionNotAvailableError: 
    # --------------------
        logging.warning(f"{year} {race_id} 세션을 찾을 수 없습니다.")
        return None
    except Exception as e:
        # 오류 발생 시 더 자세한 로그를 남깁니다.
        logging.error(f"세션 로드 중 오류 발생: {e}", exc_info=True)
        return None

# 연도별 레이스 목록 (중복 제거됨)
@lru_cache(maxsize=5)
def get_races_for_year(year: int) -> List[RaceInfo]:
    """
    (수정됨) fastf1을 사용하여 해당 연도의 레이스 스케줄을 가져옵니다.
    """
    try:
        logging.info(f"[data_service] {year}년 스케줄 로드 시도...")
        schedule = ff1.get_event_schedule(year)
        
        if schedule.empty:
            logging.warning(f"[data_service] {year}년 스케줄이 비어있습니다.")
            return []

        races = []
        for _, event in schedule.iterrows():
            # 'Session5' 접근 대신, 이벤트 이름을 확인합니다.
            event_name_lower = str(event['EventName']).lower() 
            
            # 'test'나 'season' 같은 비-레이스 이벤트를 건너뜁니다.
            if 'test' in event_name_lower or 'pre-season' in event_name_lower or 'season launch' in event_name_lower:
                continue
            
            # RoundNumber가 숫자가 아닌 경우(예: 'TBC')를 대비합니다.
            round_num_str = str(event['RoundNumber'])
            if not round_num_str.isdigit():
                continue
            # --------------------------
                
            races.append(
                RaceInfo(
                    raceId=round_num_str, 
                    name=event['EventName'],
                    round=int(round_num_str)
                )
            )
        
        logging.info(f"[data_service] {year}년 {len(races)}개 레이스를 찾았습니다.")
        
        races.sort(key=lambda r: r.round)
        return races
        
    except Exception as e:
        # 오류 발생 시 더 자세한 로그를 남깁니다.
        logging.error(f"{year}년 레이스 스케줄 로드 실패: {e}", exc_info=True)
        return []

# 레이스별 드라이버 목록
@lru_cache(maxsize=20)
def get_drivers_for_race(year: int, race_id: str) -> List[DriverInfo]:
    """
    특정 레이스 세션에서 드라이버 목록을 가져옵니다.
    """
    session = load_race_data(year, race_id) # race_id는 여기서 str로 전달 (load_race_data가 int로 변환)
    if not session or session.results is None:
        return []

    try:
        drivers = []
        # session.results에서 드라이버 약어(예: VER, HAM)와 이름을 가져옴
        for driver in session.drivers:
            driver_info = session.get_driver(driver)
            drivers.append(
                DriverInfo(
                    driverId=driver_info['Abbreviation'], # "VER"
                    name=driver_info['Abbreviation']    # "VER"
                )
            )
        
        # 이름순으로 정렬
        drivers.sort(key=lambda d: d.name)
        return drivers

    except Exception as e:
        logging.error(f"{year} {race_id} 드라이버 로드 실패: {e}")
        return []