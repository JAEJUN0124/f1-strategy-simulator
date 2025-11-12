import fastf1 as ff1
import os
import logging
from pathlib import Path

# 캐시 디렉토리 설정 (예: 프로젝트 루트의 .cache/fastf1)
CACHE_DIR = Path(os.getcwd()).parent / ".cache" / "fastf1"
CACHE_LIMIT_GB = 4  # 4GB 용량 제한

def setup_fast_f1_cache():
    """
    FastF1 캐시를 활성화하고 용량 제한을 설정
    """
    try:
        if not CACHE_DIR.exists():
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            
        # fastf1 v3+ 에서는 'limit' 및 'ignore_version' 인자가 제거됨
        ff1.Cache.enable_cache(CACHE_DIR) # 인자 없이 호출

        logging.info(f"FastF1 캐시 활성화. 경로: {CACHE_DIR}")
    
    except Exception as e:
        logging.error(f"FastF1 캐시 설정 실패: {e}")

def clear_fast_f1_cache():
    """
    FastF1 캐시를 정리 (LRU 정책에 따라).
    """
    try:
        logging.info("FastF1 캐시 정리 스케줄러 시작...")
        # clear_cache에는 경로 인자가 필요 없음 (enable_cache에서 설정됨)
        ff1.Cache.clear_cache()
        logging.info("FastF1 캐시 정리 완료.")
    except Exception as e:
        logging.error(f"FastF1 캐시 정리 실패: {e}")