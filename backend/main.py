import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from core.cache import setup_fastf1_cache, clear_fastf1_cache

# 로깅 설정
logging.basicConfig(level=logging.INFO)

# --- FastAPI 앱 및 스케줄러 초기화 ---
app = FastAPI()
scheduler = AsyncIOScheduler()

# --- CORS 설정 ---
# (v4) 1.3 항목 
# 로컬 개발 환경(Flutter Web/App)에서의 접근을 허용합니다.
origins = [
    "http://localhost",
    "http://localhost:8080", # Flutter Web 기본 포트 (변경 가능)
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 앱 시작/종료 이벤트 ---

@app.on_event("startup")
async def startup_event():
    """
    앱 시작 시 FastF1 캐시 설정 및 캐시 정리 스케줄러를 시작합니다.
    """
    # 1. FastF1 캐시 설정 (용량 제한) 
    setup_fastf1_cache()
    
    # 2. 캐시 정리 스케줄러 (시간 제한)
    # 24시간(86400초)마다 clear_fastf1_cache 함수 실행
    scheduler.add_job(
        clear_fastf1_cache,
        trigger=IntervalTrigger(seconds=86400), # 24시간
        id="daily_cache_clear",
        replace_existing=True,
    )
    scheduler.start()
    logging.info("APScheduler 시작됨. (24시간 캐시 정리)")

@app.on_event("shutdown")
async def shutdown_event():
    """
    앱 종료 시 스케줄러를 종료합니다.
    """
    scheduler.shutdown()
    logging.info("APScheduler 종료됨.")

# --- 기본 엔드포인트 ---

@app.get("/")
async def read_root():
    """
    서버 상태 확인용 "Hello World"
    """
    return {"message": "F1 Strategy Simulator (v4) Backend - Hello World"}

# (향후 여기에 routers/simulation.py, routers/data.py 등을 include할 예정)