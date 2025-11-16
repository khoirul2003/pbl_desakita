import cv2
import dlib
import numpy as np
import face_recognition
from scipy.spatial import distance as dist
import logging

logging.basicConfig(level=logging.INFO)

try:

    cascade_path = "haarcascade_frontalface_default.xml"
    face_detector_cv = cv2.CascadeClassifier(cascade_path)
    
    landmark_predictor_path = "shape_predictor_68_face_landmarks.dat"
    landmark_predictor = dlib.shape_predictor(landmark_predictor_path)

    (lStart, lEnd) = (42, 48)
    (rStart, rEnd) = (36, 42)
    logging.info("Model CV (Haar, Dlib) berhasil dimuat.")

except Exception as e:
    logging.error(f"Error loading models: {e}")
    logging.error("Pastikan file 'haarcascade_frontalface_default.xml' dan 'shape_predictor_68_face_landmarks.dat' ada di folder proyek.")
    raise e

EAR_THRESHOLD = 0.2
EAR_CONSEC_FRAMES = 1

def _bytes_to_image(image_bytes: bytes):
    """Mengubah byte gambar mentah menjadi array numpy OpenCV."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Gagal memuat gambar dari byte. Format tidak didukung?")
    return img

def _calculate_ear(shape, eye_indices):
    """Menghitung Eye Aspect Ratio (EAR) dari landmark mata."""
    eye_points = np.array([(shape.part(i).x, shape.part(i).y) for i in range(eye_indices[0], eye_indices[1])])
    
    A = dist.euclidean(eye_points[1], eye_points[5])
    B = dist.euclidean(eye_points[2], eye_points[4])

    C = dist.euclidean(eye_points[0], eye_points[3])
 
    ear = (A + B) / (2.0 * C)
    return ear

def extract_features(image_bytes: bytes):
    """
    Menerima byte gambar, mengembalikan 128 fitur wajah.
    Menggunakan library `face_recognition` (berbasis Dlib DL).
    """
    logging.info("Memulai ekstraksi fitur...")
    
    img = _bytes_to_image(image_bytes)
    rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    face_locations = face_recognition.face_locations(rgb_img, model="hog")
    
    if len(face_locations) == 0:
        logging.warning("Ekstraksi gagal: Tidak ada wajah terdeteksi.")
        return None, "Tidak ada wajah terdeteksi."
        
    if len(face_locations) > 1:
        logging.warning("Ekstraksi gagal: Terdeteksi lebih dari 1 wajah.")
        return None, "Terdeteksi lebih dari 1 wajah."

    face_encodings = face_recognition.face_encodings(rgb_img, known_face_locations=face_locations)
    
    if not face_encodings:
        logging.error("Ekstraksi gagal: Wajah terdeteksi tapi gagal encoding.")
        return None, "Gagal memproses fitur wajah."

    logging.info("Ekstraksi fitur berhasil.")

    return face_encodings[0].tolist(), "Ekstraksi berhasil."


def check_liveness(image_bytes_list: list[bytes]):
    """
    Menerima list byte gambar (frames), mengecek liveness (kedipan).
    Menggunakan OpenCV Haar Cascade dan Dlib Landmarks.
    """
    logging.info(f"Memulai cek liveness untuk {len(image_bytes_list)} frames...")
    
    blink_counter = 0
    total_frames = 0
    ear_values = []

    for image_bytes in image_bytes_list:
        try:
            frame = _bytes_to_image(image_bytes)
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            
            # Deteksi wajah menggunakan Haar Cascade
            faces_cv = face_detector_cv.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(30, 30),
                flags=cv2.CASCADE_SCALE_IMAGE
            )

            if len(faces_cv) == 0:
                logging.warning("Liveness frame skipped: Tidak ada wajah (Haar).")
                continue
   
            (x, y, w, h) = faces_cv[0]
            # Ubah ke format Dlib (rectangle object)
            dlib_rect = dlib.rectangle(int(x), int(y), int(x + w), int(y + h))

            # Dapatkan landmark wajah
            shape = landmark_predictor(gray, dlib_rect)

            # Hitung EAR untuk kedua mata
            left_ear = _calculate_ear(shape, (lStart, lEnd))
            right_ear = _calculate_ear(shape, (rStart, rEnd))
            
            # Rata-rata EAR
            ear = (left_ear + right_ear) / 2.0
            ear_values.append(ear)
            total_frames += 1

            # Cek kedipan
            if ear < EAR_THRESHOLD:
                blink_counter += 1
            else:
                # Jika tidak kedip, reset counter
                if blink_counter >= EAR_CONSEC_FRAMES:
                    logging.info("Liveness check BERHASIL: Kedipan terdeteksi.")
                    return True, "Blink detected."
                blink_counter = 0 # Reset

        except Exception as e:
            logging.warning(f"Liveness frame error: {e}")
            continue

    # Cek sekali lagi di akhir loop
    if blink_counter >= EAR_CONSEC_FRAMES:
        logging.info("Liveness check BERHASIL: Kedipan terdeteksi di akhir.")
        return True, "Blink detected."

    logging.warning(f"Liveness check GAGAL: Tidak ada kedipan. (Total {total_frames} frame valid, EARs: {ear_values})")
    return False, "No blink detected in frames."