# backend/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import data, simulation  # 1. 라우터 파일 임포트

# FastAPI 앱 인스턴스 생성
app = FastAPI()

# --- CORS 설정 ---
# (v2).txt 1.7 항목 
# Flutter 앱의 로컬 개발 환경(localhost) 등에서의 접근을 허용합니다.
# 실제 배포 시에는 origins 목록을 수정해야 할 수 있습니다.
origins = [
    "http://localhost",
    "http://localhost:8080", # Flutter 웹 기본 포트 (변경 가능)
    # Flutter 모바일 앱의 경우 특정 origin이 없을 수 있으나, 
    # 웹 테스트를 위해 localhost를 추가합니다.
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"], # 모든 HTTP 메소드 허용
    allow_headers=["*"], # 모든 HTTP 헤더 허용
)
# -----------------

# 2. 생성한 라우터들을 앱에 포함시킵니다.
app.include_router(data.router)
app.include_router(simulation.router)

@app.get("/")
def read_root():
    return {"message": "Hello World"}

# (v2).txt 1.2 항목에 따라 uvicorn으로 실행합니다.
# 터미널에서 다음 명령어로 서버를 실행할 수 있습니다:
# uvicorn main:app --reload