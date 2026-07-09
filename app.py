from flask import Flask, request, jsonify
from model import ModelManager
import os
from datetime import datetime
from functools import wraps

app = Flask(__name__)
model_manager = ModelManager()
RELOAD_TOKEN = os.environ.get('RELOAD_TOKEN')


def require_reload_token(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not RELOAD_TOKEN:
            return jsonify({'error': 'Reload endpoint is disabled (RELOAD_TOKEN not configured)'}), 503
        auth_header = request.headers.get('Authorization', '')
        if auth_header == f'Bearer {RELOAD_TOKEN}':
            return f(*args, **kwargs)
        if request.headers.get('X-Reload-Token') == RELOAD_TOKEN:
            return f(*args, **kwargs)
        return jsonify({'error': 'Unauthorized'}), 401
    return decorated

try:
    model_manager.load_model()
    print("Model loaded successfully!")
except FileNotFoundError:
    print("Warning: Model not found. Please train the model first.")

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'model_loaded': model_manager.model is not None,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()

    if not data or 'text' not in data:
        return jsonify({'error': 'Missing "text" field in request'}), 400

    if model_manager.model is None:
        return jsonify({
            'error': 'Model not loaded. Please train the model first.'
        }), 503

    text = data['text']
    
    try:
        result = model_manager.predict(text)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    if model_manager.model is None:
        return jsonify({
            'error': 'Model not loaded. Please train the model first.'
        }), 503
    
    data = request.get_json()
    
    if not data or 'texts' not in data:
        return jsonify({'error': 'Missing "texts" field in request'}), 400
    
    texts = data['texts']
    
    if not isinstance(texts, list):
        return jsonify({'error': '"texts" must be a list'}), 400
    
    try:
        results = [model_manager.predict(text) for text in texts]
        return jsonify({'results': results})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/reload', methods=['POST'])
@require_reload_token
def reload_model():
    try:
        model_path = request.get_json().get('model_path') if request.is_json else None
        model_manager.load_model(model_path)
        return jsonify({
            'status': 'success',
            'message': 'Model reloaded successfully'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)


