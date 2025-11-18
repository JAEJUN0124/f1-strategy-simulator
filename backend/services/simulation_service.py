import logging
import uuid
import numpy as np
import pandas as pd
from typing import List, Dict
from models.simulation import (
    SimulationRequest, SimulationResponse, StrategyResult, RaceEvent, Scenario, TireStint
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
        
        # 실제 타이어 스틴트 분석 로직
        tire_stints = []
        current_compound = None
        start_lap = 1
        
        # 데이터프레임을 순회하며 스틴트 추출
        laps_with_compound = driver_laps[['LapNumber', 'Compound']].dropna()
        
        for _, row in laps_with_compound.iterrows():
            lap = int(row['LapNumber'])
            compound = row['Compound']
            
            if current_compound is None:
                current_compound = compound
                start_lap = lap
            elif compound != current_compound:
                # 타이어 변경 감지 -> 이전 스틴트 저장
                tire_stints.append(TireStint(
                    compound=str(current_compound),
                    startLap=start_lap,
                    endLap=lap - 1
                ))
                current_compound = compound
                start_lap = lap
        
        # 마지막 스틴트 추가
        if current_compound is not None:
            max_lap = int(driver_laps['LapNumber'].max())
            tire_stints.append(TireStint(
                compound=str(current_compound),
                startLap=start_lap,
                endLap=max_lap
            ))

        return StrategyResult(
            name="Actual",
            totalTime=total_time,
            pitLaps=pit_laps,
            lapTimes=lap_times_data,
            tireStints=tire_stints
        )
    except Exception as e:
        logging.error(f"실제 전략 분석 실패: {e}")
        return StrategyResult(
            name="Actual", 
            totalTime=0.0, 
            pitLaps=[], 
            lapTimes=[], 
            tireStints=[]
        )

# --- 2. 타이어 성능 모델링 ---

def model_tire_degradation(driver_laps: pd.DataFrame) -> Dict[str, float]:
    """ 타이어 컴파운드별 성능 저하(degradation)를 모델링 """
    degradation_models = {}
    
    # 이상치(SC, VSC, In/Out 랩) 제거
    laps_for_model = driver_laps[
        (driver_laps['TrackStatus'] == '1') & 
        (driver_laps['IsAccurate'] == True) & 
        (driver_laps['PitInTime'].isna()) &
        (driver_laps['PitOutTime'].isna())
    ].copy()
    
    laps_for_model['LapTimeSeconds'] = laps_for_model['LapTime'].dt.total_seconds()
    
    compounds = laps_for_model['Compound'].unique()
    
    for compound in compounds:
        compound_laps = laps_for_model[laps_for_model['Compound'] == compound]
        
        if len(compound_laps) < 5: 
            continue
            
        try:
            model = np.polyfit(compound_laps['TyreLife'], compound_laps['LapTimeSeconds'], 1)
            degradation_per_lap = model[0]
            
            if degradation_per_lap < 0 or degradation_per_lap > 0.5:
                 degradation_per_lap = 0.01 
                 
            degradation_models[compound] = degradation_per_lap
            
        except Exception as e:
            logging.warning(f"{compound} 모델링 실패: {e}. 기본값(0.1) 사용.")
            degradation_models[compound] = 0.1 

    if "SOFT" not in degradation_models: degradation_models["SOFT"] = 0.15
    if "MEDIUM" not in degradation_models: degradation_models["MEDIUM"] = 0.1
    if "HARD" not in degradation_models: degradation_models["HARD"] = 0.08

    return degradation_models

# --- 3. 레이스 이벤트 추출 ---

def get_race_events(session) -> List[RaceEvent]:
    """ SC, VSC, Red Flag 이벤트를 추출합니다. """
    events = []
    try:
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
        
    if not simulated_scenarios:
        raise HTTPException(status_code=400, detail="No valid scenarios to simulate.")

    optimal_result = min(simulated_scenarios, key=lambda x: x.totalTime)
    optimal_result.name = "Optimal" 
    
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
    tire_stints = [] # (추가)
    
    current_stint_index = 0
    tire_life = 0
    current_stint_start_lap = 1 # (추가)
    
    # 수동 랩 지정을 위한 임시 endLap 설정 (시나리오에 스틴트가 1개면 마지막 랩)
    if len(scenario.stints) == 1:
        scenario.stints[0].endLap = total_laps

    for lap in range(1, total_laps + 1):
        if current_stint_index >= len(scenario.stints):
            current_stint_index = len(scenario.stints) - 1
            
        stint = scenario.stints[current_stint_index]
        compound = stint.compound
        tire_life += 1
        
        # 랩 타임 계산
        degradation = degradation_model.get(compound, 0.1) * tire_life
        lap_time = base_lap_time + degradation
        
        # 임시 피트 스톱 로직
        stints_count = len(scenario.stints)
        if stints_count > 1 and (lap % (total_laps // stints_count) == 0) and lap < total_laps:
            is_pit_lap = True
        else:
            is_pit_lap = False

        if is_pit_lap:
            lap_time += pit_loss_seconds 
            pit_laps.append(lap)
            
            # 스틴트 정보 저장
            tire_stints.append(TireStint(
                compound=compound,
                startLap=current_stint_start_lap,
                endLap=lap
            ))
            current_stint_start_lap = lap + 1 # 다음 스틴트 시작 랩
            
            tire_life = 0 
            if current_stint_index < len(scenario.stints) - 1:
                current_stint_index += 1
        
        lap_times_data.append(lap_time)

    # 마지막 스틴트 저장
    last_compound = scenario.stints[current_stint_index].compound
    tire_stints.append(TireStint(
        compound=last_compound,
        startLap=current_stint_start_lap,
        endLap=total_laps
    ))

    return StrategyResult(
        name=scenario.name,
        totalTime=sum(lap_times_data),
        pitLaps=pit_laps,
        lapTimes=lap_times_data,
        tireStints=tire_stints
    )