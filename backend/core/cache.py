import fastf1 as ff1
import os
import logging
from pathlib import Path

# 캐시 디렉토리 설정 (예: 프로젝트 루트의 .cache/fastf1)
# 무료 서버 환경에서는 이 경로를 /tmp 또는 사용 가능한 영구 스토리지로 변경해야 할 수 있음
CACHE_DIR = Path(os.getcwd()).parent / ".cache" / "fastf1"
CACHE_LIMIT_GB = 4  # 4GB 용량 제한

def setup_fastf1_cache():
    """
    FastF1 캐시를 활성화하고 용량 제한을 설정
    """
    try:
        if not CACHE_DIR.exists():
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            
        cache_limit_bytes = int(CACHE_LIMIT_GB * 1e9)
        
        ff1.Cache.enable_cache(CACHE_DIR, limit=cache_limit_bytes, ignore_version=True)
        logging.info(f"FastF1 캐시 활성화. 경로: {CACHE_DIR}, 용량 제한: {CACHE_LIMIT_GB}GB")
    
    except Exception as e:
        logging.error(f"FastF1 캐시 설정 실패: {e}")

def clear_fastf1_cache():
    """
    FastF1 캐시를 정리 (LRU 정책에 따라).
    """
    try:
        logging.info("FastF1 캐시 정리 스케줄러 시작...")
        ff1.Cache.clear_cache(CACHE_DIR)
        logging.info("FastF1 캐시 정리 완료.")
    except Exception as e:
        logging.error(f"FastF1 캐시 정리 실패: {e}")