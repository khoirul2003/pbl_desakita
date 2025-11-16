import cv_utils
from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from typing import List
import logging

app = FastAPI(
    title="API Manajemen Desa - PCVK & ML",
    description="API untuk menangani Ekstraksi Fitur Wajah dan Deteksi Liveness.",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"message": "Berhasil."}


@app.post("/extract-features")
async def extract_features_endpoint(file: UploadFile = File(..., description="Satu file gambar (JPG/PNG) wajah.")):

    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=415, detail="Format file tidak didukung. Harap gunakan JPG or PNG.")

    try:
        image_bytes = await file.read()
        
        # Panggil fungsi dari cv_utils
        features, message = cv_utils.extract_features(image_bytes)
        
        if features is None:
            # Jika tidak ada wajah atau terlalu banyak wajah
            raise HTTPException(status_code=400, detail=message)

        return {"features": features, "message": message}

    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Gambar tidak valid: {e}")
    except Exception as e:
        logging.error(f"Error di /extract-features: {e}")
        raise HTTPException(status_code=500, detail=f"Terjadi kesalahan internal: {e}")


@app.post("/check-liveness")
async def check_liveness_endpoint(files: List[UploadFile] = File(..., description="Beberapa frame gambar (minimal 5) dari video singkat.")):

    MIN_FRAMES = 5
    if len(files) < MIN_FRAMES:
        raise HTTPException(status_code=400, detail=f"Deteksi liveness membutuhkan minimal {MIN_FRAMES} frames.")

    image_bytes_list = []
    
    try:
        for file in files:
            if file.content_type not in ["image/jpeg", "image/png"]:
                raise HTTPException(status_code=415, detail=f"Format file tidak didukung: {file.filename}")
            
            image_bytes_list.append(await file.read())
        
        is_live, detail = cv_utils.check_liveness(image_bytes_list)
        
        return {"liveness": is_live, "detail": detail}

    except Exception as e:
        logging.error(f"Error di /check-liveness: {e}")
        raise HTTPException(status_code=500, detail=f"Terjadi kesalahan internal: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)