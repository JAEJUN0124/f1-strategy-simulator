import logging
import uuid
import numpy as np
import pandas as pd
from typing import List, Dict
from models.simulation import (
    SimulationRequest, SimulationResponse, StrategyResult, RaceEvent, Scenario
)
from services import data_service
from fastapi import HTTPException

# --- 1. 실제 전략 분석 ---

def get_actual_strategy(driver_laps: pd.DataFrame) -> StrategyResult:
    """ 드라이버의 실제 레이스 전략을 분석합니다. """
    try:
        # 피트 스톱 랩 찾기 (PitOutTime이 기록된 랩)
        pit_laps = driver_laps[driver_laps['PitOutTime'].notna()]['LapNumber'].tolist()
        
        # 실제 랩 타임 (초 단위로 변환)
        lap_times_data = driver_laps['LapTime'].dropna().apply(lambda x: x.total_seconds()).tolist()
        
        # 실제 총 레이스 시간
        total_time = sum(lap_times_data)
        
        # --- 수정: Pydantic 모델(camelCase)에 맞게 반환 ---
        return StrategyResult(
            name="Actual",
            totalTime=total_time,
            pitLaps=pit_laps,
            lapTimes=lap_times_data  # lap_times -> lapTimes
        )
    except Exception as e:
        logging.error(f"실제 전략 분석 실패: {e}")
        # --- 수정: Pydantic 모델(camelCase)에 맞게 반환 ---
        return StrategyResult(
            name="Actual", 
            totalTime=0.0, 
            pitLaps=[], 
            lapTimes=[] # lap_times -> lapTimes
        )

# --- 2. 타이어 성능 모델링 ---

def model_tire_degradation(driver_laps: pd.DataFrame) -> Dict[str, float]:
    """
    타이어 컴파운드별 성능 저하(degradation)를 모델링
    - (입력) driver_laps: UI에서 선택한 '특정 드라이버 1명'의 데이터
    - (출력) degradation_models: {"COMPOUND": 랩당_저하값_초} (예: {"SOFT": 0.15})
    """
    
    degradation_models = {}
    
    # [1] 모델링을 위한 데이터 정제: SC/VSC, Pit 랩 등 이상치(Noise) 제거
    laps_for_model = driver_laps[
        (driver_laps['TrackStatus'] == '1') & # 트랙 상태 Green (SC/VSC 제외)
        (driver_laps['IsAccurate'] == True) & # 정확한 랩 타임
        (driver_laps['PitInTime'].isna()) &   # 피트 스톱 랩 제외
        (driver_laps['PitOutTime'].isna())
    ].copy()
    
    # [2] 'LapTime' (TimeDelta)을 'LapTimeSeconds' (float)로 변환
    laps_for_model['LapTimeSeconds'] = laps_for_model['LapTime'].dt.total_seconds()
    
    # [3] 타이어 컴파운드별(Soft, Medium, Hard)로 반복
    compounds = laps_for_model['Compound'].unique()
    
    for compound in compounds:
        compound_laps = laps_for_model[laps_for_model['Compound'] == compound]
        
        # [4] 통계적 의미를 위해 최소 5랩 이상의 데이터가 있는지 확인
        if len(compound_laps) < 5: # 데이터가 너무 적으면 모델링 스킵
            continue
            
        try:
            # [5] 핵심: 선형 회귀(1차) 실행. X=타이어수명, Y=랩타임(초)
            #       - np.polyfit(X, Y, 1) -> [기울기(β₁), Y절편(β₀)] 반환
            model = np.polyfit(compound_laps['TyreLife'], compound_laps['LapTimeSeconds'], 1)
            
            # [6] 모델 결과(기울기) 추출: model[0]은 기울기(β₁), 즉 '랩당 성능 저하 값'임.
            degradation_per_lap = model[0]
            
            # [7] 보정: 모델이 비정상적인 값(예: 0 미만, 0.5초 초과)을 반환하면, 0.01로 고정
            if degradation_per_lap < 0 or degradation_per_lap > 0.5:
                 degradation_per_lap = 0.01 
                 
            degradation_models[compound] = degradation_per_lap
            
        except Exception as e:
            # (예외 처리) 모델링 실패 시, 기본 저하 값(0.1) 할당
            logging.warning(f"{compound} 모델링 실패: {e}. 기본값(0.1) 사용.")
            degradation_models[compound] = 0.1 

    # [8] 폴백(Fallback): 
    #     - 데이터가 부족해 모델링이 안 된 컴파운드(예: 5랩 미만 주행)에 대해 
    #     - 시뮬레이션이 멈추지 않도록 미리 정의된 기본값(Hardcoded)을 할당합니다.
    if "SOFT" not in degradation_models: degradation_models["SOFT"] = 0.15
    if "MEDIUM" not in degradation_models: degradation_models["MEDIUM"] = 0.1
    if "HARD" not in degradation_models: degradation_models["HARD"] = 0.08

    return degradation_models

