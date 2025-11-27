from flask import Flask, request, jsonify
from model import ModelManager
import os
from datetime import datetime

app = Flask(__name__)
model_manager = ModelManager()

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
    if model_manager.model is None:
        return jsonify({
            'error': 'Model not loaded. Please train the model first.'
        }), 503
    
    data = request.get_json()
    
    if not data or 'text' not in data:
        return jsonify({'error': 'Missing "text" field in request'}), 400
    
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

