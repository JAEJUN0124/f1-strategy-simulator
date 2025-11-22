import logging
import pytz
from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from core.cache import setup_fast_f1_cache, clear_fast_f1_cache
from routers import data, simulation

# 로깅 설정
logging.basicConfig(level=logging.INFO)

# --- FastAPI 앱 및 스케줄러 초기화 ---
app = FastAPI()
scheduler = AsyncIOScheduler()

# --- CORS 설정 ---
# 로컬 개발 환경(Flutter Web/App)에서의 접근을 허용합니다.
origins = [
    "http://localhost",
    "http://localhost:8080", # Flutter Web 기본 포트
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    # --- 수정된 부분 ---
    # 모든 출처(origin)를 허용하도록 "*" 사용
    allow_origins=["*"], 
    # allow_credentials=True, # 이 옵션을 제거
    allow_methods=["*"], # 모든 메소드 (GET, POST 등) 허용
    allow_headers=["*"], # 모든 헤더 허용
    # ------------------
)

# --- 라우터 포함 ---
app.include_router(data.router)
app.include_router(simulation.router)
# ------------------

# --- 앱 시작/종료 이벤트 ---

@app.on_event("startup")
async def startup_event():
    """
    앱 시작 시 FastF1 캐시 설정 및 캐시 정리 스케줄러를 시작합니다.
    """
    # 1. FastF1 캐시 설정 (용량 제한) 
    setup_fast_f1_cache()
    
    # 2. 캐시 정리 스케줄러 (시간 제한)
    scheduler.add_job(
        clear_fast_f1_cache,
        trigger=CronTrigger(hour=4, minute=0, timezone=pytz.timezone('Asia/Seoul')),
        id="daily_cache_clear",
        replace_existing=True,
    )
    scheduler.start()
    logging.info("APScheduler 시작됨. (매일 4시(KST) 캐시 정리)")

@app.on_event("shutdown")
async def shutdown_event():
    """
    앱 종료 시 스케줄러를 종료합니다.
    """
    scheduler.shutdown()
    logging.info("APScheduler 종료됨.")

# --- 기본 엔드포인트 ---

@app.get("/health", status_code=200)
async def health_check(response: Response):
    """
    서버 상태 확인용 헬스체크 엔드포인트
    로드 밸런서나 오케스트레이션 도구에서 호출
    """
    # 여기에 DB 연결 확인이나 필수 서비스 상태 확인 로직을 추가할 수 있습니다.
    # 예: if not db.is_connected(): response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    
    return {"status": "ok"}

@app.get("/")
async def read_root():
    """
    서버 상태 확인용 "Hello World"
    """
    return {"message": "F1 Strategy Simulator (v4) Backend - Hello World"}