# --- 3. 레이스 이벤트 추출 ---

def get_race_events(session) -> List[RaceEvent]:
    """ SC, VSC, Red Flag 이벤트를 추출합니다. """
    events = []
    try:
        # Safety Car 기간 추출
        sc_periods = session.laps.get_safety_car_periods()
        if sc_periods is not None:
            for _, row in sc_periods.iterrows():
                events.append(RaceEvent(
                    type="SC",
                    startLap=int(row['StartLaps']),
                    endLap=int(row['EndLaps'])
                ))
                
    except Exception as e:
        logging.warning(f"레이스 이벤트 추출 실패: {e}")
        
    return events

# --- 4. 시뮬레이션 실행 (메인 서비스) ---

def run_simulation(request: SimulationRequest) -> SimulationResponse:
    """ 메인 시뮬레이션 서비스 함수 """
    
    session = data_service.load_race_data(request.year, request.raceId)
    if not session:
        raise HTTPException(status_code=404, detail="Race data not found.")
        
    driver_laps = session.laps.pick_driver(request.driverId).reset_index()
    if driver_laps.empty:
         raise HTTPException(status_code=404, detail="Driver data not found.")

    total_laps = int(driver_laps['LapNumber'].max())
    
    actual_result = get_actual_strategy(driver_laps)
    degradation_model = model_tire_degradation(driver_laps)
    race_events = get_race_events(session)
    
    simulated_scenarios: List[StrategyResult] = []
    
    base_lap_time = driver_laps['LapTime'].dropna().min().total_seconds()

    for scenario in request.scenarios:
        sim_result = _simulate_strategy(
            scenario=scenario,
            total_laps=total_laps,
            base_lap_time=base_lap_time,
            degradation_model=degradation_model,
            pit_loss_seconds=request.pitLossSeconds
        )
        simulated_scenarios.append(sim_result)
        
    # 시뮬레이션 결과가 없는 경우 (예외 처리)
    if not simulated_scenarios:
        raise HTTPException(status_code=400, detail="No valid scenarios to simulate.")

    optimal_result = min(simulated_scenarios, key=lambda x: x.totalTime)
    optimal_result.name = "Optimal" # 이름 변경
    
    response = SimulationResponse(
        reportId=str(uuid.uuid4()),
        results={
            "actual": actual_result,
            "optimal": optimal_result,
            "scenarios": simulated_scenarios
        },
        raceEvents=race_events
    )
    
    return response


# --- 5. 개별 시나리오 시뮬레이터 (Helper) ---

def _simulate_strategy(
    scenario: Scenario, 
    total_laps: int, 
    base_lap_time: float,
    degradation_model: Dict[str, float],
    pit_loss_seconds: float
) -> StrategyResult:
    """ 
    단일 시나리오에 대해 랩 타임을 계산합니다. 
    """
    
    lap_times_data = []
    pit_laps = []
    current_stint_index = 0
    tire_life = 0
    
    # 수동 랩 지정을 위한 임시 endLap 설정 (시나리오에 스틴트가 1개면 마지막 랩)
    if len(scenario.stints) == 1:
        scenario.stints[0].endLap = total_laps

    for lap in range(1, total_laps + 1):
        # 현재 스틴트가 범위를 벗어나지 않도록 방어
        if current_stint_index >= len(scenario.stints):
            # 마지막 스틴트를 계속 사용
            current_stint_index = len(scenario.stints) - 1
            
        stint = scenario.stints[current_stint_index]
        compound = stint.compound
        tire_life += 1
        
        # 랩 타임 계산
        degradation = degradation_model.get(compound, 0.1) * tire_life
        lap_time = base_lap_time + degradation
        
        # 임시 피트 스톱 로직 (endLap이 현재 랩과 같고 마지막 랩이 아닐 때)
        # (프론트에서 endLap이 null로 오므로, 여기서는 임시로 2스탑 (total/3)으로 가정)
        # TODO: 프론트에서 startLap/endLap을 입력받아 이 로직을 대체해야 함
        
        # 임시 2스탑 로직 (예: 60랩 -> 20, 40)
        stints_count = len(scenario.stints)
        if stints_count > 1 and (lap % (total_laps // stints_count) == 0) and lap < total_laps:
            is_pit_lap = True
        else:
            is_pit_lap = False

        if is_pit_lap:
            lap_time += pit_loss_seconds # 피트 손실 추가
            pit_laps.append(lap)
            tire_life = 0 # 타이어 수명 초기화
            
            if current_stint_index < len(scenario.stints) - 1:
                current_stint_index += 1
        
        lap_times_data.append(lap_time)

    # --- 수정: Pydantic 모델(camelCase)에 맞게 반환 ---
    return StrategyResult(
        name=scenario.name,
        totalTime=sum(lap_times_data),
        pitLaps=pit_laps,
        lapTimes=lap_times_data # lap_times -> lapTimes
    )