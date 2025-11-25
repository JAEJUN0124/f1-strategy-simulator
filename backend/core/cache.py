import fastf1 as ff1
import os
import logging
from pathlib import Path

# 캐시 디렉토리 설정
CACHE_DIR = Path(os.getcwd()).parent / ".cache" / "fastf1"
CACHE_LIMIT_GB = 70  # 용량 제한을 70GB로 설정

def setup_fast_f1_cache():
    """
    FastF1 캐시를 활성화합니다.
    """
    try:
        if not CACHE_DIR.exists():
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            
        ff1.Cache.enable_cache(CACHE_DIR)
        logging.info(f"FastF1 캐시 활성화. 경로: {CACHE_DIR}")
    
    except Exception as e:
        logging.error(f"FastF1 캐시 설정 실패: {e}")

def get_dir_size(path: Path) -> int:
    """디렉토리의 총 크기(바이트)를 계산합니다."""
    total = 0
    try:
        for entry in path.rglob('*'):
            if entry.is_file():
                total += entry.stat().st_size
    except Exception as e:
        logging.error(f"크기 계산 중 오류: {e}")
    return total

def clear_fast_f1_cache():
    """
    [변경] 캐시 용량이 95GB를 초과할 경우에만, 
    오래된 파일부터 순차적으로 삭제하여 공간을 확보합니다.
    """
    try:
        logging.info("캐시 용량 점검 시작...")
        
        limit_bytes = CACHE_LIMIT_GB * 1024 * 1024 * 1024  # GB -> Bytes 변환
        current_size = get_dir_size(CACHE_DIR)
        
        logging.info(f"현재 캐시 크기: {current_size / (1024**3):.2f} GB / 제한: {CACHE_LIMIT_GB} GB")

        # 용량이 제한보다 작으면 아무것도 하지 않음
        if current_size <= limit_bytes:
            logging.info("용량이 충분합니다. 정리를 건너뜁니다.")
            return

        # 파일 목록을 가져와서 '수정 시간(mtime)' 순으로 정렬 (오래된 것이 맨 앞으로)
        files = []
        for entry in CACHE_DIR.rglob('*'):
            if entry.is_file():
                files.append((entry, entry.stat().st_mtime, entry.stat().st_size))
        
        files.sort(key=lambda x: x[1]) # 오래된 순 정렬

        deleted_size = 0
        deleted_count = 0

        # 오래된 파일부터 하나씩 지움
        for file_path, mtime, size in files:
            if current_size <= limit_bytes:
                break  # 용량이 확보되면 중단
            
            try:
                file_path.unlink() # 파일 삭제
                current_size -= size
                deleted_size += size
                deleted_count += 1
            except Exception as e:
                logging.error(f"파일 삭제 실패 {file_path}: {e}")

        logging.info(f"정리 완료. 삭제된 파일: {deleted_count}개, 확보된 공간: {deleted_size / (1024**2):.2f} MB")

    except Exception as e:
        logging.error(f"FastF1 캐시 정리 실패: {e}")