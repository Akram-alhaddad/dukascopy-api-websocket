# prediction/predictor.py
import os, joblib, numpy as np
from typing import Dict

MODEL_PATH = os.getenv("MODEL_PATH","models/market_model.pkl")
_model = None

def load_model():
    global _model
    if _model is None:
        _model = joblib.load(MODEL_PATH)
    return _model

def predict(features: Dict):
    model = load_model()
    X = np.array([features[k] for k in sorted(features.keys())]).reshape(1,-1)
    proba = model.predict_proba(X) if hasattr(model, "predict_proba") else None
    pred = model.predict(X)
    return {"pred":float(pred[0]), "proba": proba.tolist() if proba is not None else None}
