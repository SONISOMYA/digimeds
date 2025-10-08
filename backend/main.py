import uvicorn
import os
import json
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Body, Depends
from dotenv import load_dotenv
import google.generativeai as genai
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore, auth

# --- 1. Environment & API Setup ---
load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise ValueError("Error: GOOGLE_API_KEY not found in .env file.")

genai.configure(api_key=api_key)

# --- 2. Firebase Initialization ---
if not firebase_admin._apps:
    if not os.path.exists("serviceAccountKey.json"):
        raise FileNotFoundError(
            "CRITICAL ERROR: 'serviceAccountKey.json' not found. "
            "Please download it from Firebase Console."
        )
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
        print("Firebase Admin Initialized successfully.")
    except Exception as e:
        raise RuntimeError(f"Failed to initialize Firebase: {e}")

db = firestore.client()
app = FastAPI(title="DigiMeds API")

# --- 3. Data Models ---
class Medication(BaseModel):
    drugName: Optional[str] = None
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    duration: Optional[str] = None

class Prescription(BaseModel):
    id: Optional[str] = None
    doctorName: Optional[str] = None
    patientName: Optional[str] = None
    prescriptionDate: Optional[str] = None
    medications: List[Medication] = []

# --- 4. Hyper-Tuned Gemini Prompt ---
GEMINI_PROMPT = """
You are an expert pharmaceutical data extractor specializing in handwritten Indian medical prescriptions. 
Your goal is to extract structured data accurately, even from messy or cursive handwriting.

ANALYZE THE IMAGE FOR:
1. patientName (String or null)
2. doctorName (String or null)
3. prescriptionDate (String or null)
4. medications (List of objects)

CRITICAL RULES FOR MEDICATIONS:
- drugName: Identify the medicine name. Correct spelling based on common Indian brands if possible.
- dosage: Look for strengths like "200mg", "500mg".
- duration: Look for "5 days", "1 week".

- frequency: THIS IS THE MOST IMPORTANT FIELD.
  - LOOK FOR NUMERICAL PATTERNS (e.g., "1-0-1", "1-1-1", "0-0-1", "BD", "TDS").
  - INTERPRET THEM AS FOLLOWS:
    - "1-0-1", "1-O-1"  -> "Twice a day"
    - "1-1-1"           -> "Thrice a day"
    - "1-0-0"           -> "Once a day (Morning)"
    - "0-1-0"           -> "Once a day (Afternoon)"
    - "0-0-1"           -> "Once a day (Night)"
    - "BD", "BID"       -> "Twice a day"
    - "TDS", "TID"      -> "Thrice a day"
    - "OD"              -> "Once a day"
    - "SOS"             -> "As needed"

OUTPUT FORMAT:
Provide ONLY a valid JSON object. No markdown.
"""

# --- 5. Helper: Verify Token ---
async def verify_token(authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="No authorization token provided")
    try:
        token = authorization.split("Bearer ")[1]
        decoded_token = auth.verify_id_token(token)
        return decoded_token['uid']
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

# --- 6. API Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Welcome to the DigiMeds API"}

@app.post("/scan")
async def scan_prescription(image: UploadFile = File(...)):
    try:
        image_bytes = await image.read()
        image_part = {"mime_type": image.content_type, "data": image_bytes}

        # FIXED: Changed from 'gemini-2.5-flash' to 'gemini-1.5-flash'
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        response = model.generate_content([GEMINI_PROMPT, image_part])
        response_text = response.text.strip().replace('```json', '').replace('```', '')
        
        return json.loads(response_text)
    except Exception as e:
        print(f"Error scanning: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/save-prescription")
async def save_prescription(prescription: Prescription, user_id: str = Depends(verify_token)):
    try:
        data = prescription.dict()
        if 'id' in data: del data['id'] 
        data['createdAt'] = firestore.SERVER_TIMESTAMP

        doc_ref = db.collection('users').document(user_id).collection('prescriptions').document()
        doc_ref.set(data)
        
        return {"message": "Prescription saved successfully", "id": doc_ref.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/prescriptions", response_model=List[Prescription])
async def get_user_prescriptions(user_id: str = Depends(verify_token)):
    try:
        # Order by createdAt descending so newest shows first
        docs = db.collection('users').document(user_id).collection('prescriptions').order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        
        results = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            if 'createdAt' in data: del data['createdAt']
            results.append(data)
            
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NEW: Delete Endpoint (Required for History Screen) ---
@app.delete("/delete-prescription/{prescription_id}")
async def delete_prescription(prescription_id: str, user_id: str = Depends(verify_token)):
    try:
        doc_ref = db.collection('users').document(user_id).collection('prescriptions').document(prescription_id)
        doc_ref.delete()
        return {"message": "Prescription deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)